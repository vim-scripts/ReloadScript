" ReloadScript.vim: Reload a Vim script during script development.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"
" Copyright: (C) 2007-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" REVISION	DATE		REMARKS
"   1.21.007	27-Aug-2012	Avoid <f-args> because of its unescaping
"				behavior.
"				Also no global inclusion guard for ftdetect
"				scripts.
"   1.20.006	07-Jan-2011	BUG: Avoiding "E471: Argument required" error on
"				empty buffer name.
"				ENH: Explicitly checking for the existence of
"				the file, as we don't want to put the :source
"				command inside try...catch (it would stop
"				showing all resulting errors and show only the
"				first), and because :runtime doesn't complain at
"				all.
"   1.10.005	25-Jul-2008	Combined missing inclusion guard warning with
"				reload message to avoid the "Hit ENTER" prompt.
"				No missing inclusion guard warning for scripts
"				that do not need one (e.g. after-directory,
"				autoload, ftplugin, indent, syntax, ...)
"   1.10.004	28-Feb-2008	A scriptname argument with path and/or extension
"				is sourced as-is. This allows a third usage:
"				:ReloadScript {path/to/script.vim}
"   1.00.003	22-May-2007	Added documentation.
"	002	02-Apr-2007	Inclusion guard variable can have the same case
"				as the script name or be all lowercase.
"	0.01	14-Dec-2006	file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_ReloadScript') || (v:version < 700)
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
	return 1
    else
	return 0
    endif
endfunction

let s:noGlobalInclusionGuardPattern = '^\%(autoload\|colors\|compiler\|ftdetect\|ftplugin\|indent\|keymap\|lang\|syntax\)$'
function! s:IsScriptTypeWithInclusionGuard( scriptFilespec )
    " Scripts that only modify the current buffer do not have a global inclusion
    " guard (but should have a buffer-local one).
    " Autoload, color scheme, keymap and language scripts do not need an
    " inclusion guard.
    " Scripts in the after-directory do not need an inclusion guard.
    let l:scriptDir = fnamemodify( a:scriptFilespec, ':p:h:t' )
    " Because Vim supports both .vim/ftplugin/filetype_*.vim and
    " .vim/ftplugin/filetype/*.vim, we need to check the two directories
    " upwards.
    let l:scriptParentDir = fnamemodify( a:scriptFilespec, ':p:h:h:t' )
    let l:scriptParentParentDir = fnamemodify( a:scriptFilespec, ':p:h:h:h:t' )

    return ! (l:scriptDir =~? s:noGlobalInclusionGuardPattern || l:scriptParentDir =~? s:noGlobalInclusionGuardPattern || l:scriptParentDir =~? '^after$' || l:scriptParentParentDir =~? '^after$')
endfunction

function! s:ReloadScript( scriptFilespec )
    if empty(a:scriptFilespec)
	" Note: We do not check whether the current buffer contains a Vim
	" script; :source will tell.
	let l:scriptName = expand('%:t:r')
	let l:scriptFilespec = expand('%')
	if empty(l:scriptFilespec)
	    let v:errmsg = 'No file name'
	    echohl ErrorMsg
	    echomsg v:errmsg
	    echohl None
	    return
	endif
	let l:sourceCommand = 'source'
	let l:canContainInclusionGuard = s:IsScriptTypeWithInclusionGuard(l:scriptFilespec)
    else
	let l:scriptName = fnamemodify( a:scriptFilespec, ':t:r' ) " Strip off file path and extension.
	if l:scriptName ==# a:scriptFilespec
	    " A bare scriptname has been passed.
	    let l:scriptFilespec = 'plugin/' . l:scriptName . '.vim'
	    let l:sourceCommand = 'runtime'
	    " Note: the :runtime command does not complain if no script was found.
	else
	    " We assume the passed filespec represents an existing Vim script
	    " somewhere on the file system.
	    let l:scriptFilespec = a:scriptFilespec
	    let l:sourceCommand = 'source'
	endif
	let l:canContainInclusionGuard = 1
    endif

    " Assumption: 'wildignore' doesn't filter away *.vim files. Starting with
    " Vim 7.3 we will be able to pass the option {flag} to glob()/ globpath().
    if l:sourceCommand ==# 'source' && empty(glob(l:scriptFilespec))
	let v:errmsg = "Can't source file " . l:scriptFilespec
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
	return
    elseif l:sourceCommand ==# 'runtime' && empty(globpath(&runtimepath, l:scriptFilespec))
	let v:errmsg = "Can't runtime " . l:scriptFilespec
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
	return
    endif

    let l:isRemovedInclusionGuard = s:RemoveInclusionGuard( l:scriptName )

    " Note: We do not execute the command inside a try...catch, because then
    " sourcing an invalid Vim script would only print the first error, not all
    " bad lines, like :source does. Instead, we check for the existence of the
    " sourced file beforehand, and manually generate an error if it doesn't
    " exist.
    " Assumption: The script filespec does not contain special characters, so we
    " don't need to fnameescape().
    execute l:sourceCommand l:scriptFilespec

    if ! l:canContainInclusionGuard || l:isRemovedInclusionGuard
	echomsg 'Reloaded "' . l:scriptFilespec . '"'
    else
	let v:warningmsg = 'Reloaded "' . l:scriptFilespec . '"; no inclusion guard variable found.'
	echohl WarningMsg
	echomsg v:warningmsg
	echohl None
    endif
endfunction

"command! -nargs=1 -complete=file ReloadScript if exists("g:loaded_<args>") | unlet g:loaded_<args> | endif | runtime plugin/<args>.vim
command! -nargs=? -complete=file ReloadScript call <SID>ReloadScript(<q-args>)

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
