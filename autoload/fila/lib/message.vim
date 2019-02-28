function! fila#lib#message#printf(message, ...) abort
  return a:0 ? call('printf', [a:message] + a:000) : a:message
endfunction

function! fila#lib#message#echo(...) abort
  let m = call('fila#lib#message#printf', a:000)
  echo m
endfunction

function! fila#lib#message#echomsg(...) abort
  let m = call('fila#lib#message#printf', a:000)
  echomsg m
endfunction

function! fila#lib#message#notify(...) abort
  let m = call('fila#lib#message#printf', a:000)
  redraw | echo m
endfunction

function! fila#lib#message#warning(...) abort
  let m = call('fila#lib#message#printf', a:000)
  echohl WarningMsg
  redraw | echo m
  echohl None
endfunction

function! fila#lib#message#error(...) abort
  let m = call('fila#lib#message#printf', a:000)
  echohl ErrorMsg
  redraw | echo
  for line in split(m, '\n')
    echomsg line
  endfor
  echohl None
endfunction
