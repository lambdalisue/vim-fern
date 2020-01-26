let s:Flag = vital#fern#import('App.Flag')

function! fern#command#parse(qargs) abort
  let [opts, args] = s:Flag.parse(s:Flag.split(a:qargs))
  let options = {
        \ 'pop': funcref('s:options_pop', [opts]),
        \ 'drop': funcref('s:options_drop', [opts]),
        \ 'throw_if_dirty': funcref('s:options_throw_if_dirty', [opts]),
        \}
  return [options, args]
endfunction

function! s:options_pop(opts, name, default) abort
  return has_key(a:opts, a:name)
        \ ? remove(a:opts, a:name)
        \ : a:default
endfunction

function! s:options_drop(opts, name) abort
  if has_key(a:opts, a:name)
    call remove(a:opts, a:name)
  endif
endfunction

function! s:options_throw_if_dirty(opts) abort
  if empty(a:opts)
    return
  endif
  let name = keys(a:opts)[0]
  let value = a:opts[name]
  let label = value is# v:true
        \ ? printf('-%s', name)
        \ : printf('-%s=%s', name, value)
  throw printf('unknown option -%s has specified', label)
endfunction
