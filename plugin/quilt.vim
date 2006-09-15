"----------------------------------------------------------------------------"
" This plugin enables easy integration with quilt, to push/pop/refresh patch '
"                                                                            '
" Author:     Florian Delizy <florian.delizy@unfreeze.net>                   '
" Maintainer: Florian Delizy <florian.delizy@unfreeze.net>                   '
" ChangeLog:                                                                 '
" 
" uses : 
"
" * :QuiltStatus            : refresh all quilt info (from the directory)
" * :QuiltPush    [patch/n] : push to the patch (default is 1)
" * :QuiltPop     [patch/n] : pop the current patch
" * :QuiltAdd	  [file]    : add the current file to the patch
" * :QuiltRemove  [file]    : remove the file from the patch (default=current)
" * :QuiltRefresh [patch]   : refresh the patch (default=current)
"
" 0.1a : (2006/09/13)
" 	* Initial plugin creation
"
" 0.2b : (2006/09/14)
" 	* add QuiltRefresh, QuiltPush, QuiltPop commands
" 	* add QuiltAdd, QuiltRemove
" 	* check if the current directory is a quilt directory
" 	* add parameters for Refresh, Add, Pop, Add ... 
" 	* add patch completion
" 	* add in patch files completion
"
" TODO 
" * a real interface like DirDiff 
" * a merge interface
" * an interface showing the current patch on the bottom
" * allow fold/unfold to see what files are included
" * handle quilt error/warnings using quickfix ... 
" * auto add the currently modified file
" * auto refresh on change
" * handle parameters for simple operations
" * add an indication to know if the patch needs refresh or not
" * add an indication to know if the current file is in the current patch
" * add a command to move a line from a patch to another
" * add a Quilt command that takes the cmd as a parameter
" * prevent the writing if the file is in no patch (without the ! option)

command! QuiltStatus call <SID>QuiltStatus()

command! -nargs=? -complete=custom,QuiltCompleteInAppliedPatch   QuiltPop  call <SID>QuiltPop(<f-args>)
command! -nargs=? -complete=custom,QuiltCompleteInUnAppliedPatch QuiltPush call <SID>QuiltPush(<f-args>)

command! -nargs=? -complete=file                                 QuiltAdd <SID>QuiltAdd(<f-args>)
command! -nargs=? -complete=custom,QuiltCompleteInFiles          QuiltRemove call <SID>QuiltRemove(<f-args>)

command! -nargs=? -complete=custom,QuiltCompleteInPatch		 QuiltRefresh call <SID>QuiltRefresh( <f-args> )

" TODO :
"command! -range -nargs=1 -complete=custom,QuiltCompleteInPatch QuiltMoveTo call <SID>QuiltMoveTo( <f-args> )
"command! QuiltInterface call <SID>QuiltInterface()

" DEBUG

command! QuiltIsOK call <SID>IsQuiltDirectory()



"
" Pop the current patch
"

function! <SID>QuiltPop( ... )
    
    if <SID>IsQuiltDirectory() == 0 
	return 0
    endif

    let cmd= "!quilt pop "

    if a:0 == 1
	let cmd = cmd . a:1
    endif

    exec cmd

    call <SID>QuiltStatus()

endfunction

"
" Push to the next patch 
"

function! <SID>QuiltPush( ... )

    if <SID>IsQuiltDirectory() == 0 
	return 0
    endif

    let cmd= "!quilt push "

    if a:0 == 1
	let cmd = cmd . a:1
    endif

    exec cmd

    call <SID>QuiltStatus()

endfunction

"
" Add the file to the current Quilt patch
" 
" TODO: Handle the -P patch command arg
"
function! <SID>QuiltAdd( ... )

    if <SID>IsQuiltDirectory() == 0 
	return 0
    endif

    let cmd= "!quilt add "

    if a:0 >= 1
	let cmd = cmd . a:1
    else 
	let cmd = cmd . "%"
    endif

    exec cmd

    call <SID>QuiltStatus()

endfunction

"
" Remove the file from the current patch 
"
" TODO: Handle the -P patch command arg
"

function! <SID>QuiltRemove( ... )

    if <SID>IsQuiltDirectory() == 0 
	return 0
    endif

    let cmd= "!quilt remove "

    if a:0 >= 1
	let cmd = cmd . a:1
    else 
	let cmd = cmd . "%"
    endif

    exec cmd

    call <SID>QuiltStatus()
endfunction

" refresh the current patch
function! <SID>QuiltRefresh( file )

" TODO: handle warning and errors, handle refresh a specific patch
" using cexpr caddexpr cgetexpr and errorformat as well
"
"
    if <SID>IsQuiltDirectory() == 0 
	return 0
    endif

    let cmd= "!quilt refresh "

    if a:0 == 1
	let cmd = cmd . a:1
    endif

    exec cmd

    call <SID>QuiltStatus()

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

    if <SID>IsQuiltDirectory() == 0 
	return 0
    endif

    call <SID>QuiltCurrent()

    " Set the status line :

    setlocal statusline=%0.28(%f\ %m%h%r%)\ [%{g:QuiltCurrentPatch}]\ %=%0.10(%l,%c\ %P%)
    setlocal laststatus=2

endfunction


"
" Start the Quilt interface
"

function! <SID>QuiltInterface()

    " List all patches 
    new
    silent %!quilt applied 
    $
    silent .!quilt unapplied

endfunction


"
" returns 1 if the current directory is quilt enabled 
" returns 0 if not
"
function! <SID>IsQuiltDirectory()

    " Must find the patches directory

    if <SID>FileExists( "patches" ) 

	" Must find a series file somewhere
	if    <SID>FileExists( "series" ) || <SID>FileExists( "patches/series" ) || <SID>FileExists( ".pc/series" ) 
           return 1
        endif

    endif

    echo "This is not a quilt directory ... sorry"
    return 0
endfunction


"
" returns true if the specified file or directory exists
" (this is very bash dependant for now ... )
function! <SID>FileExists( filename )
    return system( ' [ -e ' . a:filename . ' ] && echo 1 || echo 0 ' )
endfunction

"
" List all patches availables as a string list (one line per patch)
"
function! <SID>ListAllPatches()
    return system('quilt applied 2>/dev/null ; quilt unapplied 2>/dev/null')
endfunction

"
" List all files included in the current patch 
"
function! <SID>ListAllFiles()
    return system('quilt files 2>/dev/null')
endfunction

"
" Completion part (used for commands)
"


"
" Complete in the patch list :
" 
function! QuiltCompleteInPatch( ArgLead, CmdLine, CursorPos )

    if ( <SID>IsQuiltDirectory() ) 
	return <SID>ListAllPatches()
    endif

    return ""

endfunction

"
" Complete in the applied patch list :
" 
function! QuiltCompleteInAppliedPatch( ArgLead, CmdLine, CursorPos )

    if ( <SID>IsQuiltDirectory() ) 
	return system( 'quilt applied 2>/dev/null' )
    endif

    return ""

endfunction

"
" Complete in the unapplied patch list :
" 
function! QuiltCompleteInUnAppliedPatch( ArgLead, CmdLine, CursorPos )

    if ( <SID>IsQuiltDirectory() ) 
	return system( 'quilt unapplied 2>/dev/null' )
    endif

    return ""

endfunction

"
" Complete in files included in the current patch
"

function! QuiltCompleteInFiles( ArgLead, CmdLine, CursorPos )

    if ( <SID>IsQuiltDirectory() ) 
	return <SID>ListAllFiles()
    endif

    return ""

endfunction


" 
" Complete first on the files then on the patches
"
" For now useless, but it's a good skeleton for tuning QuiltAdd and
" QuiltRemove
function! QuiltCompleteFilesPatch( ArgLead, CmdLine, CursorPos )

    if ( <SID>IsQuiltDirectory() ) 

	" first arg is in the files, second is in the patches
	
	echo a:CmdLine
	if a:CmdLine =~ "[^[:blank:]][^[:blank:]]* [^[:blank:]][^[:blank:]]* "

	    return system( "quilt applied" )

	endif

	return <SID>ListAllFiles()

    endif

    return ""

endfunction
