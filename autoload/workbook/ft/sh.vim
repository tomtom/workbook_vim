" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-02-10
" @Revision:    34


if !exists('g:loaded_tlib') || g:loaded_tlib < 122
    runtime plugin/tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 122
        echoerr 'tlib >= 1.22 is required'
        finish
    endif
endif


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


if !exists('g:workbook#ft#sh#comment_rxf')
    let g:workbook#ft#sh#comment_rxf = '#%s %s'   "{{{2
endif


if !exists('g:workbook#ft#sh#quicklist')
    let g:workbook#ft#sh#quicklist = ['??"%s"', 'str(%s)', 'summary(%s)', 'head(%s)', 'edit(%s)', 'fix(%s)', 'debugger()', 'traceback()', 'install.packages("%s")', 'update.packages()', 'example("%s")', 'graphics.off()']   "{{{2
    if exists('g:workbook#ft#r_quicklist_etc')
        let g:workbook#ft#sh#quicklist += g:workbook#ft#r_quicklist_etc
    endif
endif


if !exists('g:workbook#ft#sh#wait_after_send_line')
    let g:workbook#ft#sh#wait_after_send_line = '100m'   "{{{2
endif


let s:wrap_code_f = "%s\necho '%s'"   "{{{2


let s:prototype = {
            \ }

function! workbook#ft#sh#New(ext) abort "{{{3
    let o = extend(a:ext, s:prototype)
    let o.cmd = o.GetReplCmd()
    return o
endf


function! s:prototype.GetReplCmd() abort dict "{{{3
    let args = join([g:workbook#ft#sh#args] + get(self.args, '__rest__', []))
    let cmd = empty(args) ? g:workbook#ft#sh#cmd : printf('%s %s', g:workbook#ft#sh#cmd, args)
    let cmd = substitute(cmd, '\\', '/', 'g')
    return cmd
endf


" function! s:prototype.InitFiletype() abort dict "{{{3
" endf


function! s:prototype.ExitFiletype(args) abort dict "{{{3
    call self.Send('exit')
endf


" function! s:prototype.InitBufferFiletype() abort dict "{{{3
" endf


" function! s:prototype.UndoFiletype() abort dict "{{{3
" endf


function! s:prototype.GetEndMark(...) abort dict "{{{3
    let p = a:0 >= 1 ? a:1 : self.GetCurrentPlaceholder()
    return printf('---- %s ----', p)
endf


function! s:prototype.GetPlaceholderFromEndMark(msg) abort dict "{{{3
    return matchstr(a:msg, '^---- \zs\S\+\ze ----$')
endf


function! s:prototype.GetResultLineRxf() abort dict "{{{3
    return g:workbook#ft#sh#comment_rxf
endf


" function! s:prototype.Complete(text) abort dict "{{{3
"     let cmd = printf("%s\<c-t>", string(a:text))
"     let cs = self.Input(cmd, 0)
"     let css = map(split(cs, '\n'), {i,l -> split(tlib#string#Strip(l), "\s+")})
"     echom "DBG" string(css)
"     return tlib#list#Flatten(css)
" endf


function! s:prototype.WrapCode(placeholder, code) abort dict "{{{3
    let wcode = printf(s:wrap_code_f, a:code, self.GetEndMark(a:placeholder))
    return wcode
endf


" function! workbook#ft#sh#Cd() abort "{{{3
"     let wd = substitute(getcwd(), '\\', '/', 'g')
"     exec 'Workbooksend setwd('. string(wd) .')'
" endf


