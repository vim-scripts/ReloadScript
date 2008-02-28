" ReloadScript.vim: Reload a VIM script during script development. 
"
" DESCRIPTION:
"   Re-sources a VIM script. The script may use a multiple inclusion guard
"   variable g:loaded_<scriptname> (with <scriptname> having either the same
"   case as specified or all lowercase.) 
"   If you specify the bare scriptname (without .vim extension), the script must
"   reside in $VIMRUNTIME/plugin/<scriptname>.vim. Otherwise, the passed
"   filespec is interpreted as the file system location of a VIM script and
"   sourced as-is. 
"   If you execute :ReloadScript without passing a scriptname, the current
"   buffer is re-sourced. 
"
" USAGE:
"   :ReloadScript			Re-sources the current buffer. 
"   :ReloadScript <scriptname>		Re-sources the passed plugin script. 
"   :ReloadScript <path/to/script.vim>	Re-sources the passed file. 
"
" INSTALLATION:
"   Put the script into your user or system VIM plugin directory (e.g.
"   ~/.vim/plugin). 
"
" DEPENDENCIES:
"   - Requires VIM 7.0 or higher. 
"
" CONFIGURATION:
"
" LIMITATIONS:
"   - The script cannot reload itself :-)
"
" ASSUMPTIONS:
"   Not every script supports reloading. There may be error messages like
"   "function already exists". To support reloading, the script should use the
"   bang (!) variants of :function! and :command!, which will automatically
"   override already existing elements. 
"
"   Ensure that the script uses a multiple inclusion guard variable that
"   conforms to the conventions mentioned above. The :ReloadScript command will
"   issue a warning if it cannot find the inclusion guard variable. 
"
" TODO:
"
" Copyright: (C) 2007 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" REVISION	DATE		REMARKS 
"   1.10.004	28-Feb-2008	A scriptname argument with path and/or extension
"				is sourced as-is. This allows a third usage:
"				:ReloadScript <path/to/script.vim>
"   1.00.003	22-May-2007	Added documentation. 
"	002	02-Apr-2007	Inclusion guard variable can have the same case
"				as the script name or be all lowercase. 
"	0.01	14-Dec-2006	file creation

" Avoid installing twice or when in compatible mode
if exists("g:loaded_ReloadScript") || (v:version < 700)
    finish
endif
let g:loaded_ReloadScript = 1

function! s:RemoveInclusionGuard( scriptName )
    let l:scriptInclusionGuard = 'g:loaded_' . a:scriptName
    if ! exists( l:scriptInclusionGuard )
	let l:scriptInclusionGuard = 'g:loaded_' . tolower(a:scriptName)
    endif
    if exists( l:scriptInclusionGuard )
	execute 'unlet ' . l:scriptInclusionGuard
    else
	echohl WarningMsg
	echomsg 'No inclusion guard variable found.'
	echohl None
    endif
endfunction

function! s:ReloadScript(...)
    if a:0 == 0
	" Note: We do not check whether the current buffer contains a VIM
	" script; :source will tell. 
	let l:scriptName = expand('%:t:r')
	let l:scriptFilespec = expand('%')
	let l:sourceCommand = 'source'
    else
	let l:scriptName = fnamemodify( a:1, ':t:r' ) " Strip off file path and extension. 
	if l:scriptName == a:1
	    " A bare scriptname has been passed. 
	    let l:scriptFilespec = 'plugin/' . l:scriptName . '.vim'
	    let l:sourceCommand = 'runtime'
	    " Note: the :runtime command does not complain if no script was found. 
	else
	    " We assume the passed filespec represents an existing VIM script
	    " somewhere on the file system. 
	    let l:scriptFilespec = a:1
	    let l:sourceCommand = 'source'
	endif
    endif

    call s:RemoveInclusionGuard( l:scriptName )

    execute l:sourceCommand . ' ' . l:scriptFilespec
    echomsg 'Reloaded "' . l:scriptFilespec . '"'
endfunction

"command! -nargs=1 -complete=file ReloadScript if exists("g:loaded_<args>") | unlet g:loaded_<args> | endif | runtime plugin/<args>.vim
command! -nargs=? -complete=file ReloadScript call <SID>ReloadScript(<f-args>)

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
