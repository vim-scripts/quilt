"------------------------------------------------------------------------------
" This plugin enables easy integration with quilt, to push/pop/refresh patch   
"                                                                              
" Author:     Florian Delizy <florian.delizy@unfreeze.net>                     
" Maintainer: Florian Delizy <florian.delizy@unfreeze.net>                     
" ChangeLog:                                                                   
"                                                                              
" usage :                                                                      
"                                                                              
" :QuiltStatus                : show/refresh the current patch name in the     
"                               status bar                                     
"                                                                              
" :QuiltPush[!]    [patch/n]  : push to the patch (default is 1)               
" :QuiltPop[!]     [patch/n]  : pop the current patch                          
"  QuiltGoTo[!]    [patch/n]  : push or pop to the specified patch             
"                                                                              
" :QuiltAdd        [file]     : add the current file to the patch              
" :QuiltRemove     [file]     : remove the file from the patch (default=%)     
"                                                                              
" :QuiltRefresh    [patch]    : refresh the patch (default=%)                  
"                                                                              
" :[range]QuiltMoveTo[!] [patch]: move the text range from the current patch to
"                               the dest patch                                 
"  QuiltFinishMove[!]         : finishes a move initiated with QuiltMoveTo     
"                                                                              
"  QuiltSetup <patch_dir>     : Setup the working directory with needed links  
"  QuiltNew[!] <patch>           : Creates a new patch on the top of the stack 
"  QuiltDelete[!] [patch]     : Delete the patch, default is current           
"                                                                              
"------------------------------------------------------------------------------
" ChangeLog:                                                                   
"                                                                              
" 0.1a : (2006/09/13)                                                          
"       * Initial plugin creation                                              
"                                                                              
" 0.2b : (2006/09/15)                                                          
"       * Added QuiltRefresh, QuiltPush, QuiltPop commands                     
"       * Added QuiltAdd, QuiltRemove                                          
"       * Check if the current directory is a quilt directory                  
"       * Added parameters for Refresh, Add, Pop, Add ...                      
"       * Added patch completion                                               
"       * Added in patch files completion                                      
"                                                                              
" 0.3  : [2006/09/17]                                                          
"       * Added the ! argument for Pop,Push,Refresh                            
"       * Added the QuiltMoveTo/QuiltFinishMove command                        
"       * Spellchecked the Changelog ;)                                        
"       * Fixed the QuiltRefresh bug                                           
"       * Fixed QuiltAdd definition bug                                        
"       * Added QuiltGoTo[!] (Push/Pop)                                        
"       * Added QuiltSetup[!]                                                  
"       * Make this file 80 characters terminal friendly                       
"       * Added QuiltNew command                                               
"       * Added QuiltDelete[!]                                                 
"       * Fixed a whole bunch of bugs ... (thanks to #vim IRC channel )        
"                                                                              
"------------------------------------------------------------------------------
"                                                                              
" TODO:                                                                        
"                                                                              
" * a real interface like DirDiff                                              
" * a merge interface                                                          
" * an interface showing the current patch on the bottom                       
" * allow fold/unfold to see what files are included                           
" * handle quilt error/warnings using quickfix ...                             
" * auto add the currently modified file                                       
" * auto refresh on change                                                     
" * add an indication to know if the patch needs refresh or not                
" * add an indication to know if the current file is in the current patch      
" * add a command to move a line from a patch to another                       
" * add a Quilt command that takes the cmd as a parameter                      
" * prevent the writing if the file is in no patch (without the ! option)      
" * with the DirDiff intefface, add a background color to highlight what       
"   belong to what patch (might be possible for only one patch ?               
" * add an info to show to which patch belong a chunk                          
" * add Mail command                                                           
" * add a help file for commands                                               


"------------------------------------------------------------------------------
" Commands definition                                                          
"------------------------------------------------------------------------------


command! QuiltStatus call <SID>QuiltStatus()

command! -nargs=? -bang -complete=custom,QuiltCompleteInAppliedPatch   
       \ QuiltPop  call <SID>QuiltPop("<bang>", <f-args>)
command! -nargs=? -bang -complete=custom,QuiltCompleteInUnAppliedPatch 
       \ QuiltPush call <SID>QuiltPush("<bang>", <f-args>)
command! -nargs=? -bang -complete=custom,QuiltCompleteInPatch          
       \ QuiltGoTo call <SID>QuiltGoTo("<bang>", <f-args>)

command! -nargs=? -complete=file                                       
       \ QuiltAdd call <SID>QuiltAdd(<f-args>)
command! -nargs=? -complete=custom,QuiltCompleteInFiles                
       \ QuiltRemove call <SID>QuiltRemove(<f-args>)

command! -nargs=? -bang -complete=custom,QuiltCompleteInPatch          
       \ QuiltRefresh call <SID>QuiltRefresh("<bang>", <f-args> )

command! -range -nargs=1 -bang -complete=custom,QuiltCompleteInPatch   
       \ QuiltMoveTo <line1>,<line2>call <SID>QuiltMoveTo( "<bang>", <f-args> )
command! -bang QuiltFinishMove call <SID>QuiltFinishMove( "<bang>" )

command! -nargs=1 -complete=dir -bang                                  
       \ QuiltSetup call <SID>QuiltSetup( "<bang>", <f-args> )

command! -nargs=+ -bang QuiltNew call <SID>QuiltNew( "<bang>", <f-args> )
command! -nargs=? -bang -complete=custom,QuiltCompleteInPatch
       \ QuiltDelete call <SID>QuiltDelete( "<bang>", <f-args> )

" TODO
" command! QuiltInterface call <SID>QuiltInterface()

"                                                                              
" Create a new patch on the top of the patch stack                             
" ! create the directory if not existing                                       
"                                                                              

function! <SID>QuiltNew( bang,  patch )

    if <SID>ListAllPatches() =~ a:patch
       echohl ErrorMsg
       echo "there is already a patch called " . a:patch
       echohl none
       return 0
    endif

   " Make sure that the directory exists ... 
 
   if a:patch =~ "/$"
       echohl ErrorMsg
       echo "the patch name can not end with a /"
       echohl none
   endif

   if a:patch =~ "/"

       let dir = substitute( a:patch, "/[^/]*$", "", "g" )

       if isdirectory( "patches/" . dir ) == 0

           if a:bang == "!"

               echo "Creating " . dir "/"
               call mkdir( "patches/" . dir , "p" )

           else

               echohl ErrorMsg
               echo "Directory " . dir . " does not exists, use ! to create it"
               echohl none
               return 0
           endif
    

       endif

   endif

   call system ( "quilt new " . a:patch )

   call <SID>QuiltStatus()

endfunction

"                                                                              
" Create a new patch on the top of the patch stack                             
" ! : remove the file on the patch directory as well (-r)                      
"                                                                              

function! <SID>QuiltDelete( bang, ... )

    let cmd = "quilt delete "

    if a:bang == "!"

        let cmd = cmd  . " -r "

    endif

    if a:0 == 1

        call <SID>QuiltCurrent()
        if g:QuiltCurrentPatch != a:1 && <SID>ListUnAppliedPatches() !~ a:1

            echohl ErrorMsg
            echo "quilt only knows how to delete the topmost patch or an "
               \ . "unapplied patch ... fist unapply the patch before deleting"
               \ . " it "
            echohl none

        endif

        let cmd = cmd . a:1

    endif

 
    call system( cmd )

    call <SID>QuiltStatus()

endfunction

"                                                                              
" Setup a link to the patch directory, supplied as argument                    
" check that the 'series file exist, and try to find it, if found,             
" link it into the patch directory as well                                     
" <bang> is erase previous patches/series files before proceeding              
" if not found, the series file is created empty                               
"                                                                              

function! <SID>QuiltSetup( bang, patchdir )

    if <SID>IsQuiltOK() && a:bang != "!"

        echohl WarningMsg
        echo "This is already a valid quilt sandbox, use ! to recreate it"
        echohl none
        return

    endif
    " Cleanup an already existing

    if a:bang == "!"

        if   <SID>FileExists( "patches" )
        \ && system( "file patches 2>&1" ) =~ "symbolic link"

            echo "Removing existing patches link"
            call delete( "patches" )

        endif

    endif

    if <SID>FileExists( "patches" )

        echohl ErrorMsg
        echo "Can't remove an existing file, use ! to override"
        echohl none
        return 0

    endif

    " Check if the directory argument exists ?

    if   <SID>FileExists( a:patchdir ) == 0

        if a:bang == "!"

            call mkdir( a:patchdir )

        else

            echohl ErrorMsg
            echo a:patchdir . " Does not exists ... use ! to create it too"
            echohl none
            return 0

        endif

    endif

    call system( "ln -s " . a:patchdir . " patches" )

    if   filereadable( "series" ) == 0
    \ && filereadable( "patches/series" ) == 0
    \ && filereadable( ".pc/series" ) == 0
        
        " Series file does not exists ?? => create it
 
        let series = 
          \ [ '# quilt series files, automatically created by quilt.vim plugin'
          \ , '# Created on the ' . strftime( "%c" ) ]

        call writefile( series, "patches/series" )

    endif

endfunction


"
" Pop the current patch
"

function! <SID>QuiltPop( bang, ... )
    
    if <SID>IsQuiltDirectory() == 0 
        return 0
    endif


    let cmd= "!quilt pop "

    if a:0 == 1
        let cmd = cmd . a:1
    endif

    if a:bang == "!"
        let cmd = cmd . " -f "
    endif

    exec cmd

    call <SID>QuiltStatus()

endfunction

"
" Push to the next patch 
" TODO: Handle the .rej in a separate buffer ... (and add it into a quickfix)

function! <SID>QuiltPush( bang, ... )

    if <SID>IsQuiltDirectory() == 0 
        return 0
    endif

    let cmd= "!quilt push "

    if a:0 == 1
        let cmd = cmd . a:1
    endif

    if a:bang == "!"
        let cmd = cmd . " -f "
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
function! <SID>QuiltRefresh( bang, ... )

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

    if a:bang == "!"
        let cmd = cmd . " -f "
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
function! <SID>IsQuiltOK()

    if <SID>FileExists( "patches" ) 

        " Must find a series file somewhere
        if    <SID>FileExists( "series" ) || <SID>FileExists( "patches/series" ) || <SID>FileExists( ".pc/series" ) 
           return 1
        endif

    endif

    return 0

endfunction

" 
" return 0/1 if it is a quilt directory, and error if not
"
function! <SID>IsQuiltDirectory()

    " Must find the patches directory

    let r = <SID>IsQuiltOK()
    
    if r == 0 
        echohl ErrorMsg
        echo "This is not a quilt directory ... sorry"
        echohl none
    endif

    return r
endfunction

"
" QuiltGoTo : Push or Pop to a defined patch
"

function! <SID>QuiltGoTo( bang, patch )

    call <SID>QuiltCurrent()

    if a:patch == g:QuiltCurrentPatch 
        echohl WarningMsg
        echo "already at " . a:patch . " level"
        echohl none
        return 
    endif

    if <SID>ListAppliedPatches() =~ a:patch
        call <SID>QuiltPop( a:bang, a:patch )
    else

        if <SID>ListUnAppliedPatches() =~ a:patch
            call <SID>QuiltPush( a:bang, a:patch )

        else
            echohl ErrorMsg
            echo "Can't go to a non existing patch, sorry"
            echohl none
        endif

    endif

endfunction


"
" Move the selected modifications to the specified patch
"

function! <SID>QuiltMoveTo( bang,  patch ) range

    echo "startpoint is " . a:firstline
    echo "endpoint is " . a:lastline

"    if bang != "!" 
"       if <SID>ListAppliedPatches() =~ patch
"           echohl ErrorMsg
"           echo "Can't move a a chunk to an applied patch, you can only move a chunk from a patch to a non applied one, use ! to force"
"           echohl none
"       endif
"    endif
    
    " First create a directory structure

    let tmpdir1 = tempname()

    call mkdir( tmpdir1 )

    let basesrc = expand( "%:h" )

    if basesrc != ""
        call mkdir( tmpdir1 . "/a/" . basesrc, "p")
        call mkdir( tmpdir1 . "/b/" . basesrc, "p" )
    else
        call mkdir( tmpdir1 . "/a" )
        call mkdir( tmpdir1 . "/b" )
    endif

    " save the dest file (with the current block) in tmpdir1/b/
    
    exec "write " . tmpdir1 . "/b/%"

    " then delete the block and save the 'original file'
    exec a:firstline . "," . a:lastline . "delete"
    exec "write " . tmpdir1 . "/a/%"

    let cmd = "cd " . tmpdir1 .  " && diff -urN  a b > patch"

    echo cmd
    call system( cmd )

    " Now start to refresh the patch...    

    call <SID>QuiltCurrent()
    let g:QuiltFormerPatch = g:QuiltCurrentPatch
    let g:QuiltMoveFileName = expand( "%" )
        
    write
    call <SID>QuiltRefresh( a:bang )
    call <SID>QuiltGoTo( a:bang, a:patch )
    edit
    exec "vert diffpatch " . tmpdir1 . "/patch"

    if a:bang != "!"
        echo "Please Review modifications in this file, and do :QuiltFinishMove in the "
        \ . expand( "%.new" ) . " file buffer"
    else
        call <sid>QuiltFinishMove( bang )
    endif

endfunction

"
" Finish a move
" 

function! <SID>QuiltFinishMove( bang )

    if   g:QuiltFormerPatch != ""
    \ && g:QuiltMoveFileName != ""
        %y
        quit!
        %d _
        put
        write!
        call <SID>QuiltRefresh( a:bang )
        call <SID>QuiltGoTo( a:bang, g:QuiltFormerPatch )
        unlet g:QuiltFormerPatch
        unlet g:QuiltMoveFileName
    else
        echohl ErrorMsg
        echo "No move was initiated, can't finish it"
        echohl none
    endif

endfunction

"
" returns true if the specified file or directory exists
" Warning: this is very bash dependant for now ... 
" 
function! <SID>FileExists( filename )
    return system( ' [ -e ' . a:filename . ' ] && echo 1 || echo 0 ' )
endfunction

"
" List all patches availables as a string list (one line per patch)
" Warning: bash dependent !
"
function! <SID>ListAllPatches()
    return system('quilt applied 2>/dev/null ; quilt unapplied 2>/dev/null')
endfunction

function! <SID>ListAppliedPatches()
    return system('quilt applied 2>/dev/null')
endfunction

function! <SID>ListUnAppliedPatches()
    return system('quilt unapplied 2>/dev/null')
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

    if <SID>IsQuiltDirectory() 
        return <SID>ListAllPatches()
    endif

    return ""

endfunction

"
" Complete in the applied patch list :
" 
function! QuiltCompleteInAppliedPatch( ArgLead, CmdLine, CursorPos )

    if <SID>IsQuiltDirectory() 
        return <SID>ListAppliedPatches()
    endif

    return ""

endfunction

"
" Complete in the unapplied patch list :
" 
function! QuiltCompleteInUnAppliedPatch( ArgLead, CmdLine, CursorPos )

    if <SID>IsQuiltDirectory() 
        return <SID>ListUnAppliedPatches()
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
            return <SID>ListAppliedPatches()
        endif

        return <SID>ListAllFiles()

    endif

    return ""

endfunction
