function! fern#internal#path#simplify(path) abort
  let terms = s:split(a:path)
  let path = join(s:simplify(terms), '/')
  let prefix = a:path[:0] ==# '/' && path[:2] !=# '../' ? '/' : ''
  return prefix . path
endfunction

function! fern#internal#path#commonpath(paths) abort
  if !empty(filter(copy(a:paths), 'v:val[:0] !=# ''/'''))
    throw printf('fern: path in {paths} must be an absolute path: %s', a:paths)
  endif
  let path = s:commonpath(map(
        \ copy(a:paths),
        \ 's:split(v:val)'
        \))
  return '/' . join(path, '/')
endfunction

function! fern#internal#path#absolute(path, base) abort
  if a:base[:0] !=# '/'
    throw printf('fern: {base} ("%s") must be an absolute path', a:base)
  elseif a:path[:0] ==# '/'
    return a:path
  endif
  let path = s:split(a:path)
  let base = s:split(a:base)
  let abspath = join(s:simplify(base + path), '/')
  if abspath[:2] ==# '../'
    throw printf('fern: {path} (%s) beyonds {base} (%s)', a:path, a:base)
  endif
  return '/' . abspath
endfunction

function! fern#internal#path#relative(path, base) abort
  if a:base[:0] !=# '/'
    throw printf('fern: {base} ("%s") must be an absolute path', a:base)
  elseif a:path[:0] !=# '/'
    return a:path
  endif
  let path = s:split(a:path)
  let base = s:split(a:base)
  return join(s:relative(path, base), '/')
endfunction

function! fern#internal#path#basename(path) abort
  if empty(a:path) || a:path ==# '/'
    return a:path
  endif
  let terms = s:split(a:path)
  return terms[-1]
endfunction

function! fern#internal#path#dirname(path) abort
  if empty(a:path) || a:path ==# '/'
    return a:path
  endif
  let terms = s:split(a:path)[:-2]
  let path = join(s:simplify(terms), '/')
  let prefix = a:path[:0] ==# '/' && path[:2] !=# '../' ? '/' : ''
  return prefix . path
endfunction

function! s:split(path) abort
  return filter(split(a:path, '/'), '!empty(v:val)')
endfunction

function! s:simplify(path) abort
  let result = []
  for term in a:path
    if term ==# '..'
      if empty(result) || result[-1] == '..'
        call insert(result, '..', 0)
      else
        call remove(result, -1)
      endif
    elseif term ==# '.' || empty(term)
      continue
    else
      call add(result, term)
    endif
  endfor
  return result
endfunction

function! s:commonpath(paths) abort
  let paths = map(copy(a:paths), { -> s:simplify(v:val) })
  let common = []
  for index in range(min(map(copy(paths), { -> len(v:val) })))
    let term = paths[0][index]
    if empty(filter(paths[1:], { -> v:val[index] !=? term }))
      call add(common, term)
    endif
  endfor
  return common
endfunction

function! s:relative(path, base) abort
  let path = s:simplify(a:path)
  let base = s:simplify(a:base)
  for index in range(min([len(path), len(base)]))
    if path[0] !=? base[0]
      break
    endif
    call remove(path, 0)
    call remove(base, 0)
  endfor
  let prefix = repeat(['..'], len(base))
  return prefix + path
endfunction
