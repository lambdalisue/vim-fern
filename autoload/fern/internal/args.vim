function! fern#internal#args#split(cmd) abort
  let sq = '''\zs[^'']\+\ze'''
  let dq = '"\zs[^"]\+\ze"'
  let bs = '\%(\\\s\|[^ ''"]\)\+'
  let pp = printf(
        \ '\%%(%s\)*\zs\%%(\s\+\|$\)\ze',
        \ join([sq, dq, bs], '\|')
        \)
  let np = '^\%("\zs.*\ze"\|''\zs.*\ze''\|.*\)$'
  return map(split(a:cmd, pp), { -> matchstr(v:val, np) })
endfunction

function! fern#internal#args#index(args, pattern) abort
  for index in range(len(a:args))
    if a:args[index] =~# a:pattern
      return index
    endif
  endfor
  return -1
endfunction

function! fern#internal#args#set(args, name, value) abort
  let pattern = printf('^-%s\%(=.*\)\?$', a:name)
  let index = fern#internal#args#index(a:args, pattern)
  let value = a:value is# v:true
        \ ? printf('-%s', a:name)
        \ : printf('-%s=%s', a:name, a:value)
  if index is# -1
    call add(a:args, value)
  else
    let a:args[index] = value
  endif
endfunction

function! fern#internal#args#pop(args, name, default) abort
  let pattern = printf('^-%s\%(=.*\)\?$', a:name)
  let index = fern#internal#args#index(a:args, pattern)
  if index is# -1
    return a:default
  else
    let value = remove(a:args, index)
    return value =~# '^-[^=]\+='
          \ ? matchstr(value, '=\zs.*$')
          \ : v:true
  endif
endfunction

function! fern#internal#args#throw_if_dirty(args) abort
  for arg in a:args
    if arg =~# '^-'
      throw printf('unknown option %s has specified', arg)
    endif
  endfor
endfunction
