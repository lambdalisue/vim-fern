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
        \ 'keep': g:fila#viewer#drawer#keep,
        \ 'width': g:fila#viewer#drawer#width,
        \ 'toggle': g:fila#viewer#drawer#toggle,
        \}, a:options)
  if fila#viewer#drawer#is_opened()
    if options.toggle
      call fila#viewer#drawer#close()
    else
      call fila#viewer#drawer#focus(options)
    endif
    return s:Promise.resolve()
  else
    return fila#viewer#open(a:bufname, {
          \ 'opener': printf('topleft %dvsplit', options.width),
          \ 'cmdarg': '+setlocal\ winfixwidth',
          \})
          \.then({ -> s:init(options) })
          \.catch({ e -> fila#lib#error#handle(e) })
  endif
endfunction

function! fila#viewer#drawer#focus(...) abort
  if !fila#viewer#drawer#is_opened()
    return
  endif
  let t:fila_drawer_options = get(a:000, 0, t:fila_drawer_options)
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

function! s:init(options) abort
  let t:fila_drawer_winid = win_getid()
  let t:fila_drawer_options = a:options
  augroup fila_viewer_drawer_internal
    autocmd! *
    autocmd BufEnter <buffer> call s:BufEnter()
  augroup END
endfunction

function! s:BufEnter() abort
  if winnr('$') isnot# 1
    execute 'vertical resize' t:fila_drawer_options.width
    return
  elseif tabpagenr('$') isnot# 1
    close
  elseif !t:fila_drawer_options.keep
    quit
  else
    vertical new
    keepjumps wincmd p
    execute 'vertical resize' t:fila_drawer_options.width
    keepjumps wincmd p
  endif
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'keep': 0,
      \ 'width': 30,
      \ 'toggle': 0,
      \})
