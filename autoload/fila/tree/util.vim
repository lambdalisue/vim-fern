let s:Promise = vital#fila#import('Async.Promise')
let s:Lambda = vital#fila#import('Lambda')

let s:STATUS_NONE      = g:fila#tree#item#STATUS_NONE
let s:STATUS_COLLAPSED = g:fila#tree#item#STATUS_COLLAPSED
let s:STATUS_EXPANDED  = g:fila#tree#item#STATUS_EXPANDED

function! fila#tree#util#_sort(items, comparator) abort
  return sort(a:items, a:comparator.compare)
endfunction

function! fila#tree#util#_index(resource_uri, items) abort
  for index in range(len(a:items))
    if a:items[index].resource_uri ==# a:resource_uri
      return index
    endif
  endfor
  return -1
endfunction

function! fila#tree#util#_guess_parent(resource_uri, items) abort
  if empty(a:resource_uri)
    return v:null
  endif
  let resource_uri = join(split(a:resource_uri, '/')[:-2], '/')
  return s:find(resource_uri, a:items)
endfunction

function! fila#tree#util#_parent(resource_uri, provider) abort
  return s:ensure_promise(a:provider.parent(a:resource_uri))
        \.then({ v -> a:provider.item(v) })
endfunction

function! fila#tree#util#_children(resource_uri, provider) abort
  return s:children(a:resource_uri, a:provider)
endfunction

function! fila#tree#util#_reload(resource_uri, items, provider) abort
  let item = s:find(a:resource_uri, a:items)
  if item.status isnot# s:STATUS_EXPANDED
    return s:Promise.resolve(copy(a:items))
  endif
  let n = len(a:resource_uri)
  let K = { v -> v.resource_uri ==# a:resource_uri || v.resource_uri[:n] ==# a:resource_uri . '/' }
  let outer = s:Promise.resolve(copy(a:items))
        \.then(s:Lambda.filter_f({ v -> !K(v) }))
  let inner = s:Promise.resolve(copy(a:items))
        \.then(s:Lambda.filter_f({ v -> K(v) }))
        \.then(s:Lambda.filter_f({ v -> v.status is# s:STATUS_EXPANDED }))
  let descendants = inner
        \.then({ v -> copy(v) })
        \.then(s:Lambda.map_f({ v -> s:children(v.resource_uri, a:provider) }))
        \.then({ v -> s:Promise.all(v) })
        \.then(s:Lambda.reduce_f({ a, v -> a + v }, []))
  return s:Promise.all([outer, inner, descendants])
        \.then(s:Lambda.reduce_f({ a, v -> a + v }, []))
        \.then({ v -> s:uniq(v) })
endfunction

function! fila#tree#util#_expand(resource_uri, items, provider) abort
  let item = s:find(a:resource_uri, a:items)
  if item.status is# s:STATUS_EXPANDED
    return s:Promise.resolve(copy(a:items))
  endif
  let p = s:children(a:resource_uri, a:provider)
        \.then({ v -> extend(copy(a:items), v) })
        \.then({ v -> s:uniq(v) })
  call p.then({ v -> s:Lambda.let(item, 'status', s:STATUS_EXPANDED) })
  return p
endfunction

function! fila#tree#util#_collapse(resource_uri, items, provider) abort
  let item = s:find(a:resource_uri, a:items)
  if item.status is# s:STATUS_COLLAPSED
    return s:Promise.resolve(copy(a:items))
  endif
  let n = len(a:resource_uri)
  let K = { v -> v ==# a:resource_uri || v[:n] !=# a:resource_uri . '/' }
  let p = s:Promise.resolve(copy(a:items))
        \.then(s:Lambda.filter_f({ v -> K(v.resource_uri) }))
        \.then({ v -> s:uniq(v) })
  call p.then({ -> s:Lambda.let(item, 'status', s:STATUS_COLLAPSED) })
  return p
endfunction

function! s:ensure_promise(p) abort
  return s:Promise.is_promise(a:p) ? a:p : s:Promise.resolve(a:p)
endfunction

function! s:uniq(items) abort
  return uniq(a:items, { a, b -> a.resource_uri !=# b.resource_uri })
endfunction

function! s:find(resource_uri, items) abort
  for item in a:items
    if item.resource_uri ==# a:resource_uri
      return item
    endif
  endfor
  throw fila#error#new('no such resource exist', {
        \ 'resource_uri': a:resource_uri,
        \})
endfunction

function! s:children(resource_uri, provider) abort
  return s:ensure_promise(a:provider.children(a:resource_uri))
        \.then(s:Lambda.map_f({ v -> a:provider.item(v) }))
endfunction
