function! fern#internal#drawer#auto_resize_all#init() abort
  if g:fern#disable_drawer_auto_resize_all
    return
  endif

  augroup fern_internal_drawer_auto_resize_all_init
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:resize_all()
  augroup END
endfunction

function! s:resize_all() abort
  execute "normal! \<C-W>="
endfunction
