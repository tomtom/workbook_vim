" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-03-27
" @Revision:    855


if v:version < 800
    echoerr 'Workbook requires VIM 8.0 and above'
    finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 122
    runtime plugin/tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 122
        echoerr 'tlib >= 1.22 is required'
        finish
    endif
endif

if exists(':Tlibtrace') != 2
    command! -nargs=+ -bang Tlibtrace :
endif


if !exists('g:workbook#map_op')
    " Operator map
    let g:workbook#map_op = '<localleader>e'   "{{{2
endif

if !exists('g:workbook#map_leader')
    " Map leader
    let g:workbook#map_leader = '<localleader>w'   "{{{2
endif

if !exists('g:workbook#map_evalline')
    " Evaluate the current line.
    let g:workbook#map_evalline = '<s-cr>'   "{{{2
endif

if !exists('g:workbook#map_evalblock')
    " Evaluate the current paragraph or the current visual selection.
    let g:workbook#map_evalblock = '<c-cr>'   "{{{2
endif

if !exists('g:workbook#map_evalinsertblock')
    " Evaluate the current paragraph and always insert the result.
    let g:workbook#map_evalinsertblock = '<c-s-cr>'   "{{{2
endif

if !exists('g:workbook#transcript')
    " If true, maintain a transcript
    let g:workbook#transcript = 1   "{{{2
endif

if !exists('g:workbook#insert_results_in_buffer')
    " If not zero, insert the results of an evaluation below the 
    " evaluated code.
    " If 1, insert the result.
    "
    " This parameter will be overridden by the value of 
    " b:workbook_insert_results_in_buffer_once or 
    " b:workbook_insert_results_in_buffer if existant.
    let g:workbook#insert_results_in_buffer = 1   "{{{2
    " If -1, insert the result only if the transcipt isn't visible.
endif

if !exists('g:workbook#debug')
    let g:workbook#debug = 0   "{{{2
endif


if !exists('g:workbook#handlers')
    let g:workbook#handlers = [{'key': 5, 'agent': 'workbook#EditItem', 'key_name': '<c-e>', 'help': 'Edit item'}]   "{{{2
endif


augroup Workbook
    autocmd VimLeave * call workbook#StopAll()
augroup END


let s:repls = {}
let s:buffers = {}
let s:workbook_args = {
            \ 'help': 'workbook.txt',
            \ 'trace': 'workbook',
            \ 'values': {
            \   'cmd': {'type': 1},
            \   'args': {'type': 1},
            \   'save': {'type': -1},
            \   'filetype': {'type': 1, 'complete_customlist': 'workbook#GetSupportedFiletypes()'},
            \ },
            \ 'flags': {
            \ },
            \ }


function! s:GetBufRepl(bufnr) abort "{{{3
    Tlibtrace 'workbook', a:bufnr
    let rid = s:buffers[a:bufnr]
    Tlibtrace 'workbook', rid
    return s:repls[rid]
endf


function! workbook#GetRepl(...) abort "{{{3
    Tlibtrace 'workbook', a:0
    if a:0 >= 1
        if type(a:1) == 4
            let args = a:1
        else
            let args = tlib#arg#GetOpts(a:1, s:workbook_args)
        endif
    else
        let args = {}
    endif
    let reset = a:0 >= 2 ? a:2 : 0
    let bufnr = bufnr('%')
    Tlibtrace 'workbook', reset, bufnr, keys(args)
    if reset && has_key(s:buffers, bufnr)
        call workbook#Stop(args, s:GetBufRepl(bufnr))
    endif
    if !has_key(s:buffers, bufnr)
        let repl = workbook#InitBuffer(args, bufnr)
    else
        let repl = s:GetBufRepl(bufnr)
    endif
    return repl
endf


function! workbook#GetID(args, bufnr) abort "{{{3
    Tlibtrace 'workbook', a:bufnr, keys(a:args)
    let id = printf('%s/%s_%s', getcwd(), getbufvar(a:bufnr, '&ft', ''), join(get(a:args, '__rest__', []), ','))
    return id
endf


function! workbook#InitBuffer(args, ...) abort "{{{3
    let bufnr = a:0 >= 1 ? a:1 : bufnr('%')
    let id = workbook#GetID(a:args, bufnr)
    Tlibtrace 'workbook', bufnr, id
    if has_key(s:repls, id)
        let repl = s:repls[id]
    else
        let repl = workbook#repl#New(a:args)
        let repl.id = id
        call repl.Start()
        if has_key(repl, 'InitFiletype')
            call repl.InitFiletype()
        endif
        let s:repls[id] = repl
    endif
    let s:buffers[bufnr] = id
    " if has_key(repl, 'result_syntax')
    "     let rl = repl.GetResultLineRx(1)
    "     let group = repl.result_syntax
    "     echom 'syntax include @WorkbookResult syntax/'. repl.filetype .'.vim'
    "     exec 'syntax include @WorkbookResult syntax/'. repl.filetype .'.vim'
    "     echom 'syntax match WorkbookResultLine /'. escape(rl, '/') .'/ contains=@WorkbookResult containedin='. group
    "     exec 'syntax match WorkbookResultLine /'. escape(rl, '/') .'/ contains=@WorkbookResult containedin='. group
    " endif
    call workbook#SetupBuffer(repl)
    call workbook#InitQuicklist(2, repl)
    if has_key(repl, 'InitBufferFiletype')
        call repl.InitBufferFiletype()
    endif
    return repl
endf


function! workbook#InitQuicklist(mode, ...) abort "{{{3
    let do_init = 0
    if a:mode == 1
        let do_init = exists('g:workbook#ft#'. &filetype .'#quicklist')
    endif
    if a:mode == 2 && !do_init
        let repl = a:0 >= 1 ? a:1 : workbook#GetRepl()
        let do_init = has_key(repl, 'GetQuicklist')
    endif
    if do_init
        exec 'nnoremap <buffer> '. g:workbook#map_leader .'q :call workbook#Quicklist(expand("<cword>"))<cr>'
        exec 'xnoremap <buffer> '. g:workbook#map_leader .'q :call workbook#Quicklist(join(tlib#selection#GetSelection("v"), " "))<cr>'
    endif
endf


" In workbooks the following maps can be used:
" |g:workbook#map_evalblock| ... Eval the current block (usually the 
"               current paragraph or visually selected code)
" |g:workbook#map_evalinsertblock ... Eval the current block with 
"               |g:workbook#insert_results_in_buffer| reverted
" |g:workbook#map_op|{motion} ... Operator: eval some code
" |g:workbook#map_op| ... Visual mode: eval some code
"
" In the following maps, <WML> is |g:workbook#map_leader|:
" <WML>r    ... Interactive REPL (sort of)
" <WML>z    ... Reset the inferior process (if supported)
" <WML>c    ... Remove the next result block
" <WML>C    ... Remove all result blocks in the current buffer
" <WML>q    ... Display the quicklist (if supported)
" <WML><F1> ... Get some help
function! workbook#SetupBuffer(...) abort "{{{3
    let repl = a:0 >= 1 ? a:1 : {}
    if !exists('b:workbook_setup_done')
        let b:workbook_setup_done = 1
        autocmd Workbook Bufwipeout <buffer> call workbook#RemoveBuffer(expand('<abuf>'))
        " Send code to the REPL.
        command -buffer -nargs=1 Workbooksend call workbook#Send(<q-args>)
        " Eval some code and display the result.
        command -buffer -nargs=1 Workbookeval echo workbook#Eval(<q-args>)
        " Remove the current block's placeholder.
        command -buffer Workbookrepl call workbook#InteractiveRepl()
        " Remove any placeholders in the current buffer.
        command -buffer Workbookclear call workbook#StripResults(1, line('$'))
        " Display help on available maps etc.
        command -buffer Workbookhelp call workbook#Help()
        " Reset a REPL's state.
        command -buffer Workbookreset call workbook#Reset()
        exec 'nmap <expr> <buffer>' g:workbook#map_evalblock 'workbook#EvalBlockExpr("")'
        exec 'nmap <expr> <buffer>' g:workbook#map_evalinsertblock 'workbook#EvalBlockExpr(":let b:workbook_insert_results_in_buffer_once = 1\<cr>")'
        exec 'nnoremap <buffer>' g:workbook#map_evalline ':call workbook#Print(line("."), line("."))<cr>j$'
        exec 'nnoremap <buffer>' g:workbook#map_op ':set opfunc=workbook#Op<cr>g@'
        exec 'xnoremap <buffer>' g:workbook#map_op 'y:<c-u>call workbook#Op(visualmode(), 1)<cr>'
        exec 'xmap <buffer>' g:workbook#map_evalblock g:workbook#map_op
        exec 'nnoremap <buffer>' g:workbook#map_leader .'r :call workbook#InteractiveRepl()<cr>'
        exec 'nnoremap <buffer>' g:workbook#map_leader .'z :call workbook#ResetRepl()<cr>'
        exec 'nnoremap <buffer>' g:workbook#map_leader .'c :call workbook#StripResults(line("."), line("."))<cr>'
        exec 'nnoremap <buffer>' g:workbook#map_leader .'C :call workbook#StripResults(1, line("$"))<cr>'
        exec 'nnoremap <buffer>' g:workbook#map_leader .'<f1> :Workbookhelp<cr>'
        try
            let ft = get(repl, 'filetype', &filetype)
            call workbook#ft#{ft}#SetupBuffer()
		catch /^Vim\%((\a\+)\)\=:E117/
        endtry
        call workbook#InitQuicklist(1)
    endif
endf


function! workbook#SetOmnifunc() abort "{{{3
    if &omnifunc !=# 'workbook#OmniComplete'
        let b:workbook_orig_omnifunc = &omnifunc
        setlocal omnifunc=workbook#OmniComplete
    endif
endf


function! workbook#EvalBlockExpr(prefix) abort "{{{3
    let repl = a:0 >= 1 ? a:1 : workbook#GetRepl()
    let gbeg = s:GotoBeginOfBlockExpr(repl)
    let gnext = s:GotoNextBlockExpr()
    if empty(gbeg)
        return gnext
    else
        let gend = s:GotoEndOfBlockExpr(repl)
        if gend ==# gnext
            return gnext
        else
            let expr = g:workbook#map_op
            let ml = exists('g:mapleader') ? g:mapleader : '\'
            let expr = substitute(expr, '\c<leader>', escape(ml, '\'), 'g')
            if exists('g:maplocalleader')
                let expr = substitute(expr, '\c<localleader>', escape(g:maplocalleader, '\'), 'g')
            endif
            if !empty(a:prefix)
                let expr = a:prefix . expr
            endif
            let expr .= gend
            Tlibtrace 'workbook', expr
            return expr
        endif
    endif
endf


function! s:GotoBeginOfBlockExpr(...) abort "{{{3
    let repl = a:0 >= 1 ? a:1 : workbook#GetRepl()
    let line = getline('.')
    let rhs = has_key(repl, 'GotoBeginOfBlockExpr') ? repl.GotoBeginOfBlockExpr(0) : '^'
    Tlibtrace 'workbook', rhs
    return rhs
endf


function! s:GotoEndOfBlockExpr(...) abort "{{{3
    let repl = a:0 >= 1 ? a:1 : workbook#GetRepl()
    let default = a:0 >= 1 ? a:1 : 'ip}'
    let line = getline('.')
    if line =~ '\S'
        " && synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name") !=# 'Comment'
        let rhs = has_key(repl, 'GotoEndOfBlockExpr') ? repl.GotoEndOfBlockExpr(0) : 'ip}'
    else
        let rhs = s:GotoNextBlockExpr(repl)
    endif
    Tlibtrace 'workbook', rhs
    return rhs
endf


function! s:GotoNextBlockExpr(...) abort "{{{3
    let repl = a:0 >= 1 ? a:1 : workbook#GetRepl()
    " let repl.ignore_input = 1
    let rhs = has_key(repl, 'GotoNextBlockExpr') ? repl.GotoNextBlockExpr() : 'j^'
    Tlibtrace 'workbook', rhs
    return rhs
endf


function! workbook#UndoSetup() abort "{{{3
    let repl = workbook#GetRepl()
    let bufnr = bufnr('%')
    if has_key(s:buffers, bufnr)
        if has_key(repl, 'UndoFiletype')
            call repl.UndoFiletype()
        endif
    endif
    delcommand Workbooksend
    delcommand Workbookeval
    delcommand Workbookrepl
    delcommand Workbookclear
    exec 'nunmap <buffer>' g:workbook#map_evalblock
    exec 'nunmap <buffer>' g:workbook#map_evalinsertblock
    exec 'nunmap <buffer>' g:workbook#map_evalline
    exec 'nunmap <buffer>' g:workbook#map_op
    exec 'xunmap <buffer>' g:workbook#map_op
    exec 'nunmap <buffer>' g:workbook#map_leader .'<f1>'
    exec 'nunmap <buffer>' g:workbook#map_leader .'r'
    exec 'nunmap <buffer>' g:workbook#map_leader .'z'
    exec 'nunmap <buffer>' g:workbook#map_leader .'c'
    exec 'nunmap <buffer>' g:workbook#map_leader .'C'
    exec 'silent! nunmap <buffer>' g:workbook#map_leader .'q'
    exec 'silent! xunmap <buffer>' g:workbook#map_leader .'q'
    if exists('b:workbook_orig_omnifunc')
        let &l:omnifunc = b:workbook_orig_omnifunc
        unlet! b:workbook_orig_omnifunc
    endif
    unlet! b:workbook_setup_done
    try
        let filetype = get(repl, 'filetype', &filetype)
        call workbook#ft#{filetype}#UndoSetup()
    catch /^Vim\%((\a\+)\)\=:E117/
    endtry
endf


function! workbook#Help() abort "{{{3
    echom 'Commands:'
    " :nodoc:
    command Workbook
    echom ' '
    echom 'Maps:'
    echom 'Use' g:workbook#map_evalblock 'to evaluate the current paragraph.'
    echom 'Use' g:workbook#map_evalinsertblock 'to evaluate the current paragraph with g:workbook#insert_results_in_buffer inversed.'
    echom 'Use' g:workbook#map_evalline 'to evaluate the current line.'
    exec 'map' g:workbook#map_op
    exec 'map' g:workbook#map_leader
    echom ' '
    echom 'Type `:h workbook` for more help'
endf


" Called from BufWipeout
" :nodoc:
function! workbook#RemoveBuffer(bufnr) abort "{{{3
    if has_key(s:buffers, a:bufnr)
        let id = remove(s:buffers, a:bufnr)
        Tlibtrace 'workbook', a:bufnr, id
        if index(values(s:buffers), id) ==# -1
            let repl = s:repls[id]
            call workbook#Stop({}, repl)
        endif
    endif
endf


function! workbook#Op(type, ...) abort "{{{3
    Tlibtrace 'workbook', a:type, a:000
    call assert_true(type(a:type) == v:t_string)
    let sel_save = &selection
    let &selection = 'inclusive'
    let reg_save = @@
    try
        if a:0 >= 1  " Invoked from Visual mode, use gv command.
            " silent exec "normal! gvy"
            let repl = workbook#GetRepl()
            let code = @@
            if repl.DoTranscribe()
                call repl.Transcribe('c', split(code, '\n'))
            endif
            call repl.Send(code, '')
        else
            let l1 = line("'[")
            let l2 = line("']")
            Tlibtrace 'workbook', l1, l2, a:type, col("`["), col("`]")
            if a:type ==# 'line'
                call workbook#Print(l1, l2)
                return
            else
                silent exec "normal! `[v`]y"
                " if index(['v', 'V', "\<c-v>"], a:type) == -1
                "     if a:type ==# 'block'
                "         silent exec "normal! `[\<C-V>`]y"
                "         " elseif a:type ==# 'char'
                "         "     silent exec "normal! `[v`]y"
                "         " elseif a:type ==# "\<C-V>"
                "         " elseif a:type ==# 'v'
                "         " silent exec "normal! y"
                "     else
                "         silent exec "normal! `[v`]y"
                "     endif
                " endif
            endif
            let lines = split(@@, "\n")
            Tlibtrace 'workbook', a:type, @@, lines
            call workbook#Print(l1, l2, lines)
        endif
        " norm! `<
    finally
        let &selection = sel_save
        let @@ = reg_save
    endtry
endf


function! workbook#Stop(...) abort "{{{3
    if a:0 >= 1
        if type(a:1) == 4
            let args = a:1
        else
            let args = tlib#arg#GetOpts(a:1, s:workbook_args)
        endif
    else
        let args = {}
    endif
    call assert_true(type(args) == v:t_dict)
    if a:0 >= 2
        let repl = a:2
    else
        if has_key(s:buffers, bufnr('%'))
            let repl = workbook#GetRepl(args)
        else
            return
        endif
    endif
    call assert_true(type(repl) == v:t_dict)
    let id = repl.id
    Tlibtrace 'workbook', id
    if has_key(s:repls, id)
        let s:buffers = filter(s:buffers, 'v:val != id')
        call repl.Stop(args)
        unlet! s:repls[id]
    endif
    call assert_true(index(values(s:buffers), id) == -1)
    call assert_true(index(keys(s:repls), id) == -1)
endf


function! workbook#StopAll(...) abort "{{{3
    let args = a:0 >= 1 ? a:1 : {}
    for repl in values(s:repls)
        call repl.Stop(args)
    endfor
    let s:repls = {}
    let s:buffers = {}
endf


function! workbook#Print(line1, line2, ...) abort "{{{3
    Tlibtrace 'workbook', a:line1, a:line2
    let repl = workbook#GetRepl()
    Tlibtrace 'workbook', tlib#Object#Methods(repl)
    if repl.ignore_input
        let repl.ignore_input = 0
        return
    endif
    let [line1, line2] = workbook#StripResults(a:line1, a:line2, repl)
    Tlibtrace 'workbook', line1, line2
    " TODO allow for in line selection
    let lines = a:0 >= 1 ? a:1 : getline(line1, line2)
    Tlibtrace 'workbook', lines
    let code = join(lines, "\n")
    if len(lines) == 0 && empty(code)
        return
    endif
    let indent = matchstr(code, '^\s\+')
    let placeholder = repl.GetPlaceholder(code)
    Tlibtrace 'workbook', placeholder
    let pos = getpos('.')
    try
        if repl.DoInsertResultsInBuffer(0)
            let pline = indent . repl.GetResultLine('p', placeholder)
            call append(line2, [pline])
        else
            let pline = ''
        endif
        let rid = repl.id
        Tlibtrace 'workbook', rid
        call repl.SetPlaceholder(bufnr('%'), placeholder, pline)
        " async
        if repl.DoTranscribe()
            call repl.Transcribe('c', lines)
        endif
    finally
        call setpos('.', pos)
    endtry
    call repl.Send(code, placeholder)
endf


function! workbook#StripResults(line1, line2, ...) abort "{{{3
    Tlibtrace 'workbook', a:line1, a:line2
    let repl = a:0 >= 1 ? a:1 : workbook#GetRepl()
    let result_rx = repl.GetResultLineRx()
    let line1 = a:line1
    let line2 = a:line2
    let line3 = a:line2 + 1
    let line = getline(line3)
    while line3 <= line('$') && line =~# result_rx
        exec line3 'delete'
        let line = getline(line3)
    endwh
    for lnum in range(line2, line1, -1)
        if getline(lnum) =~# result_rx
            exec lnum 'delete'
            let line2 -= 1
        endif
    endfor
    return sort([line1, line2], {i1, i2 -> i1 == i2 ? 0 : i1 > i2 ? 1 : -1})
endf


function! workbook#Send(code) abort "{{{3
    Tlibtrace 'workbook', a:code
    let repl = workbook#GetRepl()
    let p = repl.GetPlaceholder(a:code)
    call repl.SetPlaceholder(0, p, '')
    call repl.Send(a:code, p)
endf


function! workbook#Eval(code) abort "{{{3
    Tlibtrace 'workbook', a:code
    let repl = workbook#GetRepl()
    " sync
    return repl.Eval(a:code)
endf


function! workbook#OmniComplete(findstart, base) abort "{{{3
    Tlibtrace 'workbook', a:findstart, a:base
    let repl = workbook#GetRepl()
    if !has_key(repl, 'Complete')
        if exists('b:workbook_orig_omnifunc')
            let &l:omnifunc = b:workbook_orig_omnifunc
            unlet! b:workbook_orig_omnifunc
            return empty(&l:omnifunc) ? [] : call(&l:omnifunc, [a:findstart, a:base])
        endif
    else
        if a:findstart
            let line = getline('.')
            let start = col('.') - 1
            let rx = has_key(repl, 'GetKeywordRx') ? repl.GetKeywordRx() : '\k'
            while start > 0 && line[start - 1] =~ rx
                let start -= 1
            endwhile
            return start
        else
            let values = repl.Complete(a:base)
            " if empty(values) && exists('b:workbook_orig_omnifunc') && !empty(b:workbook_orig_omnifunc)
            "     let values = call(b:workbook_orig_omnifunc, [a:findstart, a:base])
            " endif
            if !empty(b:workbook_orig_omnifunc) && exists('*'. b:workbook_orig_omnifunc)
                let values += call(b:workbook_orig_omnifunc, [a:findstart, a:base])
            endif
            return tlib#list#Uniq(values)
        endif
    endif
endf


" When a REPL is stuck, some REPLs support a way to reset the repl's 
" state.
function! workbook#ResetRepl() abort "{{{3
    let repl = workbook#GetRepl()
    if has_key(repl, 'Reset')
        call repl.Reset()
    else
        echom 'Workbook: REPL doesn''t support reset!'
    endif
endf


function! workbook#InteractiveRepl() abort "{{{3
    let repl = workbook#GetRepl()
    if !repl.DoTranscribe()
        let transcribe = repl.DoTranscribe()
        call repl.SetTranscribe(1)
    endif
    try
        let ignore_output = get(repl, 'ignore_output', 0)
        if ignore_output == 0
            let repl.ignore_output = 1
        endif
        call inputsave()
        while 1
            let code = input('> ')
            if empty(code)
                break
            else
                call repl.Transcribe('i', [code], 1)
                call repl.Input(code, 1)
            endif
        endwh
        call inputrestore()
    finally
        if ignore_output == 0
            let repl.ignore_output = 0
        endif
        if exists('transcribe')
            call repl.SetTranscribe(transcribe)
        endif
    endtry
endf


function! workbook#NextCmd() abort "{{{3
    let repl = workbook#GetRepl()
    if !empty(repl.next_cmd)
        let cmd = remove(repl.next_cmd, 0)
        exec cmd
    endif
endf


function! workbook#Quicklist(word) "{{{3
    " TLogVAR a:word
    let repl = workbook#GetRepl()
    if has_key(repl, 'GetQuicklist')
        let quicklist = repl.GetQuicklist()
    else
        let ft = get(repl, 'filetype', &filetype)
        if exists('g:workbook#ft#'. ft .'#quicklist')
            let quicklist = g:workbook#ft#{ft}#quicklist
        else
            let quicklist = []
        endif
    endif
    if !empty(quicklist)
        let filename = expand('%:p')
        if has_key(repl, 'GetFilename')
            let filename = repl.GetFilename(filename)
        endif
        let dict = {
                    \ 'filename': filename,
                    \ 'cword': a:word}
        let ql = map(copy(quicklist), 'tlib#string#Format(v:val, dict)')
        let code = tlib#input#List('s', 'Select function:', ql, g:workbook#handlers)
        if !empty(code)
            call workbook#Send(code)
        endif
    endif
endf


function! workbook#EditItem(world, items) "{{{3
    " TLogVAR a:items
    let item = get(a:items, 0, '')
    call inputsave()
    let item = input('Edit> ', item)
    call inputrestore()
    " TLogVAR item
    if !empty(item)
        let a:world.rv = item
        let a:world.state = 'picked'
        return a:world
    endif
    let a:world.state = 'redisplay'
    return a:world
endf


function! workbook#Complete(ArgLead, CmdLine, CursorPos) abort "{{{3
    let words = tlib#arg#CComplete(s:workbook_args, a:ArgLead)
    return sort(words)
endf


" Return a list of supported filetypes.
function! workbook#GetSupportedFiletypes() abort "{{{3
    let files = globpath(&rtp, 'autoload/workbook/ft/*.vim', 0, 1)
    let files = map(files, {i,f -> matchstr(f, '[\/]\zs[^\/.]\{-}\ze\.vim$')})
    return files
endf


function! workbook#Overview() abort "{{{3
    let repls = items(s:repls)
    let rinfos = map(copy(repls), {i, v -> v[0] .': '. (v[1].IsReady() ? 'ready' : 'dead')})
    let w = tlib#World#New()
    let w.type = 'si'
    let w.pick_last_item = 0
    let w.base = rinfos
    let sel = tlib#input#ListW(w)
    if sel > 0
        let repl = repls[sel - 1]
        let bufnr = repl[1].bufnr
        let wins = win_findbuf(bufnr)
        if empty(wins)
            exec 'sbuffer' bufnr
        else
            call win_gotoid(wins[0])
        endif
    endif
endf

