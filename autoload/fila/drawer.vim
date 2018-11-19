function! fila#drawer#is_drawer(winid) abort
  return a:winid is# s:get_winid()
endfunction

function! fila#drawer#is_opened() abort
  return !empty(getwininfo(s:get_winid()))
endfunction

function! fila#drawer#open(bufname, options) abort
  let options = extend({
        \ 'width': 30,
        \ 'toggle': 0,
        \}, a:options)
  if fila#drawer#is_opened()
    if options.toggle
      call fila#drawer#close()
    else
      call fila#drawer#focus()
    endif
  else
    call fila#buffer#open(a:bufname, {
          \ 'opener': printf('topleft %dvsplit', options.width),
          \ 'cmdarg': '+setlocal\ winfixwidth',
          \})
          \.then({ c -> s:set_winid(bufwinid(c.bufnr)) })
          \.catch({ e -> fila#error#handle(e) })
  endif
endfunction

function! fila#drawer#focus() abort
  if !fila#drawer#is_opened()
    return
  endif
  call win_gotoid(s:get_winid())
endfunction

function! fila#drawer#close() abort
  if !fila#drawer#is_opened()
    return
  endif
  execute printf('%dclose!', s:get_winid())
endfunction

function! fila#drawer#quit() abort
  if !fila#drawer#is_opened()
    return
  endif
  execute printf('%quit!', s:get_winid())
endfunction

function! s:get_winid() abort
  return get(t:, 'fila_drawer_winid', -1)
endfunction

function! s:set_winid(winid) abort
  let t:fila_drawer_winid = a:winid
endfunction

