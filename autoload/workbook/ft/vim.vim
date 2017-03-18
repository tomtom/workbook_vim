" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-03-18
" @Revision:    83


let s:prototype = {'repl_type': 'vim_eval'}


" NOTE: The scope of variables should be made explicit, where `l:` means 
" local to the currently evaluated code.
function! workbook#ft#vim#New(ext) abort "{{{3
    let o = extend(a:ext, s:prototype)
    return o
endf


function! s:prototype.GetCommentLineRxf() abort dict "{{{3
    return '"%s'
endf


function! s:prototype.GetResultLinef() abort dict "{{{3
    return '"%s'
endf

