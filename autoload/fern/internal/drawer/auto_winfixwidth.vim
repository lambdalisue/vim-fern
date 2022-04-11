function! fern#internal#drawer#auto_winfixwidth#init() abort
  if g:fern#disable_drawer_auto_winfixwidth
    return
  endif

  augroup fern_internal_drawer_auto_winfixwidth_init
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:set_winfixwidth()
  augroup END
endfunction

function! s:set_winfixwidth() abort
  let &l:winfixwidth = winnr('$') isnot# 1
endfunction
