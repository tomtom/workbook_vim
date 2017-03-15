" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-03-15
" @Revision:    492


function! workbook#ft#rmd#SetupBuffer() abort "{{{3
    call workbook#ft#r#SetupBuffer()
endf


function! workbook#ft#rmd#UndoSetup() abort "{{{3
    call workbook#ft#r#UndoSetup()
endf


let s:prototype = {'transcript_filetype': 'r'}


function! workbook#ft#rmd#New(ext) abort "{{{3
    let p = workbook#ft#r#New(a:ext)
    let o = extend(p, s:prototype)
    return o
endf


function! s:prototype.GotoBeginOfBlockExpr(return_lnum) abort dict "{{{3
    let ibeg = match(getline('.'), '`\zs[^`]*\%'. col('.') .'c[^`]*`')
    Tlibtrace 'workbook', 'GotoBeginOfBlockExpr', ibeg
    if ibeg != -1
        " return ibeg '|lvt`'
        return a:return_lnum ? line('.') : "?`\<cr>l"
    endif
    let beg = search('^\s*```{r\>', 'bcnW')
    Tlibtrace 'workbook', 'GotoBeginOfBlockExpr', beg
    if beg > 0
        let pend = search('^\s*```\s*$', 'bcnW')
        Tlibtrace 'workbook', 'GotoBeginOfBlockExpr', pend
        if pend < beg
            let lnum = beg + 1
            Tlibtrace 'workbook', 'GotoBeginOfBlockExpr', lnum
            return a:return_lnum ? lnum : (lnum .'gg')
        endif
    endif
    return a:return_lnum ? 0 : ''
endf


function! s:prototype.GotoEndOfBlockExpr(return_lnum) abort dict "{{{3
    let ibeg = match(getline('.'), '`\zs[^`]*\%'. col('.') .'c[^`]*`')
    Tlibtrace 'workbook', 'GotoEndOfBlockExpr', ibeg
    if ibeg != -1
        " return ibeg '|lvt`'
        return a:return_lnum ? line('.') : "t`/`\\zs\<cr>"
    endif
    let beg = self.GotoBeginOfBlockExpr(1)
    if beg > 0
        let end = search('^\s*```\s*$', 'cnW')
        Tlibtrace 'workbook', 'GotoEndOfBlockExpr', end
        if beg < end
            let nbeg = search('^\s*```{r\>', 'cnW')
            Tlibtrace 'workbook', 'GotoEndOfBlockExpr', nbeg
            if nbeg == 0 || nbeg > end
                " return beg ."ggjV/\\ze\\n```$\<cr>"
                let lnum = end - 1
                Tlibtrace 'workbook', 'GotoEndOfBlockExpr', lnum
                return a:return_lnum ? lnum : (lnum .'gg'. min([end + 1, line('$')]) .'gg')
            endif
        endif
    endif
    let self.ignore_input = 1
    Tlibtrace 'workbook', 'GotoEndOfBlockExpr', self.ignore_input
    return a:return_lnum ? 0 : self.GetNextKeys()
endf


function! s:prototype.GotoNextBlockExpr() abort dict "{{{3
    " return "/\\ze\\n\\s*```{r\<cr>"
    return "/\\%(\\%(^\\|\\s\\)``\\@!\\|^\\s*```{r\\>.*\\n\\)\\zs\<cr>"
endf

