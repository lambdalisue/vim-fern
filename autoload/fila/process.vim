let s:Process = vital#fila#import('Async.Process')

function! fila#process#new(...) abort
  return call(s:Process.new, a:000, s:Process)
endfunction

function! fila#process#start(...) abort
  return call(s:Process.start, a:000, s:Process)
endfunction
