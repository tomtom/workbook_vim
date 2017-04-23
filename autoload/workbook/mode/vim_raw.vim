" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-04-22
" @Revision:    85



let s:prototype = {}


function! workbook#mode#vim_raw#New(ext) abort "{{{3
    let o = extend(a:ext, s:prototype)
    return o
endf


function! s:prototype.Start() abort dict "{{{3
    let self.working_dir = getcwd()
    let cmd = self.GetReplCmd()
    Tlibtrace 'workbook', 'Start', cmd
    let self.job = job_start(cmd, {'in_mode': 'raw', 'out_mode': 'raw', 'err_mode': 'raw'
                \ , 'close_cb': {ch -> self.CloseCb(ch, 'closed')}
                \ , 'exit_cb': {job, status -> self.ExitCb(job, status, 'exited')}
                \ , 'out_cb': {ch, msg -> self.OutCb(ch, msg)}
                \ , 'err_cb': {ch, msg -> self.ErrCb(ch, msg)}
                \ })
    " \ , 'out_timeout': 500, 'err_timeout': 500
    if has_key(self, 'wait_after_startup')
        exec 'sleep' self.wait_after_startup
    endif
    if job_status(self.job) ==# 'fail'
        echoerr 'Cannot start process:' cmd
    endif
endf


function! s:prototype.CloseCb(job, type) abort dict "{{{3
    call self.Echohl('Workbook: REPL '. self.id .' '. a:type)
    " let self.teardown = 1
    " call workbook#Stop({}, self)
endf


function! s:prototype.ExitCb(job, status, type) abort dict "{{{3
    call self.Echohl('Workbook: REPL '. self.id .' '. a:type .' with status '. a:status)
    let self.teardown = 1
    call workbook#Stop({}, self)
endf


function! s:prototype.PreprocessCallbackRawMessage(msg) abort dict "{{{3
    Tlibtrace 'workbook', 'PreprocessCallbackRawMessage', a:msg
    if has_key(self, 'PreprocessRawMessage')
        return self.PreprocessRawMessage(a:msg)
    else
        return a:msg
    endif
endf


function! s:prototype.OutCb(ch, msg) abort dict "{{{3
    Tlibtrace 'workbook', 'OutCb', a:msg
    if get(self, 'ignore_output', 0) > 2
        return
    endif
    call self.ConsumeOutput('', self.PreprocessCallbackRawMessage(a:msg))
endf


function! s:prototype.ErrCb(ch, msg) abort dict "{{{3
    Tlibtrace 'workbook', 'ErrCb', a:msg
    call self.ConsumeError(self.PreprocessCallbackRawMessage(a:msg))
endf


function! s:prototype.Stop(args) abort dict "{{{3
    Tlibtrace 'workbook', 'Stop', a:args
    if has_key(self, 'ExitFiletype')
        call self.ExitFiletype(a:args)
    endif
    if job_status(self.job) ==# 'run'
        call job_stop(self.job)
    endif
endf


function! s:prototype.IsReady(...) abort dict "{{{3
    let warn = a:0 >= 1 ? a:1 : !has_key(self, 'teardown')
    let rv = job_status(self.job) == 'run'
    Tlibtrace 'workbook', 'IsReady', warn, rv
    if !rv && warn
        call self.Echohl('Workbook: REPL '. self.id .' is not ready')
    endif
    return rv
endf


function! s:prototype.SendToRepl(code, ...) abort dict "{{{3
    let nl = a:0 >= 1 ? a:1 : 0
    let placeholder = a:0 >= 2 ? a:2 : ''
    Tlibtrace 'workbook', 'SendToRepl', nl, placeholder, a:code
    let code = nl ? a:code ."\n" : a:code
    let channel = job_getchannel(self.job)
    if nl && has_key(self, 'ProcessSendLine')
        for line in split(code, '\n')
            if self.IsReady()
                Tlibtrace 'workbook', 'SendToRepl', line
                let sent = self.ProcessSendLine({-> ch_sendraw(channel, line ."\n")})
                " Tlibtrace 'workbook', 'SendToRepl', sent
            endif
        endfor
    else
        if self.IsReady()
            Tlibtrace 'workbook', 'SendToRepl', code
            call ch_sendraw(channel, code)
        endif
    endif
endf

