let s:Config = vital#fila#import('Config')
let s:Flag = vital#fila#import('App.Flag')

function! fila#command(mods, qargs) abort
  let [options, remains] = s:Flag.parse(s:Flag.split(a:qargs))
  call s:open(s:bufname(remains), extend(options, {
        \   'mods': a:mods,
        \ }))
        \.then({ -> s:reveal(expand(get(options, 'reveal', ''))) })
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:open(bufname, options) abort
  if get(a:options, 'drawer')
    return fila#viewer#drawer#open(a:bufname, a:options)
  else
    return fila#viewer#open(a:bufname, a:options)
  endif
endfunction

function! s:bufname(args) abort
  let url = len(a:args) ? remove(a:args, 0) : s:smart_url()
  let url = url =~# '^[^:]\+://' ? url : 'file://' . fnamemodify(url, ':p')
  return 'fila://' . fnamemodify(url, ':gs?\\?/?')
endfunction

function! s:smart_url() abort
  if &buftype !=# 'nofile' && filereadable(expand('%'))
    return simplify(expand('%:p:h'))
  else
    return getcwd()
  endif
endfunction

function! s:reveal(path) abort
  if empty(a:path)
    return
  endif
  let winid = win_getid()
  let helper = fila#node#helper#new()
  let key = helper.keyof(a:path)
  call helper.reveal(key)
        \.then({ h -> h.redraw() })
        \.then({ h -> h.cursor(winid, key, 0, 1) })
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'debug': 1,
      \})

