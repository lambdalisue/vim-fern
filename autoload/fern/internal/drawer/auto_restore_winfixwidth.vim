function! fern#internal#drawer#auto_restore_winfixwidth#init() abort
  if g:fern#disable_drawer_auto_restore_winfixwidth
    return
  endif

  let b:fern_drawer_auto_restore_winfixwidth = get(b:, 'fern_drawer_auto_restore_winfixwidth', &winfixwidth)

  augroup fern_internal_drawer_auto_restore_winfixwidth
    autocmd! * <buffer>
    autocmd BufWinLeave <buffer> call s:restore_winfixwidth()
  augroup END
endfunction

function! s:restore_winfixwidth() abort
  if !exists('b:fern_drawer_auto_restore_winfixwidth')
    return
  endif
  let &winfixwidth = b:fern_drawer_auto_restore_winfixwidth
  silent! unlet! b:fern_drawer_auto_restore_winfixwidth
endfunction
