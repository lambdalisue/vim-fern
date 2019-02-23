let s:StructError = vital#fila#import('App.StructError')

function! fila#error#new(...) abort
  return call(s:StructError.new, a:000, s:StructError)
endfunction

function! fila#error#cause(...) abort
  return call(s:StructError.cause, a:000, s:StructError)
endfunction

function! fila#error#handle(...) abort
  let error = s:norm(a:0 ? a:1 : v:exception)
  if error.exception =~# '^Cancelled'
    echohl Title
    echo '[fila] Cancelled'
    echohl None
  else
    let ms = split(error.exception, "\n")
    if &verbose
      let ms += split(error.throwpoint, "\n")
    endif
    echohl WarningMsg
    for m in ms
      echomsg printf('[fila] %s', m)
    endfor
    echohl None
  endif
endfunction

function! s:norm(exception) abort
  if type(a:exception) is# v:t_dict
    return extend({
          \ 'exception': v:exception,
          \ 'throwpoint': v:throwpoint,
          \}, a:exception)
  elseif type(a:exception) is# v:t_string
    return fila#error#cause(a:exception)
  else
    throw '[fila] exception is not expected type'
  endif
endfunction
