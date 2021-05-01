function! fern#internal#drawer#auto_resize#init() abort
  if g:fern#disable_drawer_auto_resize
    return
  endif

  augroup fern_internal_drawer_init
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:load_width()
    autocmd BufLeave <buffer> call s:save_width()
  augroup END
endfunction

if has('nvim')
  function! s:should_ignore() abort
    return nvim_win_get_config(win_getid()).relative !=# ''
  endfunction
else
  function! s:should_ignore() abort
    return 0
  endfunction
endif

function! s:save_width() abort
  if s:should_ignore()
    return
  endif
  let t:fern_drawer_auto_resize_width = winwidth(0)
endfunction

function! s:load_width() abort
  if s:should_ignore()
    return
  endif
  if !exists('t:fern_drawer_auto_resize_width')
    call fern#internal#drawer#resize()
  else
    execute 'vertical resize' t:fern_drawer_auto_resize_width
  endif
endfunction
