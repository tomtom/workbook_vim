" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-03-05
" @Revision:    472


if !exists('g:workbook#repl#transript_new_cmd')
    let g:workbook#repl#transript_new_cmd = &previewheight .'split'   "{{{2
endif

if !exists('g:workbook#repl#transript_drop_cmd')
    let g:workbook#repl#transript_drop_cmd = 'drop'   "{{{2
endif


let s:prototype = {
            \ 'bufnrs': {},
            \ 'ignore_input': 0,
            \ 'ignore_output': 0,
            \ 'do_insert_results_in_buffer': g:workbook#insert_results_in_buffer,
            \ 'do_transcribe': g:workbook#transcript,
            \ 'next_cmd': [],
            \ 'next_process_output': '',
            \ 'placeholders': {},
            \ 'placeholder_queue': [],
            \ 'repl_type': 'vim_raw',
            \ 'send_wait': '',
            \ 'output_buffer': [],
            \ 'lines_buffer': []}


function! workbook#repl#New(args) abort "{{{3
    let o = deepcopy(s:prototype)
    let o.args = a:args
    let o.filetype = get(o.args, 'filetype', &filetype)
    try
        let o = workbook#ft#{o.filetype}#New(o)
    catch /^Vim\%((\a\+)\)\=:E117/
        echoerr 'Workbook: Unsupported filetype:' o.filetype
    endtry
    let o = workbook#mode#{o.repl_type}#New(o)
    return o
endf


function! s:prototype.GetReplCmd() abort dict "{{{3
    let [cmd0, args0] = self.GetFiletypeCmdAndArgs()
    let cmd = get(self.args, 'cmd', cmd0)
    let args = get(self.args, 'args', args0)
    let oargs = get(self.args, '__rest__', [])
    if !empty(oargs)
        let args .= ' '. join(oargs)
    endif
    if !empty(args)
        let cmd .= ' '. args
    endif
    let cmd = substitute(cmd, '\\', '/', 'g')
    return cmd
endf


" async
function! s:prototype.Input(code, nl) abort dict "{{{3
    if self.IsReady()
        Tlibtrace 'workbook', 'Input', len(a:code), a:nl
        call self.SendToRepl(a:code, a:nl)
    endif
endf


function! s:prototype.SetTranscribe(transcribe) abort dict "{{{3
    let self.do_transcribe = a:transcribe
endf


function! s:prototype.DoTranscribe() abort dict "{{{3
    return self.do_transcribe
endf


function! s:prototype.DoInsertResultsInBuffer() abort dict "{{{3
    Tlibtrace 'workbook', 'DoInsertResultsInBuffer', self.do_insert_results_in_buffer
    if exists('b:workbook_insert_results_in_buffer_once') && self.do_insert_results_in_buffer != 0
        let do_insert_results_in_buffer = b:workbook_insert_results_in_buffer_once
        unlet! b:workbook_insert_results_in_buffer
    elseif exists('b:workbook_log_buffer') || self.do_insert_results_in_buffer < 0
        let do_insert_results_in_buffer = 0
    elseif exists('b:workbook_insert_results_in_buffer')
        let do_insert_results_in_buffer = b:workbook_insert_results_in_buffer
    else
        let do_insert_results_in_buffer = self.do_insert_results_in_buffer
    endif
    Tlibtrace 'workbook', 'DoInsertResultsInBuffer', do_insert_results_in_buffer
    if do_insert_results_in_buffer < 0
        let bufname = self.GetTranscriptId()
        let win = bufwinnr(bufname)
        return win == -1
    else
        return do_insert_results_in_buffer
    endif
endf


" async
function! s:prototype.Send(code, ...) abort dict "{{{3
    if self.IsReady()
        Tlibtrace 'workbook', 'Send', len(a:code)
        let placeholder = a:0 >= 1 ? a:1 : ''
        let wrapcode = a:0 >= 2 ? a:2 : self.DoInsertResultsInBuffer()
        let code = wrapcode && !empty(placeholder) && has_key(self, 'WrapCode') ? self.WrapCode(placeholder, a:code) : a:code
        Tlibtrace 'workbook', 'Send', code
        call self.SendToRepl(code, 1, placeholder)
    endif
endf


" sync
function! s:prototype.Eval(code) abort dict "{{{3
    if self.IsReady()
        Tlibtrace 'workbook', 'Eval', a:code
        try
            let self.next_process_output = function(self.ProcessEval)
            let p = self.GetPlaceholder('eval')
            call self.SetPlaceholder(0, p, '')
            call self.Send(a:code, p, 1)
            let i = 0
            let d = 200
            while !has_key(self, 'eval_result') && i < 2000
                exec 'sleep' d .'m'
                let i += d
                Tlibtrace 'workbook', 'Eval', i
            endwh
            let result = get(self, 'eval_result', '')
        finally
            if has_key(self, 'eval_result')
                unlet self.eval_result
            endif
        endtry
    else
        let result = ''
    endif
    return result
endf


function! s:prototype.ProcessEval(lines) abort dict "{{{3
    Tlibtrace 'workbook', 'ProcessEval', a:lines
    let self.eval_result = join(a:lines, "\n")
endf


function! s:prototype.GetMark(...) abort dict "{{{3
    let p = a:0 >= 1 ? a:1 : self.GetCurrentPlaceholder()
    return printf('---- %s ----', p)
endf


function! s:prototype.GetPlaceholderFromBeginMark(msg) abort dict "{{{3
    return matchstr(a:msg, '^WorkbookBEGIN:---- \zs\S\+\ze ----$')
endf


function! s:prototype.GetPlaceholderFromEndMark(msg) abort dict "{{{3
    return matchstr(a:msg, '^WorkbookEND:---- \zs\S\+\ze ----$')
endf


function! s:prototype.GetCommentLineRx(...) abort dict "{{{3
    let highlight = a:0 >= 1 ? a:1 : 0
    let rxf = self.GetCommentLineRxf()
    let brx = a:0 >= 2 ? a:2 : (rxf =~ '%s$' ? '.*' : '.\{-}')
    if highlight
        let brx = '\zs'.brx
    endif
    return printf('^\s*'. rxf. '$', brx)
endf


function! s:prototype.GetResultLineRx(...) abort dict "{{{3
    let highlight = a:0 >= 1 ? a:1 : 0
    let rxf = self.GetCommentLineRxf()
    let brx = a:0 >= 2 ? a:2 : (rxf =~ '%s$' ? '.*' : '.\{-}')
    if highlight
        let brx = '\zs'.brx
    endif
    return printf('^\s*'. rxf. '$', '=[>!?] '. brx)
endf


function! s:prototype.GetResultLine(type, result) abort dict "{{{3
    let f = self.GetResultLinef()
    if a:type ==# 'p'
        let tid = '=?'
    elseif a:type ==# 'e'
        let tid = '=!'
    else
        let tid = '=>'
    endif
    return printf(f, tid .' '. a:result)
endf


function! s:prototype.SetPlaceholder(bufnr, placeholder, pline) abort dict "{{{3
    let rid = self.id
    call add(self.placeholder_queue, a:placeholder)
    let self.placeholders[a:placeholder] = {'pline': a:pline, 'bufnr': a:bufnr}
endf

function! s:prototype.GetPlaceholder(code) abort dict "{{{3
    let tid = printf('%s|%s|%s', bufnr('%'), string(reltime()), a:code)
    let id = sha256(tid)
    return id
endf


" TODO Should this be a function that scans all repls?
function! s:prototype.IsKnownPlaceholder(placeholder) abort dict "{{{3
    Tlibtrace 'workbook', 'IsKnownPlaceholder', a:placeholder
    if has_key(self.placeholders, a:placeholder)
        Tlibtrace 'workbook', 'IsKnownPlaceholder', 1
        return 1
    endif
    return 0
endf


function! s:prototype.GetCurrentPlaceholder() abort dict "{{{3
    return self.placeholder_queue[0]
endf


function! s:prototype.PrepareMessage(msg) abort dict "{{{3
    return substitute(a:msg, "\r", '', 'g')
endf


function! s:prototype.ConsumeOutput(type, msg, ...) abort dict "{{{3
    call assert_true(type(a:type) == v:t_string)
    call assert_true(type(a:msg) == v:t_string || type(a:msg) == v:t_list)
    let placeholder0 = a:0 >= 1 ? a:1 : ''
    let id = self.id
    Tlibtrace 'workbook', 'ConsumeOutput', id, a:type, a:msg
    let msg = self.PrepareMessage(a:msg)
    let msg = has_key(self, 'ProcessMessage') ? self.ProcessMessage(msg) : msg
    let parts = self.SplitMessage(msg)
    if has_key(self, 'FilterMessageLines')
        let parts = self.FilterMessageLines(parts)
    endif
    if has_key(self, 'ProcessLine')
        let parts = map(parts, {i, val -> self.ProcessLine(val)})
    endif
    for part in parts
        Tlibtrace 'workbook', 'ConsumeOutput', part
        if empty(placeholder0)
            if has_key(self, 'GetPlaceholderFromBeginMark')
                let placeholder = self.GetPlaceholderFromBeginMark(part)
                if !empty(placeholder)
                    Tlibtrace 'workbook', 'ConsumeOutput', 'BEGIN', placeholder
                    call self.FlushOutput()
                    continue
                endif
            endif
            if has_key(self, 'GetPlaceholderFromEndMark')
                let placeholder = self.GetPlaceholderFromEndMark(part)
                if !empty(placeholder)
                    Tlibtrace 'workbook', 'ConsumeOutput', 'END', placeholder
                    call self.ProcessOutput(placeholder)
                    continue
                endif
            endif
        endif
        if self.DoTranscribe() && empty(self.next_process_output)
            call self.Transcribe('r', [part])
        endif
        if get(self, 'ignore_output', 0) == 0 && !empty(part)
            let line = !empty(self.next_process_output) ? part : self.GetResultLine(a:type, part)
            call add(self.lines_buffer, line)
        endif
    endfor
    Tlibtrace 'workbook', 'ConsumeOutput', placeholder0
    if !empty(placeholder0)
        call self.ProcessOutput(placeholder0)
    endif
endf


function! s:prototype.ConsumeError(msg, ...) abort dict "{{{3
    call assert_true(type(a:msg) == v:t_string || type(a:msg) == v:t_list)
    Tlibtrace 'workbook', 'ConsumeError', a:msg
    let msg = self.PrepareMessage(a:msg)
    let parts = self.SplitMessage(msg)
    Tlibtrace 'workbook', 'ConsumeError', parts
    if !empty(parts)
        let id = self.id
        Tlibtrace 'workbook', 'ConsumeError', id
        if self.DoTranscribe()
            call self.Transcribe('e', parts)
        else
            echohl ErrorMsg
            echom 'Workbook:' join(parts, '; ')
            echohl NONE
        endif
    endif
endf


function! s:prototype.SplitMessage(msg) abort dict "{{{3
    Tlibtrace 'workbook', 'SplitMessage', a:msg
    if type(a:msg) == v:t_string
        let parts = split(a:msg, "\n", 1)
        " while !empty(parts) && empty(parts[-1])
        "     call remove(parts, -1)
        " endwh
    else
        let parts = a:msg
    endif
    return parts
endf


" function! s:prototype.Trace(id, ...) abort dict "{{{3
"     Tlibtrace 'workbook', a:id, a:000
"     let line = printf('%s: %s', a:id, join(map(a:000, {i,v -> string(v)}), '; '))
"     call self.Transcribe('d', [line])
" endf


function! s:prototype.Transcribe(type, lines, ...) abort dict "{{{3
    Tlibtrace 'workbook', 'Transcribe', a:type, a:lines
    if empty(a:lines)
        return
    endif
    let redraw = a:0 >= 1 ? a:1 : 0
    let lines = copy(a:lines)
    let start_new_line = a:type =~# '^[ed]$'
    if a:type =~# '^[ic]$'
        let lines = map(lines, {i,v -> printf(self.GetResultLinef(), (i == 0 ? '> ' : '+ '). v)})
        if a:type ==# 'c'
            call add(lines, '')
        endif
    else
        let lines = filter(lines, {i,v -> !empty(v)})
        if a:type ==# 'e'
            let lines = map(lines, {i,v -> printf("!!!\t%s", v)})
        elseif a:type ==# 'd'
            let lines = map(lines, {i,v -> printf("DDD\t%s", v)})
        endif
    endif
    Tlibtrace 'workbook', lines
    if empty(lines)
        return
    endif
    if !empty(self.output_buffer) && (!start_new_line || empty(self.output_buffer[-1]))
        let [first; rest] = lines
        Tlibtrace 'workbook', first, rest
        let self.output_buffer[-1] .= first
        if !empty(rest)
            call extend(self.output_buffer, rest)
        else
            call add(self.output_buffer, '')
        endif
    else
        call extend(self.output_buffer, lines)
    endif
    " call extend(self.output_buffer, lines)
    if has_key(self, 'redraw_timer')
        call timer_stop(self.redraw_timer)
    endif
    if redraw
        call self.TranscribeNow(get(self, 'redraw_timer', 0))
        redraw
    else
        let self.redraw_timer = timer_start(500, self.TranscribeNow)
    endif
endf


function! s:prototype.GetTranscriptId() abort dict "{{{3
    let tid = '__Transript_'. self.id  .'__'
    return tid
endf


function! s:prototype.TranscribeNow(timer) abort dict "{{{3
    Tlibtrace 'workbook', 'TranscribeNow', self.id, a:timer
    if has_key(self, 'redraw_timer') && self.redraw_timer == a:timer
        call remove(self, 'redraw_timer')
    endif
    let show = a:0 >= 1 ? a:1 : 0
    let tabnr = tabpagenr()
    let winnr = winnr()
    let bufnr = bufnr('%')
    let tid = self.GetTranscriptId()
    try
        if bufnr(tid) == -1 || (!self.DoInsertResultsInBuffer() && bufwinnr(tid) == -1)
            if !exists('b:workbook_log_buffer')
                let ft = self.filetype
                exec g:workbook#repl#transript_new_cmd fnameescape(tid)
                " exec 'lcd' fnameescape(self.working_dir)
                setlocal buftype=nofile
                setlocal noswapfile
                " setlocal nobuflisted
                " setlocal foldmethod=manual
                " setlocal foldcolumn=0
                setlocal nospell
                setlocal modifiable
                setlocal noreadonly
                exec 'setl ft='. get(self, 'transcript_filetype', ft)
                syntax match WorkbookError /^!!!\t.*$/
                hi def link WorkbookError ErrorMsg
                syntax match WorkbookDebug /^\CDDD\t.*$/
                hi def link WorkbookDebug NonText
                let b:workbook_log_buffer = self.id
                let self.bufnr = bufnr('%')
                Workbook
                " call workbook#SetupBuffer()
                let hd = printf(self.GetResultLinef(), '! '. strftime('%c') .' -- '. self.id)
                call append(0, hd)
            endif
        else
            exec g:workbook#repl#transript_drop_cmd fnameescape(tid)
        endif
        if !empty(self.output_buffer)
            call append('$', self.output_buffer)
            let self.output_buffer = []
            $
            " redraw
        endif
    finally
        if tabpagenr() != tabnr
            exec 'tabnext' tabnr
        endif
        if winnr() != winnr
            exec winnr 'wincmd w'
        endif
        if self.bufnr != bufnr
            exec 'hide buffer' bufnr
        endif
    endtry
    if bufwinnr(tid) == -1
        exec g:workbook#repl#transript_new_cmd fnameescape(tid)
    endif
endf


function! s:prototype.FlushOutput() abort dict "{{{3
    Tlibtrace 'workbook', 'FlushOutput'
    let lines = self.lines_buffer
    let self.lines_buffer = []
    return lines
endf


function! s:prototype.ProcessOutput(...) abort dict "{{{3
    let placeholder = a:0 >= 1 ? a:1 : self.GetCurrentPlaceholder()
    let id = self.id
    Tlibtrace 'workbook', 'ProcessOutput', id, placeholder
    while !empty(self.lines_buffer) && empty(self.lines_buffer[0])
        call remove(self.lines_buffer, 0)
    endwh
    while !empty(self.lines_buffer) && empty(self.lines_buffer[-1])
        call remove(self.lines_buffer, -1)
    endwh
    let pi = index(self.placeholder_queue, placeholder)
    if pi == -1
        echom 'Workbook queue' self.id string(self.placeholder_queue)
        echom 'Workbook names' self.id string(keys(self.placeholders))
        throw 'Workbook: Internal error: Placeholder not in queue: '. string(placeholder)
    else
        let obsoletes = remove(self.placeholder_queue, 0, pi)
        let lines = self.FlushOutput()
        Tlibtrace 'workbook', 'ProcessOutput', lines
        if has_key(self, 'FilterOutputLines')
            let lines = self.FilterOutputLines(lines)
        endif
        let pdef = remove(self.placeholders, placeholder)
        if !empty(self.next_process_output)
            call call(self.next_process_output, [lines])
            let self.next_process_output = ''
        else
            let pbufnr = pdef.bufnr
            let pline = pdef.pline
            let bufnr = bufnr('%')
            let pos = getpos('.')
            " echom "DBG" string(pos)
            Tlibtrace 'workbook', 'ProcessOutput', bufnr, pos, pline
            try
                if empty(pline)
                    for line in lines
                        echom line
                    endfor
                else
                    if bufnr('%') != pbufnr
                        exec 'hide buffer' pbufnr
                    endif
                    let plnum = search('\V'. pline .'\$', 'bw')
                    if plnum > 0
                        Tlibtrace 'workbook', 'ProcessOutput', plnum
                        if !empty(lines)
                            call append(plnum, lines)
                        endif
                        exec plnum 'delete'
                    endif
                endif
                for obsolete in obsoletes[0:-2]
                    Tlibtrace 'workbook', 'ProcessOutput', obsolete
                    let pdef = remove(self.placeholders, obsolete)
                    let pline = pdef.pline
                    if !empty(pline)
                        let pbufnr = pdef.bufnr
                        if bufnr('%') != pbufnr
                            exec 'hide buffer' pbufnr
                        endif
                        let plnum = search('\V'. pline .'\$', 'bw')
                        if plnum > 0
                            exec 'delete'
                        endif
                    endif
                endfor
            finally
                if bufnr('%') != bufnr
                    exec 'hide buffer' bufnr
                endif
                call setpos('.', pos)
                Tlibtrace 'workbook', 'ProcessOutput', pos, getpos('.')
            endtry
            " echom "DBG" string(pos)
        endif
    endif
endf


