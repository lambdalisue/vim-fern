let s:StructLogger = vital#fila#import('App.StructLogger')

function! fila#lib#logger#start(...) abort
  return call(s:StructLogger.start, a:000, s:StructLogger)
endfunction

function! fila#lib#logger#stop(...) abort
  return call(s:StructLogger.stop, a:000, s:StructLogger)
endfunction

function! fila#lib#logger#debug(...) abort
  return call(s:StructLogger.debug, a:000, s:StructLogger)
endfunction

function! fila#lib#logger#info(...) abort
  return call(s:StructLogger.info, a:000, s:StructLogger)
endfunction

function! fila#lib#logger#warning(...) abort
  return call(s:StructLogger.warning, a:000, s:StructLogger)
endfunction

function! fila#lib#logger#error(...) abort
  return call(s:StructLogger.error, a:000, s:StructLogger)
endfunction

function! fila#lib#logger#critical(...) abort
  return call(s:StructLogger.critical, a:000, s:StructLogger)
endfunction

function! fila#lib#logger#open(...) abort
  let opener = a:0 ? a:1 : 'edit'
  let filename = s:StructLogger.get_logfile()
  if filename is# v:null
    echohl WarningMsg
    echo 'Start logging by fila#lib#logger#start() first.'
    echohl None
    return
  endif
  execute printf('%s %s', opener, filename)
  setlocal nomodifiable readonly autoread
endfunction
