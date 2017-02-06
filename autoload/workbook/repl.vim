" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-02-06
" @Revision:    159


if !exists('g:workbook#repl#transript_new_cmd')
    let g:workbook#repl#transript_new_cmd = 'vert split'   "{{{2
endif

if !exists('g:workbook#repl#transript_drop_cmd')
    let g:workbook#repl#transript_drop_cmd = 'drop'   "{{{2
endif


let s:prototype = {
            \ 'bufnrs': {},
            \ 'ignore_lines': [],
            \ 'next_cmd': [],
            \ 'placeholders': {},
            \ 'placeholder_queue': [],
            \ 'placeholder_lines': []}


function! workbook#repl#New(ext) abort "{{{3
    let o = extend(deepcopy(s:prototype), a:ext)
    let ft = get(o, 'filetype', &filetype)
    let o = workbook#ft#{ft}#New(o)
    return o
endf


function! s:prototype.Start() abort dict "{{{3
    let cmd = substitute(self.GetCmd(), '\\', '/', 'g')
    Tlibtrace 'workbook', cmd
    let self.job = job_start(cmd, {'in_mode': 'raw', 'out_mode': 'nl', 'err_mode': 'nl'
                \ , 'exit_cb': {job, status -> self.ExitCb(job, status)}
                \ , 'out_cb': {ch, msg -> self.OutCb(ch, msg)}
                \ , 'err_cb': {ch, msg -> self.ErrCb(ch, msg)}
                \ })
endf


function! s:prototype.Stop(args) abort dict "{{{3
    if has_key(self, 'ExitFiletype')
        call self.ExitFiletype(a:args)
    endif
    call job_stop(self.job)
endf


function! s:prototype.SendToChannel(fn, code, ...) abort dict "{{{3
    let direct = a:0 >= 1 ? a:1 : 0
    if !direct && has_key(self, 'PrepareEvaluation')
        call self.PrepareEvaluation(a:code)
    endif
    let channel = job_getchannel(self.job)
    return call(a:fn, [channel, a:code])
endf


" async
function! s:prototype.Input(code) abort dict "{{{3
    if job_status(self.job) == 'run'
        Tlibtrace 'workbook', len(a:code)
        call self.SendToChannel(function('ch_sendraw'), a:code)
    elseif !has_key(self, 'teardown')
        echohl WarningMsg
        echom 'Workbook.Send: REPL' self.id 'is not running'
        echohl NONE
    endif
endf


" async
function! s:prototype.Send(placeholder, code) abort dict "{{{3
    if job_status(self.job) == 'run'
        Tlibtrace 'workbook', len(a:code)
        let code = g:workbook#insert_results_in_buffer ? self.WrapCode(a:placeholder, a:code) : a:code
        Tlibtrace 'workbook', code
        call self.SendToChannel(function('ch_sendraw'), code ."\n")
    elseif !has_key(self, 'teardown')
        echohl WarningMsg
        echom 'Workbook.Send: REPL' self.id 'is not running'
        echohl NONE
    endif
endf


" sync
function! s:prototype.Eval(code) abort dict "{{{3
    if job_status(self.job) == 'run'
        let channel = job_getchannel(self.job)
        Tlibtrace 'workbook', len(a:code)
        let self.ignore_output = 1
        try
            let response = self.SendToChannel(function('ch_evalraw'), a:code ."\n")
            if has_key(self, 'ProcessLine')
                let response = self.ProcessLine(response)
            endif
        finally
            let self.ignore_output = 0
        endtry
    else
        if !has_key(self, 'teardown')
            echohl WarningMsg
            echom 'Workbook.Eval: REPL' self.id 'is not running'
            echohl NONE
        endif
        let response = ''
    endif
    return response
endf


function! s:prototype.ExitCb(job, status) abort dict "{{{3
    echohl WarningMsg
    echom 'Workbook: REPL' self.id 'has exited with status' a:status
    echohl NONE
    let self.teardown = 1
    call workbook#Stop({}, self)
endf


function! s:prototype.OutCb(ch, msg) abort dict "{{{3
    Tlibtrace 'workbook', a:msg
    if get(self, 'ignore_output', 0)
        return
    endif
    let placeholder = self.GetPlaceholderFromEndMark(a:msg)
    Tlibtrace 'workbook', placeholder
    if !empty(placeholder) && self.IsKnownPlaceholder(placeholder)
        call self.ProcessOutput(placeholder)
    else
        call self.ConsumeOutput('', a:msg, placeholder)
    endif
endf


function! s:prototype.ErrCb(ch, msg) abort dict "{{{3
    Tlibtrace 'workbook', a:msg
    call self.ConsumeError(a:msg)
endf


function! s:prototype.GetCmd() abort dict "{{{3
    if !has_key(self, 'cmd')
        let self.cmd = self.GetReplCmd()
        Tlibtrace 'workbook', self.cmd
    endif
    return self.cmd
endf


function! s:prototype.GetResultLineRx(...) abort dict "{{{3
    let highlight = a:0 >= 1 ? a:1 : 0
    let rxf = self.GetResultLineRxf()
    let brx = rxf =~ '%s$' ? '.*' : '.\{-}'
    if highlight
        let brx = '\zs'.brx
    endif
    return printf('^\s*'. rxf, '=[>!?]', brx)
endf


function! s:prototype.GetResultLine(type, result) abort dict "{{{3
    let rxf = self.GetResultLineRxf()
    if a:type ==# 'p'
        let tid = '=?'
    elseif a:type ==# 'e'
        let tid = '=!'
    else
        let tid = '=>'
    endif
    return printf(rxf, tid, a:result)
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
    Tlibtrace 'workbook', a:placeholder
    if has_key(self.placeholders, a:placeholder)
        Tlibtrace 'workbook', 1
        return 1
    endfor
    return 0
endf


function! s:prototype.GetCurrentPlaceholder() abort dict "{{{3
    return self.placeholder_queue[0]
endf


function! s:prototype.FilterIgnoredLines(lines) abort dict "{{{3
    if len(self.ignore_lines) == 0
        return a:lines
    else
        let lines = a:lines
        Tlibtrace 'workbook', lines
        Tlibtrace 'workbook', self.ignore_lines
        let iline = self.ignore_lines[0]
        let ii = index(lines, iline)
        if ii != -1
            call remove(lines, ii)
            call remove(self.ignore_lines, 0)
            Tlibtrace 'workbook', lines
        endif
        return lines
    endif
endf


function! s:prototype.ConsumeOutput(type, msg, ...) abort dict "{{{3
    call assert_true(type(a:type) == v:t_string)
    call assert_true(type(a:msg) == v:t_string || type(a:msg) == v:t_list)
    let id = self.id
    Tlibtrace 'workbook', id, a:type
    let parts = self.PrepareMessage(a:msg)
    let parts = self.FilterIgnoredLines(parts)
    if has_key(self, 'FilterLines')
        let parts = self.FilterLines(parts)
    endif
    if has_key(self, 'ProcessLine')
        let parts = map(parts, {i, val -> self.ProcessLine(val)})
    endif
    while len(parts) > 0 && parts[0] ==# ''
        call remove(parts, 0)
    endwh
    while len(parts) > 0 && parts[-1] ==# ''
        call remove(parts, -1)
    endwh
    if g:workbook#transcript
        call self.Transcribe('r', parts)
    endif
    let lines = map(parts, {i, val -> self.GetResultLine(a:type, val)})
    " Tlibtrace 'workbook', placeholder, len(lines)
    Tlibtrace 'workbook', lines
    let self.placeholder_lines += lines
endf


function! s:prototype.ConsumeError(msg, ...) abort dict "{{{3
    call assert_true(type(a:msg) == v:t_string || type(a:msg) == v:t_list)
    Tlibtrace 'workbook', a:msg
    let parts = self.PrepareMessage(a:msg)
    Tlibtrace 'workbook', parts
    let parts = self.FilterIgnoredLines(parts)
    Tlibtrace 'workbook', parts
    if !empty(parts)
        let id = self.id
        Tlibtrace 'workbook', id
        echohl ErrorMsg
        echom 'Workbook:' join(parts, '; ')
        echohl NONE
    endif
endf


function! s:prototype.PrepareMessage(msg) abort dict "{{{3
    Tlibtrace 'workbook', a:msg
    if type(a:msg) == v:t_string
        let parts = split(a:msg, "\n", 1)
    else
        let parts = a:msg
    endif
    return parts
endf


function! s:prototype.Transcribe(type, lines, ...) abort dict "{{{3
    Tlibtrace 'workbook', self.id, a:type, a:lines
    let show = a:0 >= 1 ? a:1 : 0
    let tabnr = tabpagenr()
    let winnr = winnr()
    let bufnr = bufnr('%')
    let tid = '__Transript_'. self.id  .'__'
    try
        if bufnr(tid) == -1 || (!g:workbook#insert_results_in_buffer && bufwinnr(tid) == -1)
            let ft = &ft
            exec g:workbook#repl#transript_new_cmd fnameescape(tid)
            setlocal buftype=nofile
            setlocal noswapfile
            " setlocal nobuflisted
            " setlocal foldmethod=manual
            " setlocal foldcolumn=0
            setlocal nospell
            setlocal modifiable
            setlocal noreadonly
            exec 'setf' ft
            let hd = printf(self.GetResultLineRxf(), '!', strftime('%c') .' -- '. self.id)
            call append(0, hd)
        else
            exec g:workbook#repl#transript_drop_cmd fnameescape(tid)
        endif
        if a:type =~# '^[ic]$'
            let lines = map(copy(a:lines), {i,v -> printf(self.GetResultLineRxf(), i == 0 ? '>' : '+', v)})
            if a:type ==# 'c'
                call insert(lines, '')
            endif
        else
            let lines = a:lines
        endif
        call append('$', lines)
        if exists('s:redraw_timer')
            call timer_stop(s:redraw_timer)
        endif
        call timer_start(500, 'workbook#repl#Redraw')
        $
    finally
        if tabpagenr() != tabnr
            exec 'tabnext' tabnr
        endif
        if winnr() != winnr
            exec winnr 'wincmd w'
        endif
        if bufnr('%') != bufnr
            exec 'hide buffer' bufnr
        endif
    endtry
    if bufwinnr(tid) == -1
        exec g:workbook#repl#transript_new_cmd fnameescape(tid)
    endif
endf


function! s:prototype.ProcessOutput(...) abort dict "{{{3
    let placeholder = a:0 >= 1 ? a:1 : self.GetCurrentPlaceholder()
    let id = self.id
    Tlibtrace 'workbook', id, placeholder
    let pi = index(self.placeholder_queue, placeholder)
    if pi == -1
        echom 'Workbook queue' self.id string(self.placeholder_queue)
        echom 'Workbook names' self.id string(keys(self.placeholders))
        throw 'Workbook: Internal error: Placeholder not in queue: '. string(placeholder)
    else
        let obsoletes = remove(self.placeholder_queue, 0, pi)
        let lines = self.placeholder_lines
        Tlibtrace 'workbook', lines
        let self.placeholder_lines = []
        let pdef = remove(self.placeholders, placeholder)
        let pbufnr = pdef.bufnr
        let pline = pdef.pline
        let bufnr = bufnr('%')
        let pos = getpos('.')
        Tlibtrace 'workbook', bufnr, pos, pline
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
                    Tlibtrace 'workbook', plnum
                    if !empty(lines)
                        call append(plnum, lines)
                    endif
                    exec plnum 'delete'
                endif
            endif
            for obsolete in obsoletes[0:-2]
                Tlibtrace 'workbook', obsolete
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
            Tlibtrace 'workbook', pos, getpos('.')
        endtry
    endif
endf


function! workbook#repl#Redraw(timer) abort "{{{3
    redraw
endf


