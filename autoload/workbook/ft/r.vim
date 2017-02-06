" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-02-06
" @Revision:    192

if !exists('g:loaded_tlib') || g:loaded_tlib < 122
    runtime plugin/tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 122
        echoerr 'tlib >= 1.22 is required'
        finish
    endif
endif


if !exists('g:workbook#ft#r#cmd')
    let g:workbook#ft#r#cmd = executable('Rterm') ? 'Rterm' : 'R'   "{{{2
endif
if !executable(g:workbook#ft#r#cmd)
    throw 'Workbook: g:workbook#ft#r#cmd is not executable: '. g:workbook#ft#r#cmd
endif


if !exists('g:workbook#ft#r#args')
    let g:workbook#ft#r#args = '--slave --no-save'   "{{{2
    " let g:workbook#ft#r#args = '--no-save'   "{{{2
endif


if !exists('g:workbook#ft#r#init_script')
    let g:workbook#ft#r#init_script = simplify(expand('<sfile>:p:h') .'/workbook_vim.R')  "{{{2
endif


if !exists('g:workbook#ft#r#init_code')
    let g:workbook#ft#r#init_code = 'invisible({options(width = 10000); NULL})'   "{{{2
endif


if !exists('g:workbook#ft#r#comment_rxf')
    let g:workbook#ft#r#comment_rxf = '#%s %s'   "{{{2
endif


if !exists('g:workbook#ft#r#quicklist')
    let g:workbook#ft#r#quicklist = ['??"%s"', 'str(%s)', 'summary(%s)', 'head(%s)', 'edit(%s)', 'fix(%s)', 'debugger()', 'traceback()', 'install.packages("%s")', 'update.packages()', 'example("%s")', 'graphics.off()']   "{{{2
    if exists('g:workbook#ft#r_quicklist_etc')
        let g:workbook#ft#r#quicklist += g:workbook#ft#r_quicklist_etc
    endif
endif


if !exists('g:workbook#ft#r#handlers')
    let g:workbook#ft#r#handlers = [{'key': 5, 'agent': 'workbook#ft#r#EditItem', 'key_name': '<c-e>', 'help': 'Edit item'}]   "{{{2
endif


if !exists('g:workbook#ft#r#highlight_debug')
    " Highlight group for debugged functions.
    let g:workbook#ft#r#highlight_debug = 'SpellRare'   "{{{2
endif


if !exists('g:workbook#ft#r#wrap_code_f')
    let g:workbook#ft#r#wrap_code_f = 'tryCatch(with(withVisible({%s}), if (visible) print(value)), finally = cat("\n%s\n"))'   "{{{2
endif


let s:prototype = {'debugged': {}}


function! workbook#ft#r#New(ext) abort "{{{3
    let o = extend(a:ext, s:prototype)
    return o
endf


function! s:prototype.InitFiletype() abort dict "{{{3
    if filereadable(g:workbook#ft#r#init_script)
        call self.Eval(printf('source("%s")', substitute(g:workbook#ft#r#init_script, '\\', '/', 'g')))
    endif
    let p = self.GetPlaceholder('startup message')
    call self.SetPlaceholder(0, p, '')
    call self.Send(p, g:workbook#ft#r#init_code)
    " call workbook#ft#r#Cd()
endf


function! s:prototype.ExitFiletype(args) abort dict "{{{3
    let qargs = get(a:args, 'save', 0) || get(self, 'save', 0) ? 'save = "yes"' : ''
    let cmd = printf('q(%s)', qargs)
    call self.Eval(cmd)
endf


function! s:prototype.InitBufferFiletype() abort dict "{{{3
    let filename = substitute(expand('%:p'), '\\', '/', 'g')
    " let wd = substitute(expand('%:p:h'), '\\', '/', 'g')
    let wd = substitute(getcwd(), '\\', '/', 'g')
    exec 'nnoremap <buffer>' g:workbook#map_leader .'cd :call workbook#ft#r#Cd()<cr>'
    exec 'nnoremap <buffer>' g:workbook#map_leader .'s :call workbook#Send(''source('. string(filename) .')'')<cr>'
    nnoremap <buffer> K :call workbook#Send('workbookKeyword(<c-r><c-w>, "<c-r><c-w>")')<cr>
    exec 'nnoremap <buffer>' g:workbook#map_leader .'k :call workbook#Send(''workbookKeyword(<c-r><c-w>, "<c-r><c-w>")'')<cr>'
    exec 'nnoremap <buffer>' g:workbook#map_leader .'f :echo "<c-r><c-w>" workbook#Eval(''args("<c-r><c-w>")'')<cr>'
    " exec 'nnoremap <buffer> '. g:workbook#map_leader .'r :call workbook#ft#r#Quicklist(expand("<cword>"))<cr>'
    exec 'nnoremap <buffer> '. g:workbook#map_leader .'q :call workbook#ft#r#Quicklist(expand("<cword>"))<cr>'
    exec 'vnoremap <buffer> '. g:workbook#map_leader .'q :call workbook#ft#r#Quicklist(join(tlib#selection#GetSelection("v"), " "))<cr>'
    exec 'nnoremap <buffer> '. g:workbook#map_leader .'d :call workbook#ft#r#Debug(expand("<cword>"))<cr>'
    exec 'vnoremap <buffer> '. g:workbook#map_leader .'d ""p:call workbook#ft#r#Debug(@")<cr>'
endf


function! s:prototype.GetEndMark(...) abort dict "{{{3
    let p = a:0 >= 1 ? a:1 : self.GetCurrentPlaceholder()
    return printf('---- %s ----', p)
endf


function! s:prototype.GetPlaceholderFromEndMark(msg) abort dict "{{{3
    return matchstr(a:msg, '^---- \zs\S\+\ze ----$')
endf


function! s:prototype.GetReplCmd() abort dict "{{{3
    return printf('%s %s', g:workbook#ft#r#cmd, g:workbook#ft#r#args)
endf


" function! s:prototype.ProcessLine(line) abort dict "{{{3
"     " if a:line =~# '^Browse\[\d\+\]>'
"     "     " call add(self.next_cmd, 'Worbookrepl')
"     "     call timer_start(500, function('workbook#ft#r#BrowserHandler()'))
"     " endif
"     return a:line
"     " return substitute(a:line, '^\%([>+] \)\+', '', 'g')
" endf


function! s:prototype.GetResultLineRxf() abort dict "{{{3
    return g:workbook#ft#r#comment_rxf
endf


" function! s:prototype.GetKeywordRx() abort dict "{{{3
" endf


function! s:prototype.Complete(text) abort dict "{{{3
    let cmd = printf('workbookComplete(%s)', string(a:text))
    let cs = self.Eval(cmd)
    return split(cs, "\t")
endf


" function! s:prototype.PrepareEvaluation(code) abort dict "{{{3
"     " call add(self.ignore_lines, a:code)
"     call add(self.ignore_lines, 'No traceback available')
"     call add(self.ignore_lines, "Error: unexpected input in \"\<c-c>\"")
"     call self.SendToChannel(function('ch_sendraw'), "\<c-c>\n", 1)
" endf


function! s:prototype.WrapCode(placeholder, code) abort dict "{{{3
    return printf(g:workbook#ft#r#wrap_code_f, a:code, self.GetEndMark(a:placeholder))
endf


function! s:prototype.FilterLines(lines) abort dict "{{{3
    let rx = printf('\V'. escape(g:workbook#ft#r#wrap_code_f, '\'), '\.\{-}', '---- \S\+ ----')
    return filter(a:lines, {i,v -> v !~# rx})
endf


function! s:prototype.Debug(fn) abort dict "{{{3
    " TLogVAR fn
    if !empty(a:fn) && !get(self.debugged, a:fn, 0)
        let r = printf('{debug(%s); "ok"}', a:fn)
        let rv = self.Eval(r)
        " TLogVAR rv
        if rv == "ok"
            let self.debugged[a:fn] = 1
            call self.HighlightDebug()
        else
            echohl Error
            echom "workbook#ft#r: Cannot debug ". a:fn
            echohl NONE
        endif
    else
        call workbook#ft#r#Undebug(a:fn)
    endif
endf


function! s:prototype.Undebug(fn) abort dict "{{{3
    let fn = a:fn
    if empty(fn)
        let fn = tlib#input#List('s', 'Select function:', sort(keys(self.debugged)))
    endif
    if !empty(fn)
        if has_key(self.debugged, fn)
            let self.debugged[fn] = 0
            echom "workbook: Undebug:" a:fn
        else
            echom "workbook: Not a debugged function?" fn
        endif
        let r = printf('undebug(%s)', fn)
        call self.Send(r)
        call self.HighlightDebug()
    endif
endf


function! s:prototype.HighlightDebug() abort dict "{{{3
    let bufnr = bufnr('%')
    try
        for [bnr, rid] in items(s:buffers)
            if rid == self.id
                exec 'hide buffer' bnr
                if b:workbook_r_hl_init
                    syntax clear WorkbookRDebug
                else
                    exec 'hi def link WorkbookRDebug' g:workbook#ft#r#highlight_debug
                    let b:workbook_r_hl_init = 1
                endif
                if !empty(self.debugged)
                    let debugged = map(copy(self.debugged), 'escape(v:val, ''\'')')
                    exec 'syntax match WorkbookRDebug /\V\<\('. join(debugged, '\|') .'\)\>/'
                endif
            endif
        endfor
    finally
        exec 'hide buffer' bufnr
    endtry
endf


function! workbook#ft#r#Cd() abort "{{{3
    let wd = substitute(getcwd(), '\\', '/', 'g')
    exec 'Workbooksend setwd('. string(wd) .')'
endf


function! workbook#ft#r#Quicklist(word) "{{{3
    " TLogVAR a:word
    let ql = map(copy(g:workbook#ft#r#quicklist), 'tlib#string#Printf1(v:val, a:word)')
    let r = tlib#input#List('s', 'Select function:', ql, g:workbook#ft#r#handlers)
    if !empty(r)
        call workbook#Send(r)
    endif
endf


function! workbook#ft#r#EditItem(world, items) "{{{3
    " TLogVAR a:items
    let item = get(a:items, 0, '')
    call inputsave()
    let item = input('R: ', item)
    call inputrestore()
    " TLogVAR item
    if item != ''
        let a:world.rv = item
        let a:world.state = 'picked'
        return a:world
    endif
    let a:world.state = 'redisplay'
    return a:world
endf


" Toggle the debug status of a function.
function! workbook#ft#r#Debug(fn) "{{{3
    let repl = workbook#GetRepl()
    call repl.Debug(a:fn)
endf


" Undebug a debugged function.
function! workbook#ft#r#Undebug(fn) "{{{3
    let repl = workbook#GetRepl()
    call repl.Undebug(a:fn)
endf


function! workbook#ft#r#BrowserHandler(timer) abort "{{{3
    call workbook#InteractiveRepl()
endf

