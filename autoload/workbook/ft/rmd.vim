" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-02-20
" @Revision:    436


let s:prototype = {'transcript_filetype': 'r'}


function! workbook#ft#rmd#New(ext) abort "{{{3
    let p = workbook#ft#r#New(a:ext)
    let o = extend(p, s:prototype)
    return o
endf


function! s:prototype.GetBlockKeys() abort dict "{{{3
    let beg = search('^\s*```{r\>', 'bnW')
    let end = search('^\s*```\s*$', 'bnW')
    if beg > end
        return "V/\\ze\\n```$\<cr>"
    else
        let self.ignore_input = 1
        return self.GetNextKeys()
    endif
endf


function! s:prototype.GetNextKeys() abort dict "{{{3
    return "/\\ze\\n\\s*```{r\<cr>"
endf

