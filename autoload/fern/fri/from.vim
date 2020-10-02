function! fern#fri#from#filepath(path) abort
  if !fern#internal#filepath#is_absolute(a:path)
    throw printf('The "path" must be an absolute path but "%s" has specfied', a:path)
  endif
  if fern#internal#filepath#is_uncpath(a:path)
    return s:from_uncpath(a:path)
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

function! fern#fri#from#uncpath(path) abort
  if !fern#internal#filepath#is_uncpath(a:path)
    throw printf('The "path" must be an UNC path but "%s" has specfied', a:path)
  endif
  return s:from_uncpath(a:path)
endfunction

function! s:from_uncpath(path) abort
  let terms = filter(split(a:path[2:], '\'), { -> !empty(v:val) })
  let path = join(terms[1:], '/')
  let fri = fern#fri#from#path('/' . path)
  let fri.authority = terms[0]
  return fri
endfunction
