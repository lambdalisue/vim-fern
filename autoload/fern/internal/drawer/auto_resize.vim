function! fern#internal#drawer#auto_resize#init() abort
  if g:fern#disable_drawer_auto_resize
    return
  endif

  augroup fern_internal_drawer_init
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:resize()
    autocmd BufLeave <buffer> call s:resize()
  augroup END
endfunction

if has('nvim')
  function! s:is_relative() abort
    return nvim_win_get_config(win_getid()).relative !=# ''
  endfunction

  function! s:resize() abort
    if s:is_relative()
      return
    endif
    call fern#internal#drawer#resize()
  endfunction
else
  let s:resize = funcref('fern#internal#drawer#resize')
endif
