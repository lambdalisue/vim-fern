function! fern#fri#to#filepath(fri) abort
  if a:fri.scheme !=# 'file'
    throw printf('The "scheme" must be "file" but "%s" has specified', a:fri.scheme)
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
