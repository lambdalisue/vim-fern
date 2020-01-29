function! fern#internal#path#simplify(path) abort
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

function! fern#internal#path#commonpath(paths) abort
  let paths = map(copy(a:paths), { -> fern#internal#path#simplify(v:val) })
  let common = []
  for index in range(min(map(copy(paths), { -> len(v:val) })))
    let term = paths[0][index]
    if empty(filter(paths[1:], { -> v:val[index] !=? term }))
      call add(common, term)
    endif
  endfor
  return common
endfunction

function! fern#internal#path#relative(path, base) abort
  let path = fern#internal#path#simplify(a:path)
  let base = fern#internal#path#simplify(a:base)
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
