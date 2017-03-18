" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-03-18
" @Revision:    561

if !exists('g:loaded_tlib') || g:loaded_tlib < 122
    runtime plugin/tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 122
        echoerr 'tlib >= 1.22 is required'
        finish
    endif
endif


if !exists('g:workbook#ft#python#cmd')
    let g:workbook#ft#python#cmd = 'python'   "{{{2
endif
if !executable(g:workbook#ft#python#cmd)
    throw 'Workbook: g:workbook#ft#python#cmd is not executable: '. g:workbook#ft#python#cmd
endif


if !exists('g:workbook#ft#python#args')
    let g:workbook#ft#python#args = '-i'   "{{{2
endif


if !exists('g:workbook#ft#python#init_script')
    let g:workbook#ft#python#init_script = simplify(expand('<sfile>:p:h') .'/workbook_vim.py')  "{{{2
endif


if !exists('g:workbook#ft#python#init_code')
    let g:workbook#ft#python#init_code = ''   "{{{2
endif


if !exists('g:workbook#ft#python#quicklist')
    let g:workbook#ft#python#quicklist = []   "{{{2
    if exists('g:workbook#ft#r_quicklist_etc')
        let g:workbook#ft#python#quicklist += g:workbook#ft#python#quicklist_etc
    endif
endif


if !exists('g:workbook#ft#python#wait_after_send_line')
    let g:workbook#ft#python#wait_after_send_line = '100m'   "{{{2
endif


if !exists('g:workbook#ft#python#wait_after_startup')
    let g:workbook#ft#python#wait_after_startup = '300m'   "{{{2
endif


let s:prototype = {
            \ 'use_err_cb': 1,
            \ 'wait_after_startup': g:workbook#ft#python#wait_after_startup}


function! workbook#ft#python#New(ext) abort "{{{3
    let o = extend(a:ext, s:prototype)
    return o
endf


function! s:prototype.GetFiletypeCmdAndArgs() abort dict "{{{3
    return [g:workbook#ft#python#cmd, g:workbook#ft#python#args]
endf


function! s:prototype.InitFiletype() abort dict "{{{3
    Tlibtrace 'workbook', 'InitFiletype'
    if filereadable(g:workbook#ft#python#init_script)
        call self.Send(printf('exec(open("%s").read(), globals())', substitute(g:workbook#ft#python#init_script, '\\', '/', 'g')))
    endif
    call self.Send(g:workbook#ft#python#init_code)
endf


function! s:prototype.ExitFiletype(args) abort dict "{{{3
    Tlibtrace 'workbook', 'ExitFiletype', a:args
    call self.Send('quit()')
endf


if !empty(g:workbook#ft#python#wait_after_send_line)
    function! s:prototype.ProcessSendLine(Sender) abort dict "{{{3
        Tlibtrace 'workbook', 'ProcessSendLine', a:Sender
        let rv = a:Sender()
        Tlibtrace 'workbook', 'ProcessSendLine', g:workbook#ft#python#wait_after_send_line
        exec 'sleep' g:workbook#ft#python#wait_after_send_line
        Tlibtrace 'workbook', 'ProcessSendLine', rv
        return rv
    endf
endif


function! s:prototype.GetCommentLineRxf() abort dict "{{{3
    return '# %s'
endf


function! s:prototype.GetResultLinef() abort dict "{{{3
    return '# %s'
endf


function! s:prototype.WrapCode(placeholder, code) abort dict "{{{3
    Tlibtrace 'workbook', 'WrapCode', a:placeholder, a:code
    let mark = self.GetMark(a:placeholder)
    let wcode = printf("print(\"WorkbookBEGIN:%s\")\n%s\nprint(\"WorkbookEND:%s\")\n",
                \ mark, a:code, mark)
    return wcode
endf


" function! s:prototype.FilterMessageLines(lines) abort dict "{{{3
"     Tlibtrace 'workbook', 'FilterMessageLines', a:lines
"     echom "DBG" string(a:lines)
"     return a:lines
" endf


function! s:prototype.FilterErrorMessageLines(parts) abort dict "{{{3
    Tlibtrace 'workbook', 'FilterErrorMessageLines', a:lines
    let lines = filter(a:parts, 'v:val !~# ''^>>>\s*''')
    return lines
endf

