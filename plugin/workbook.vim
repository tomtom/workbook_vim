" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-03-16
" @Revision:    24
" GetLatestVimScripts: 5527 0 :AutoInstall: workbook.vim

if &cp || exists('g:loaded_workbook')
    finish
endif
let g:loaded_workbook = 2

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:workbook_autosetup_filetypes')
    let g:workbook_autosetup_filetypes = []   "{{{2
endif


" :display: :Workbook [--filetype=FILETYPE] [--cmd=CMD] [--args=ARGS] [-- OTHER]
" If no FILETYPE is specified 'filetype' is used.
" CMD and ARGS can be used to override the default parameters for the 
" gived filetype.
" OTHER arguments are added to CMD ARGS when starting the inferior 
" process.
"
" Additional filetype-specific arguments:
" r:
"   --[no-]save ...... Save an image (default: --no-save)
"   --[no-]restore ... Restore an image (default: --restore)
command! -nargs=* -bang -bar -complete=customlist,workbook#Complete Workbook call workbook#GetRepl([<f-args>], !empty("<bang>"))


" Select a repl from a list of inferior processes. The list also 
" included their status.
command! -bar Workbooks call workbook#Overview()


augroup Workbook
    autocmd!
    for s:ft in g:workbook_autosetup_filetypes
        exec 'autocmd Filetype' s:ft 'call workbook#SetupBuffer()'
    endfor
    unlet! s:ft
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
