"----------------------------------------------------------------------------"
" This plugin enables easy integration with quilt, to push/pop/refresh patch '
"                                                                            '
" Author:     Florian Delizy <florian.delizy@unfreeze.net>                   '
" Maintainer: Florian Delizy <florian.delizy@unfreeze.net>                   '
" ChangeLog:                                                                 '
"                                                                            '
" * 2006/09/13 - Initial plugin creation
"
" cmds : 
"
" * :QuiltCurrent : print the current patch
" * :QuiltStatus  : refresh all quilt info (from the directory)
"

command! -nargs=0 QuiltStatus call <SID>QuiltStatus()
command! -nargs=0 QuiltPop call <SID>QuiltPop(1)
command! -nargs=0 QuiltPush call <SID>QuiltPush(1)



function! <SID>QuiltPop( nb )
!quilt pop
call <SID>QuiltStatus()
endfunction

function! <SID>QuiltPush( nb )
!quilt push
call <SID>QuiltStatus()
endfunction

function! <SID>QuiltMerge( nb )
endfunction

function! <SID>QuiltPushAll()
endfunction

function! <SID>QuiltPopAll()
endfunction


"
" Print the current patch level and set the global variable for the statusline
" use
" 
function! <SID>QuiltCurrent()


    let g:QuiltCurrentPatch = system ("quilt applied | tail -n 1")
    let g:QuiltCurrentPatch = substitute( g:QuiltCurrentPatch, '\n', '', '' )
    echo "The last patch is " . g:QuiltCurrentPatch

endfunction

"
" Quilt Status : refresh all screen quilt info
"

function! <SID>QuiltStatus()

    call <SID>QuiltCurrent()


    " Set the status line :

    setlocal statusline=%0.28(%f\ %m%h%r%)\ [%{g:QuiltCurrentPatch}]\ %=%0.10(%l,%c\ %P%)
    setlocal laststatus=2

endfunction
