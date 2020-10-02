function! fern#fri#to#filepath(fri) abort
  if a:fri.scheme !=# 'file'
    throw printf('The "scheme" must be "file" but "%s" has specified', a:fri.scheme)
  endif
  if !empty(a:fri.authority) && fern#internal#filepath#is_unc_compat()
    return s:to_uncpath(a:fri)
  endif
  let path = fern#fri#to#path(a:fri)
  let path = fern#internal#filepath#from_slash(path)
  return path
endfunction

function! fern#fri#to#path(fri) abort
  let path = '/' . a:fri.path
  let path = fern#fri#decode(path)
  return path
endfunction

function! fern#fri#to#uncpath(fri) abort
  if !fern#internal#filepath#is_unc_compat()
    throw printf('The system does not support UNC path')
  endif
  if a:fri.scheme !=# 'file'
    throw printf('The "scheme" must be "file" but "%s" has specified', a:fri.scheme)
  endif
  if empty(a:fri.authority)
    throw printf('The "authority" must be non-empty')
  endif
  return s:to_uncpath(a:fri)
endfunction

function! s:to_uncpath(fri) abort
  let path = fern#fri#decode(a:fri.path)
  let path = fern#internal#filepath#from_slash(path)
  let res = printf('\\%s\%s', a:fri.authority, path)
  return res
endfunction
