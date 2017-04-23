" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-04-22
" @Revision:    593

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
    " let g:workbook#ft#r#args = '--slave --no-save'   "{{{2
    let g:workbook#ft#r#args = '--silent '. (g:workbook#ft#r#cmd =~? '\<rterm\%(\.exe\)\>' ? '--ess' : '--no-readline --interactive')   "{{{2
endif


if !exists('g:workbook#ft#r#init_script')
    let g:workbook#ft#r#init_script = simplify(expand('<sfile>:p:h') .'/workbook_vim.R')  "{{{2
endif


if !exists('g:workbook#ft#r#init_code')
    " Evaluate this code on startup.
    let g:workbook#ft#r#init_code = 'workbookCtags()'   "{{{2
endif


if !exists('g:workbook#ft#r#init_files')
    " Source these files on startup.
    let g:workbook#ft#r#init_files = []   "{{{2
endif


if !exists('g:workbook#ft#r#save')
    " If true, save R sessions by default.
    let g:workbook#ft#r#save = 1   "{{{2
endif


if !exists('g:workbook#ft#r#restore')
    " If true, restore R sessions by default.
    let g:workbook#ft#r#restore = 1   "{{{2
endif


if !exists('g:workbook#ft#r#quicklist')
    let g:workbook#ft#r#quicklist = ['??"%{cword}"', 'str(%{cword})', 'summary(%{cword})', 'head(%{cword})', 'edit(%{cword})', 'fix(%{cword})', 'debugger()', 'traceback()', 'install.packages("%{cword}")', 'update.packages()', 'example("%{cword}")', 'graphics.off()']   "{{{2
    if exists('g:workbook#ft#r_quicklist_etc')
        let g:workbook#ft#r#quicklist += g:workbook#ft#r_quicklist_etc
    endif
endif


if !exists('g:workbook#ft#r#highlight_debug')
    " Highlight group for debugged functions.
    let g:workbook#ft#r#highlight_debug = 'SpellRare'   "{{{2
endif


if !exists('g:workbook#ft#r#mode')
    " Defined how to talk to R. Possible values are:
    " '' ......... run via |job_start()|
    " 'rserve' ... Use Rserve (doesn't work properly yet)
    let g:workbook#ft#r#mode = ''   "{{{2
endif


if !exists('g:workbook#ft#r#wait_after_send_line')
    let g:workbook#ft#r#wait_after_send_line = '100m'   "{{{2
endif


if !exists('g:workbook#ft#r#wait_after_startup')
    let g:workbook#ft#r#wait_after_startup = '300m'   "{{{2
endif


if !exists('g:workbook#ft#r#handle_qfl_expression_f')
    " An ex command as format string. Defined how the results from 
    " codetools:checkUsage are displayed.
    let g:workbook#ft#r#handle_qfl_expression_f = 'cgetexpr %s | cwindow'   "{{{2
endif


if !exists('g:workbook#ft#r#use_formatR')
    " If true, format code with formatR.
    let g:workbook#ft#r#use_formatR = 1   "{{{2
endif


if !exists('g:workbook#ft#r#formatR_options')
    " Additional arguments to formatR::tidy_source().
    let g:workbook#ft#r#formatR_options = ''   "{{{2
endif


" In R workbooks the following additional maps are set (<WML> is 
" |g:workbook#map_leader|):
"
" <WML>cd ... Set the working directory in R to VIM's working directory
" <WML>d  ... Debug the word under the cursor
" <WML>i  ... Inspect the word under the cursor
" <WML>k  ... Get help on the word under the cursor
" <WML>s  ... Source the current file
"
" The following maps require codetools to be installed in R:
" <WML>cu ... Run checkUsage on the global environment
"
" The following maps require formatR to be installed in R:
" <WML>f{motion} ... Format some code
" <WML>f  ... In visual mode: format some code
" <WML>ff ... Format the current paragraph
"
" Omni completion (see 'omnifunc') is enabled.
function! workbook#ft#r#SetupBuffer() abort "{{{3
    Tlibtrace 'workbook', 'SetupBuffer'
    exec 'nnoremap <buffer>' g:workbook#map_leader .'cd :call workbook#ft#r#Cd()<cr>'
    exec 'nnoremap <buffer>' g:workbook#map_leader .'cu :call workbook#ft#r#CheckUsage()<cr>'
    exec 'nnoremap <buffer>' g:workbook#map_leader .'d :call workbook#ft#r#Debug(expand("<cword>"))<cr>'
    exec 'xnoremap <buffer>' g:workbook#map_leader .'d ""y:call workbook#ft#r#Debug(@")<cr>'
    if g:workbook#ft#r#use_formatR
        " let b:formatexpr_orig = &l:formatexpr
        " setlocal formatexpr=workbook#ft#r#FormatR()
        exec 'nmap <buffer>' g:workbook#map_leader .'f :set opfunc=workbook#ft#r#Format<CR>g@'
        exec 'nmap <buffer>' g:workbook#map_leader .'f' g:workbook#map_leader .'ip'
        exec 'xmap <buffer>' g:workbook#map_leader .'f :<C-U>call workbook#ft#r#Format(visualmode(), 1)<CR>'
    endif
    exec 'nnoremap <buffer>' g:workbook#map_leader .'i :echo "<c-r><c-w>" workbook#Send(''str(<c-r><c-w>)'')<cr>'
    exec 'nnoremap <buffer>' g:workbook#map_leader .'k :call workbook#Send(''workbookKeyword(<c-r><c-w>, "<c-r><c-w>")'')<cr>'
    if &l:keywordprg =~# '^\%(man\>\|:help$\|$\)'
        nnoremap <buffer> K :call workbook#Send('?"<c-r><c-w>"')<cr>
    endif
    if &buftype !=# 'nofile'
        let filename = substitute(expand('%:p'), '\\', '/', 'g')
        exec 'nnoremap <buffer>' g:workbook#map_leader .'s :call workbook#Send("source('. string(filename) .')")<cr>'
    endif
    call workbook#SetOmnifunc()
    syntax match Comment '^\s*#.*$'
endf


function! workbook#ft#r#UndoSetup() abort "{{{3
    Tlibtrace 'workbook', 'UndoSetup'
    exec 'nunmap <buffer>' g:workbook#map_leader .'cd'
    exec 'nunmap <buffer>' g:workbook#map_leader .'cu'
    exec 'nunmap <buffer>' g:workbook#map_leader .'d'
    exec 'xunmap <buffer>' g:workbook#map_leader .'d'
    exec 'nunmap <buffer>' g:workbook#map_leader .'f'
    exec 'nunmap <buffer>' g:workbook#map_leader .'ff'
    exec 'xunmap <buffer>' g:workbook#map_leader .'f'
    exec 'nunmap <buffer>' g:workbook#map_leader .'i'
    exec 'nunmap <buffer>' g:workbook#map_leader .'k'
    exec 'nunmap <buffer>' g:workbook#map_leader .'s'
    if &l:keywordprg =~# '^\%(man\>\|help$\|$\)'
        nunmap <buffer> K
    endif
    if exists('b:formatexpr_orig')
        let &l:formatexpr = b:formatexpr_orig
    endif
endf


" let s:WrapCode = {p, c -> printf("cat(\"\\nWorkbookBEGIN:%s\\n\")\n%s\ncat(\"\\nWorkbookEND:%s\\n\"); flush.console()\n", p, c, p)}
function! s:WrapCode(p, c) abort "{{{3
    return printf("cat(\"\\nWorkbookBEGIN:%s\\n\")\n%s\ncat(\"\\nWorkbookEND:%s\\n\"); flush.console()\n", a:p, a:c, a:p)
endf


let s:prototype = {'debugged': {}
            \ , 'result_syntax': 'rComment'
            \ , 'transcript_filetype': ''
            \ , 'wait_after_startup': g:workbook#ft#r#wait_after_startup
            \ }
            " \ ,'repl_type': 'vim_nl'
            " \ ,'repl_type': 'vim_raw'

function! workbook#ft#r#New(ext) abort "{{{3
    let o = extend(a:ext, s:prototype)
    return o
endf


function! s:prototype.GetFiletypeCmdAndArgs() abort dict "{{{3
    let args = g:workbook#ft#r#args
    if get(self.args, 'save', g:workbook#ft#r#save)
        let args .= ' --save'
    else
        let args .= ' --no-save'
    endif
    if get(self.args, 'restore', g:workbook#ft#r#restore)
        let args .= ' --restore'
    else
        let args .= ' --no-restore'
    endif
    return [g:workbook#ft#r#cmd, args]
endf


function! s:prototype.InitFiletype() abort dict "{{{3
    Tlibtrace 'workbook', 'InitFiletype'
    if filereadable(g:workbook#ft#r#init_script)
        call self.Send(printf('source("%s")', substitute(g:workbook#ft#r#init_script, '\\', '/', 'g')))
    endif
    if !empty(g:workbook#ft#r#init_code)
        call self.Send(g:workbook#ft#r#init_code)
    endif
    for filename in g:workbook#ft#r#init_files
        if filereadable(filename)
            call self.Send(printf('source("%s")', substitute(filename, '\\', '/', 'g')))
        endif
    endfor
    " call workbook#ft#r#Cd()
    call self.Send('flush.console()')
    " call self.Input("\n\n", 0)
endf


function! s:prototype.ExitFiletype(args) abort dict "{{{3
    Tlibtrace 'workbook', 'ExitFiletype', a:args
    let qargs = get(a:args, 'save', 0) || get(self, 'save', 0) ? 'save = "yes"' : ''
    let cmd = printf('q(%s)', qargs)
    Tlibtrace 'workbook', 'ExitFiletype', cmd
    call self.Send(cmd)
endf


" function! s:prototype.PreprocessNlMessage(msg) abort dict "{{{3
"     let parts = split(a:msg, "\<c-h>\\+\<c-m>\\?", 1)
"     return parts[-1]
" endf


" function! s:prototype.PreprocessRawMessage(msg) abort dict "{{{3
"     let parts = split(a:msg, '\n', 1)
"     let parts = map(parts, {i,p -> self.PreprocessNlMessage(p)})
"     return join(parts, "\n")
" endf


function! s:prototype.ProcessMessage(msg) abort dict "{{{3
    Tlibtrace 'workbook', 'ProcessMessage', a:msg
    let msg = substitute(a:msg, '^\%([>+]\_s\+\)\+', '', 'g')
    Tlibtrace 'workbook', 'ProcessMessage', msg
    return msg
endf


function! s:prototype.ProcessLine(line) abort dict "{{{3
    Tlibtrace 'workbook', 'ProcessLine', a:line
    "" Doesn't work because it will be called recursively
    if !empty(a:line)
        " if has_key(self, 'expect_frames_list')
        "     if a:line =~# '^\s*\d\+:'
        "         call add(self.expect_frames_list, a:line)
        "     else
        "         " for line in self.expect_frames_list
        "         "     call self.Echohl(line)
        "         " endfor
        "         echo join(self.expect_frames_list, "\n")
        "         unlet self.expect_frames_list
        "     endif
        " else
        if a:line =~# '^Browse\[\d\+\]>'
            call self.Echohl('Workbook/r: '. a:line)
        elseif a:line =~# '^Enter a frame number, or 0 to exit\>'
            call self.Echohl('Workbook/r: '. a:line)
            " let self.expect_frames_list = [a:line]
            "     " call add(self.next_cmd, 'Worbookrepl')
            "     if !has_key(self, 'browser_mode')
            "         call timer_start(500, function('workbook#ft#r#BrowserHandler'))
            "     endif
        endif
        return substitute(a:line, '^\%([>+] \)\+', '', 'g')
    else
        return a:line
    endif
endf


if !empty(g:workbook#ft#r#wait_after_send_line)
    function! s:prototype.ProcessSendLine(Sender) abort dict "{{{3
        Tlibtrace 'workbook', 'ProcessSendLine', a:Sender
        let rv = a:Sender()
        Tlibtrace 'workbook', 'ProcessSendLine', g:workbook#ft#r#wait_after_send_line
        exec 'sleep' g:workbook#ft#r#wait_after_send_line
        Tlibtrace 'workbook', 'ProcessSendLine', rv
        return rv
    endf
endif


function! s:prototype.GetCommentLineRxf() abort dict "{{{3
    return '#%s'
endf


function! s:prototype.GetResultLinef() abort dict "{{{3
    return '#%s'
endf


" function! s:prototype.GetKeywordRx() abort dict "{{{3
" endf


function! s:prototype.Complete(text) abort dict "{{{3
    let cmd = printf('workbookComplete(%s)', string(a:text))
    let cs = self.Eval(cmd)
    return split(cs, "\t")
endf


function! s:prototype.WrapCode(placeholder, code) abort dict "{{{3
    Tlibtrace 'workbook', 'WrapCode', a:placeholder, a:code
    if g:workbook#ft#r#mode ==# 'rserve'
        let code = printf('workbookRserveEval(with(withVisible({%s}), if (visible) {print(value); value}))', a:code)
    else
        let code = a:code
    endif
    let mark = self.GetMark(a:placeholder)
    let wcode = s:WrapCode(mark, code)
    return wcode
endf


function! s:prototype.Reset() abort dict "{{{3
    " call self.Input(")]}\<cr>")
    call self.Input("\<c-c>", 1)
endf


" function! s:prototype.FilterOutputLines(lines) abort dict "{{{3
"     " let rx = printf('\V'. escape(s:wrap_code_f, '\'), '\.\{-}', '---- \S\+ ----')
"     " Tlibtrace 'workbook', 'FilterOutputLines', a:lines
"     " Tlibtrace 'workbook', 'FilterOutputLines', rx
"     " return filter(a:lines, {i,v -> v !~# rx})
" endf


function! s:prototype.Debug(fn) abort dict "{{{3
    " TLogVAR fn
    if !empty(a:fn) && !get(self.debugged, a:fn, 0)
        let r = printf('{debug(%s); "ok"}', a:fn)
        let rv = self.Eval(r)
        " TLogVAR rv
        if rv ==# 'ok'
            let self.debugged[a:fn] = 1
            call self.HighlightDebug()
        else
            call self.Echohl('Workbook/r: Cannot debug '. a:fn, 'ErrorMsg')
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
            echom 'Workbook/r: Undebug:' a:fn
        else
            echom 'Workbook/r: Not a debugged function?' fn
        endif
        let r = printf('undebug(%s)', fn)
        call self.Send(r)
        call self.HighlightDebug()
    endif
endf


function! s:prototype.HighlightDebug() abort dict "{{{3
    let bufnr = bufnr('%')
    try
        for bnr in workbook#GetReplBufnrs(self.id)
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
        endfor
    finally
        exec 'hide buffer' bufnr
    endtry
endf


function! s:prototype.GetFilename(filename) abort dict "{{{3
    return workbook#ft#r#GetFilename(a:filename)
endf


function! workbook#ft#r#GetFilename(filename) abort "{{{3
    return substitute(a:filename, '\\', '/', 'g')
endf


function! workbook#ft#r#Cd() abort "{{{3
    let wd = workbook#ft#r#GetFilename(getcwd())
    exec 'Workbooksend setwd('. string(wd) .')'
endf


" Toggle the debug status of a function.
function! workbook#ft#r#Debug(fn) abort "{{{3
    let repl = workbook#GetRepl()
    call repl.Debug(a:fn)
endf


" Undebug a debugged function.
function! workbook#ft#r#Undebug(fn) abort "{{{3
    let repl = workbook#GetRepl()
    call repl.Undebug(a:fn)
endf


function! workbook#ft#r#BrowserHandler(timer) abort "{{{3
    call workbook#InteractiveRepl()
endf


function! workbook#ft#r#CheckUsage() abort "{{{3
    let repl = workbook#GetRepl()
    let checks = repl.Eval('codetools::checkUsageEnv(.GlobalEnv)')
    Tlibtrace 'workbook', checks
    let efm = &errorformat
    let &errorformat = '%m (%f:%l-%*[0-9]),%m (%f:%l)'
    try
        exec printf(g:workbook#ft#r#handle_qfl_expression_f, 'checks')
    finally
        let &errorformat = efm
    endtry
endf


function! workbook#ft#r#Format(type, ...) abort "{{{3
    let sel_save = &selection
    let &selection = 'inclusive'
    let reg_save = @@
    try
        if a:0  " Invoked from Visual mode, use gv command.
            let lbeg = line("'<")
            let lend = line("'>")
        else
            let lbeg = line("'[")
            let lend = line("']")
        endif
        let cnt = lend - lbeg
        call workbook#ft#r#FormatR(lbeg, cnt + 1)
    finally
        let &selection = sel_save
        let @@ = reg_save
    endtry
endf


function! workbook#ft#r#FormatR(lnum, count) abort "{{{3
    let repl = workbook#GetRepl()
    let lend = a:lnum + a:count - 1
    let lines = getline(a:lnum, lend)
    let lines = map(lines, '''"''. escape(v:val, ''"\'') .''"''')
    let code = join(lines, ', ')
    let options = empty(g:workbook#ft#r#formatR_options) ? '' : (', '. g:workbook#ft#r#formatR_options)
    let cmd = printf('suppressWarnings(formatR::tidy_source(text = c(%s)%s))', code, options)
    let formatted = repl.Eval(cmd)
    if a:count > 1
        exec a:lnum .','. lend 'delete'
    else
        exec a:lnum 'delete'
    endif
    call append(a:lnum - 1, split(formatted, '\n'))
    return 0
endf

