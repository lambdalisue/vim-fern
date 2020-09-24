function! fern#internal#drawer#auto_winfixwidth#init() abort
  if g:fern#disable_drawer_auto_winfixwidth
    return
  endif

  augroup fern_internal_drawer_auto_winfixwidth_init
    autocmd! * <buffer>
    autocmd BufEnter <buffer> setlocal winfixwidth
  augroup END
endfunction
