" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-02-26
" @Revision:    81


let s:prototype = {'repl_type': 'vim_eval'}


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

