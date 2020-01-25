let s:Later = vital#trea#import('Async.Later')

function! trea#message#debug(...) abort
  if !get(g:, 'trea#debug')
    return
  endif
  call s:Later.call(funcref('s:message', ['Comment'] + a:000))
endfunction

function! trea#message#info(...) abort
  call s:Later.call(funcref('s:message', ['None'] + a:000))
endfunction

function! trea#message#title(...) abort
  call s:Later.call(funcref('s:message', ['Title'] + a:000))
endfunction

function! trea#message#error(...) abort
  call s:Later.call(funcref('s:message', ['Error'] + a:000))
endfunction

function! s:message(hl, ...) abort
  try
    execute 'echohl' a:hl
    let m = join(map(copy(a:000), { _, v -> type(v) is# v:t_string ? v : string(v) }))
    for line in split(m, '\r\?\n')
      echomsg '[trea] ' . line
    endfor
  finally
    echohl None
  endtry
endfunction
