let s:Config = vital#fila#import('Config')
let s:Flag = vital#fila#import('App.Flag')

function! fila#command(mods, qargs) abort
  let [options, remains] = s:Flag.parse(s:Flag.split(a:qargs))
  let bufname = s:init_bufname(remains)
  let options.mods = a:mods
  if get(options, 'drawer')
    return fila#viewer#drawer#open(bufname, options)
  else
    return fila#viewer#open(bufname, options)
  endif
endfunction

function! s:init_bufname(args) abort
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

call s:Config.config(expand('<sfile>:p'), {
      \ 'debug': 1,
      \})

