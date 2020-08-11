function! fern#fri#from#filepath(path) abort
  if !fern#internal#filepath#is_absolute(a:path)
    throw printf('The "path" must be an absolute path but "%s" has specfied', a:path)
  endif
  let path = fern#internal#filepath#to_slash(a:path)
  return fern#fri#from#path(path)
endfunction

function! fern#fri#from#path(path) abort
  if a:path[:0] !=# '/'
    throw printf('The "path" must start from "/" but "%s" has specfied', a:path)
  endif
  let path = fern#internal#path#simplify(a:path)
  let path = fern#fri#encode(path)
  let path = fern#fri#encode(path, '[#\[\]; ]')
  " Remove leading '/' while 'path' sub-component does NOT include it.
  return fern#fri#new({
        \ 'scheme': 'file',
        \ 'path': path[1:],
        \})
endfunction
