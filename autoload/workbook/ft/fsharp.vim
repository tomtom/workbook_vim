" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-03-16
" @Revision:    504

if !exists('g:loaded_tlib') || g:loaded_tlib < 122
    runtime plugin/tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 122
        echoerr 'tlib >= 1.22 is required'
        finish
    endif
endif


if !exists('g:workbook#ft#fsharp#cmd')
    let g:workbook#ft#fsharp#cmd = 'fsharpi'   "{{{2
endif
if !executable(g:workbook#ft#fsharp#cmd)
    throw 'Workbook: g:workbook#ft#fsharp#cmd is not executable: '. g:workbook#ft#fsharp#cmd
endif


if !exists('g:workbook#ft#fsharp#args')
    let g:workbook#ft#fsharp#args = '--nologo -g --tailcalls+ --warn:5 --checked --readline-'   "{{{2
endif


if !exists('g:workbook#ft#fsharp#init_script')
    let g:workbook#ft#fsharp#init_script = simplify(expand('<sfile>:p:h') .'/workbook_vim.fs')  "{{{2
endif


if !exists('g:workbook#ft#fsharp#init_code')
    let g:workbook#ft#fsharp#init_code = ''   "{{{2
endif


if !exists('g:workbook#ft#fsharp#quicklist')
    let g:workbook#ft#fsharp#quicklist = []   "{{{2
    if exists('g:workbook#ft#r_quicklist_etc')
        let g:workbook#ft#fsharp#quicklist += g:workbook#ft#fsharp#quicklist_etc
    endif
endif


if !exists('g:workbook#ft#fsharp#wait_after_send_line')
    let g:workbook#ft#fsharp#wait_after_send_line = '100m'   "{{{2
endif


if !exists('g:workbook#ft#fsharp#wait_after_startup')
    let g:workbook#ft#fsharp#wait_after_startup = '300m'   "{{{2
endif


" let s:WrapCode = {p, c -> printf("printfn \"WorkbookBEGIN:%%s\\n\" \"%s\";;\n\n%s;;\n\nprintfn \"WorkbookEND:%%s\\n\" \"%s\";;\n", p, c, p)}
let s:WrapCode = {p, c -> printf("printfn \"WorkbookBEGIN:%s\\n\";\n%s\nprintfn \"WorkbookEND:%s\\n\";;\n", p, c, p)}

let s:prototype = {'debugged': {}
            \ , 'wait_after_startup': g:workbook#ft#fsharp#wait_after_startup
            \ }
            " \ ,'repl_type': 'vim_nl'
            " \ ,'repl_type': 'vim_raw'

function! workbook#ft#fsharp#New(ext) abort "{{{3
    let o = extend(a:ext, s:prototype)
    return o
endf


function! s:prototype.GetFiletypeCmdAndArgs() abort dict "{{{3
    return [g:workbook#ft#fsharp#cmd, g:workbook#ft#fsharp#args]
endf


function! s:prototype.InitFiletype() abort dict "{{{3
    Tlibtrace 'workbook', 'InitFiletype'
    if filereadable(g:workbook#ft#fsharp#init_script)
        call self.Send(printf('#load "%s")', substitute(g:workbook#ft#fsharp#init_script, '\\', '/', 'g')))
    endif
    call self.Send(g:workbook#ft#fsharp#init_code)
endf


function! s:prototype.ExitFiletype(args) abort dict "{{{3
    Tlibtrace 'workbook', 'ExitFiletype', a:args
    call self.Send("#quit;;")
endf


if !empty(g:workbook#ft#fsharp#wait_after_send_line)
    function! s:prototype.ProcessSendLine(Sender) abort dict "{{{3
        Tlibtrace 'workbook', 'ProcessSendLine', a:Sender
        let rv = a:Sender()
        Tlibtrace 'workbook', 'ProcessSendLine', g:workbook#ft#fsharp#wait_after_send_line
        exec 'sleep' g:workbook#ft#fsharp#wait_after_send_line
        Tlibtrace 'workbook', 'ProcessSendLine', rv
        return rv
    endf
endif


function! s:prototype.GetCommentLineRxf() abort dict "{{{3
    return '(\*%s\*)'
endf


function! s:prototype.GetResultLinef() abort dict "{{{3
    return '(*%s *)'
endf


function! s:prototype.WrapCode(placeholder, code) abort dict "{{{3
    Tlibtrace 'workbook', 'WrapCode', a:placeholder, a:code
    let mark = self.GetMark(a:placeholder)
    let wcode = s:WrapCode(mark, a:code)
    return wcode
endf


function! s:prototype.ProcessMessage(msg) abort dict "{{{3
    Tlibtrace 'workbook', 'ProcessMessage', a:msg
    let msg = substitute(a:msg, '\%(\_^\%(>\_s\+\)\+\|\%(>\_s\+\)\_$\+\)\+', "\n", 'g')
    Tlibtrace 'workbook', 'ProcessMessage', msg
    return msg
endf


function! s:prototype.FilterMessageLines(lines) abort dict "{{{3
    Tlibtrace 'workbook', 'FilterMessageLines', a:lines
    " let mi = len(a:lines) - 1
    " return filter(a:lines, {i, v -> i != 0 || i != mi || v !=# 'val it : unit = ()'})
    return filter(a:lines, {i, v -> v !~# '^\%(>\s*\|val it : unit = ()\)$'})
endf

" function! s:prototype.FilterOutputLines(lines) abort dict "{{{3
"     Tlibtrace 'workbook', 'FilterOutputLines', a:lines
"     " let mi = len(a:lines) - 1
"     " return filter(a:lines, {i, v -> i != 0 || i != mi || v !=# 'val it : unit = ()'})
"     return filter(a:lines, {i, v -> v !~# '^(\*=.\{-}\%(val it : unit = ()\|>\s*\)\+\*)$'})
" endf

