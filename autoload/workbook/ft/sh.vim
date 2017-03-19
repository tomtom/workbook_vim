" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-03-19
" @Revision:    77


if !exists('g:loaded_tlib') || g:loaded_tlib < 122
    runtime plugin/tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 122
        echoerr 'tlib >= 1.22 is required'
        finish
    endif
endif


" " Simulate interactive use:
" script -f --return -c bash /dev/null
" :nodoc:

if !exists('g:workbook#ft#sh#cmd')
    let g:workbook#ft#sh#cmd = 'bash'   "{{{2
endif
if !executable(g:workbook#ft#sh#cmd)
    throw 'Workbook: g:workbook#ft#sh#cmd is not executable: '. g:workbook#ft#sh#cmd
endif


if !exists('g:workbook#ft#sh#args')
    let g:workbook#ft#sh#args = ''   "{{{2
endif


if !exists('g:workbook#ft#sh#init_script')
    let g:workbook#ft#sh#init_script = simplify(expand('<sfile>:p:h') .'/workbook_vim.sh')  "{{{2
endif


if !exists('g:workbook#ft#sh#init_code')
    let g:workbook#ft#sh#init_code = ''   "{{{2
endif


if !exists('g:workbook#ft#sh#quicklist')
    let g:workbook#ft#sh#quicklist = []   "{{{2
    if exists('g:workbook#ft#r_quicklist_etc')
        let g:workbook#ft#sh#quicklist += g:workbook#ft#r_quicklist_etc
    endif
endif


if !exists('g:workbook#ft#sh#wait_after_send_line')
    let g:workbook#ft#sh#wait_after_send_line = '100m'   "{{{2
endif


" " Omni completion (see 'omnifunc') is enabled.
" function! workbook#ft#sh#SetupBuffer() abort "{{{3
"     call workbook#SetOmnifunc()
" endf

let s:prototype = {}

function! workbook#ft#sh#New(ext) abort "{{{3
    let o = extend(a:ext, s:prototype)
    return o
endf


function! s:prototype.GetFiletypeCmdAndArgs() abort dict "{{{3
    return [g:workbook#ft#sh#cmd, g:workbook#ft#sh#args]
endf


function! s:prototype.ExitFiletype(args) abort dict "{{{3
    call self.Send('exit')
endf


function! s:prototype.GetCommentLineRxf() abort dict "{{{3
    return '#%s'
endf


function! s:prototype.GetResultLinef() abort dict "{{{3
    return '#%s'
endf


function! s:prototype.WrapCode(placeholder, code) abort dict "{{{3
    " let wcode = printf(s:wrap_code_f, a:code, self.GetMark(a:placeholder))
    let p = self.GetMark(a:placeholder)
    let wcode = printf('echo ''WorkbookBEGIN:%s''\n%s\necho ''WorkbookEND:%s''', p, a:code, p)
    return wcode
endf


" " Works only in interactive mode
" function! s:prototype.Complete(text) abort dict "{{{3
"     let cs = self.Eval(a:text ."\<tab>\<c-c>")
"     return split(cs, "[\t\n\j]")
" endf

