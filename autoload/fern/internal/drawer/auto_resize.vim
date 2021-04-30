function! fern#internal#drawer#auto_resize#init() abort
  if g:fern#disable_drawer_auto_resize
    return
  endif

  augroup fern_internal_drawer_auto_resize_init
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:load_resize()
    if !g:fern#disable_drawer_auto_resize_keep
      autocmd BufLeave <buffer> call s:save_resize()
    endif
  augroup END
endfunction

function! s:save_resize() abort
  if s:should_skip()
    return
  endif
  let b:fern_drawer_auto_resize_keep = winwidth(0)
endfunction

function! s:load_resize() abort
  if s:should_skip()
    return
  endif
  if !exists('b:fern_drawer_auto_resize_keep')
    call fern#internal#drawer#resize()
  else
    execute 'vertical resize' b:fern_drawer_auto_resize_keep
  endif
endfunction

if has('nvim')
  function! s:should_skip() abort
    return nvim_win_get_config(win_getid()).relative !=# ''
  endfunction
else
  function! s:should_skip() abort
    return 0
  endfunction
endif
