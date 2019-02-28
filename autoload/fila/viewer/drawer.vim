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
          \.then({ -> s:init() })
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

function! s:init() abort
  let t:fila_drawer_winid = win_getid()
  augroup fila_viewer_drawer_internal
    autocmd! *
    autocmd BufEnter <buffer> call s:BufEnter()
  augroup END
endfunction

function! s:BufEnter() abort
  if winnr('$') isnot# 1
    execute 'vertical resize' g:fila#viewer#drawer#width
    return
  elseif tabpagenr('$') isnot# 1
    close
  elseif !g:fila#viewer#drawer#keep
    quit
  else
    vertical new
    keepjumps wincmd p
    execute 'vertical resize' g:fila#viewer#drawer#width
    keepjumps wincmd p
  endif
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'width': 30,
      \ 'toggle': 0,
      \ 'keep': 0,
      \})
