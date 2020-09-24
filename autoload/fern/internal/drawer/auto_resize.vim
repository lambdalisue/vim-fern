function! fern#internal#drawer#auto_resize#init() abort
  if g:fern#disable_drawer_auto_resize
    return
  endif

  augroup fern_internal_drawer_init
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call fern#internal#drawer#resize()
    autocmd BufLeave <buffer> call fern#internal#drawer#resize()
  augroup END
endfunction
