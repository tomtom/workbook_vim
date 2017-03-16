" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-03-16
" @Revision:    544

if !exists('g:loaded_tlib') || g:loaded_tlib < 122
    runtime plugin/tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 122
        echoerr 'tlib >= 1.22 is required'
        finish
    endif
endif


if !exists('g:workbook#ft#ruby#cmd')
    let g:workbook#ft#ruby#cmd = 'irb'   "{{{2
endif
if !executable(g:workbook#ft#ruby#cmd)
    throw 'Workbook: g:workbook#ft#ruby#cmd is not executable: '. g:workbook#ft#ruby#cmd
endif


if !exists('g:workbook#ft#ruby#args')
    let g:workbook#ft#ruby#args = '-w --noreadline --inf-ruby-mode'   "{{{2
endif


if !exists('g:workbook#ft#ruby#init_script')
    let g:workbook#ft#ruby#init_script = simplify(expand('<sfile>:p:h') .'/workbook_vim.rb')  "{{{2
endif


if !exists('g:workbook#ft#ruby#init_code')
    let g:workbook#ft#ruby#init_code = ''   "{{{2
endif


if !exists('g:workbook#ft#ruby#quicklist')
    let g:workbook#ft#ruby#quicklist = []   "{{{2
    if exists('g:workbook#ft#r_quicklist_etc')
        let g:workbook#ft#ruby#quicklist += g:workbook#ft#ruby#quicklist_etc
    endif
endif


if !exists('g:workbook#ft#ruby#wait_after_send_line')
    let g:workbook#ft#ruby#wait_after_send_line = '100m'   "{{{2
endif


if !exists('g:workbook#ft#ruby#wait_after_startup')
    let g:workbook#ft#ruby#wait_after_startup = '300m'   "{{{2
endif


let s:prototype = {
            \ 'use_err_cb': 1,
            \ 'wait_after_startup': g:workbook#ft#ruby#wait_after_startup}


function! workbook#ft#ruby#New(ext) abort "{{{3
    let o = extend(a:ext, s:prototype)
    return o
endf


function! s:prototype.GetFiletypeCmdAndArgs() abort dict "{{{3
    return [g:workbook#ft#ruby#cmd, g:workbook#ft#ruby#args]
endf


function! s:prototype.InitFiletype() abort dict "{{{3
    Tlibtrace 'workbook', 'InitFiletype'
    if filereadable(g:workbook#ft#ruby#init_script)
        call self.Send(printf('require "%s"', substitute(g:workbook#ft#ruby#init_script, '\\', '/', 'g')))
    endif
    call self.Send(g:workbook#ft#ruby#init_code)
endf


function! s:prototype.ExitFiletype(args) abort dict "{{{3
    Tlibtrace 'workbook', 'ExitFiletype', a:args
    call self.Send('exit')
endf


if !empty(g:workbook#ft#ruby#wait_after_send_line)
    function! s:prototype.ProcessSendLine(Sender) abort dict "{{{3
        Tlibtrace 'workbook', 'ProcessSendLine', a:Sender
        let rv = a:Sender()
        Tlibtrace 'workbook', 'ProcessSendLine', g:workbook#ft#ruby#wait_after_send_line
        exec 'sleep' g:workbook#ft#ruby#wait_after_send_line
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


function! s:prototype.WrapCode(placeholder, code) abort dict "{{{3
    Tlibtrace 'workbook', 'WrapCode', a:placeholder, a:code
    let mark = self.GetMark(a:placeholder)
    let wcode = printf("puts \"WorkbookBEGIN:%s\"\nbegin\n%s\nrescue => e\n$stderr.puts \"#{e.class}: #{e.message}\"\n$stderr.puts e.backtrace.join(\"\\n\\t\")\nend\nputs \"WorkbookEND:%s\"\n",
                \ mark, a:code, mark)
    return wcode
endf


function! s:prototype.FilterMessageLines(lines) abort dict "{{{3
    Tlibtrace 'workbook', 'FilterMessageLines', a:lines
    let lines = filter(a:lines[1 : -2], 'v:val !=# "nil"')
    return lines
endf

