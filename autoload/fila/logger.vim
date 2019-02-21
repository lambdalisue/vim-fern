let s:StructLogger = vital#fila#import('App.StructLogger')

function! fila#logger#start(...) abort
  return call(s:StructLogger.start, a:000, s:StructLogger)
endfunction

function! fila#logger#stop(...) abort
  return call(s:StructLogger.stop, a:000, s:StructLogger)
endfunction

function! fila#logger#debug(...) abort
  return call(s:StructLogger.debug, a:000, s:StructLogger)
endfunction

function! fila#logger#info(...) abort
  return call(s:StructLogger.info, a:000, s:StructLogger)
endfunction

function! fila#logger#warning(...) abort
  return call(s:StructLogger.warning, a:000, s:StructLogger)
endfunction

function! fila#logger#error(...) abort
  return call(s:StructLogger.error, a:000, s:StructLogger)
endfunction

function! fila#logger#critical(...) abort
  return call(s:StructLogger.critical, a:000, s:StructLogger)
endfunction

function! fila#logger#open(...) abort
  let opener = a:0 ? a:1 : 'edit'
  let filename = s:StructLogger.get_logfile()
  if filename is# v:null
    echohl WarningMsg
    echo 'Start logging by fila#logger#start() first.'
    echohl None
    return
  endif
  execute printf('%s %s', opener, filename)
  setlocal nomodifiable readonly autoread
endfunction

call fila#logger#start(expand('~/fila.jsonl'), { 'fresh': 1 })
