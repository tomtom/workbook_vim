" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-02-05
" @Revision:    68


if !exists('g:workbook#ft#vim#comment_rxf')
    let g:workbook#ft#vim#comment_rxf = '"%s %s'   "{{{2
endif


let s:prototype = {}


function! workbook#ft#vim#New(ext) abort "{{{3
    let o = extend(a:ext, s:prototype)
    return o
endf


function! s:prototype.Start(...) abort dict "{{{3
endf


" async
function! s:prototype.Send(placeholder, code) abort dict "{{{3
    let out = self.Eval(a:code)
    call self.ConsumeOutput('', out, a:placeholder)
    call self.ProcessOutput(a:placeholder)
endf


" sync
function! s:prototype.Eval(code) abort dict "{{{3
    let t = @t
    let @t = a:code
    try
        redir => out
        silent @t
        redir END
        Tlibtrace 'workbook', out
        return out
    finally
        let @t = t
    endtry
endf


function! s:prototype.GetResultLineRxf() abort dict "{{{3
    return g:workbook#ft#vim#comment_rxf
endf


" function! s:prototype.ExitRepl(args) abort dict "{{{3
" endf


" function! s:prototype.GetKeywordRx() abort dict "{{{3
" endf


" function! s:prototype.Complete(text) abort dict "{{{3
" endf


