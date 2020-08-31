function! test#feedkeys(keys) abort
  return s:feedkeys(a:keys)
endfunction

if exists('*nvim_input')
  function! s:feedkeys(keys) abort
    return nvim_input(a:keys)
  endfunction
else
  function! s:feedkeys(keys) abort
    return timer_start(0, { -> feedkeys(a:keys) })
  endfunction
endif
