let s:Config = vital#fila#import('Config')
let s:Promise = vital#fila#import('Async.Promise')

function! fila#viewer#drawer#is_drawer(winid) abort
  return a:winid is# s:get_winid()
endfunction

function! fila#viewer#drawer#is_opened() abort
  return !empty(getwininfo(s:get_winid()))
endfunction

function! fila#viewer#drawer#open(bufname, options) abort
  let options = extend({
        \ 'width': g:fila#viewer#drawer#width,
        \ 'toggle': g:fila#viewer#drawer#toggle,
        \}, a:options)
  if fila#viewer#drawer#is_opened()
    if options.toggle
      call fila#viewer#drawer#close()
    else
      call fila#viewer#drawer#focus()
    endif
    return s:Promise.resolve()
  else
    return fila#viewer#open(a:bufname, {
          \ 'opener': printf('topleft %dvsplit', options.width),
          \ 'cmdarg': '+setlocal\ winfixwidth',
          \})
          \.then({ -> s:set_winid(win_getid()) })
          \.catch({ e -> fila#lib#error#handle(e) })
  endif
endfunction

function! fila#viewer#drawer#focus() abort
  if !fila#viewer#drawer#is_opened()
    return
  endif
  call win_gotoid(s:get_winid())
endfunction

function! fila#viewer#drawer#close() abort
  if !fila#viewer#drawer#is_opened()
    return
  endif
  execute printf('%dclose!', win_id2win(s:get_winid()))
endfunction

function! fila#viewer#drawer#quit() abort
  if !fila#viewer#drawer#is_opened()
    return
  endif
  execute printf('%dquit!', win_id2win(s:get_winid()))
endfunction

function! s:get_winid() abort
  return get(t:, 'fila_drawer_winid', -1)
endfunction

function! s:set_winid(winid) abort
  let t:fila_drawer_winid = a:winid
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'width': 30,
      \ 'toggle': 0,
      \})
