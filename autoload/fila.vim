let s:Config = vital#fila#import('Config')

function! fila#open(...) abort
  let url = a:0 ? a:1 : ''
  let url = empty(url) ? s:smart_url() : url
  let bufname = 'fila:file://' . fnamemodify(url, ':p')
  let options = extend({}, a:0 > 1 ? a:2 : {})
  call fila#viewer#open(bufname, options)
endfunction

function! fila#drawer(...) abort
  let url = a:0 ? a:1 : ''
  let url = empty(url) ? s:smart_url() : url
  let bufname = 'fila:file://' . fnamemodify(url, ':p')
  let options = extend({}, a:0 > 1 ? a:2 : {})
  call fila#drawer#open(bufname, options)
endfunction

function! s:smart_url() abort
  if &buftype !=# 'nofile' && filereadable(expand('%'))
    return simplify(expand('%:p:h'))
  else
    return getcwd()
  endif
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'debug': 1,
      \})

