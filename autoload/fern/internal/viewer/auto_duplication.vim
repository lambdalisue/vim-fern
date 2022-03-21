function! fern#internal#viewer#auto_duplication#init() abort
  if g:fern#disable_viewer_auto_duplication ||
    \ (g:fern#disable_drawer_tabpage_isolation && fern#internal#drawer#is_drawer())
    return
  endif

  augroup fern_internal_viewer_auto_duplication_init
    autocmd! * <buffer>
    autocmd WinEnter <buffer> nested call s:duplicate()
  augroup END
endfunction

function! s:duplicate() abort
  if len(win_findbuf(bufnr('%'))) < 2
    return
  endif
  " Only one window is allowed to display one fern buffer.
  " So create a new fern buffer with same options
  let fri = fern#fri#parse(bufname('%'))
  let fri.authority = ''
  let bufname = fern#fri#format(fri)
  execute printf('silent! keepalt edit %s', fnameescape(bufname))
endfunction
