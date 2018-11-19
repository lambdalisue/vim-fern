let s:Lambda = vital#fila#import('Lambda')
let s:Promise = vital#fila#import('Async.Promise')

let s:STATUS_COLLAPSED = 0
let s:STATUS_EXPANDED = 1

function! fila#node#new(key, options) abort
  if type(a:key) isnot# v:t_list
    throw 'fila: "key" must be a list'
  endif
  let text = get(a:key, -1, '')
  let node = extend({
        \ 'text': text,
        \ 'hidden': 0,
        \ 'status': s:STATUS_COLLAPSED,
        \}, a:options)
  let node.key = a:key
  return node
endfunction

function! fila#node#is_hidden(node) abort
  return a:node.hidden ? 1 : 0
endfunction

function! fila#node#is_branch(node) abort
  return has_key(a:node, 'children')
endfunction

function! fila#node#is_expanded(node) abort
  return a:node.status is# s:STATUS_EXPANDED
endfunction

function! fila#node#index(key, nodes) abort
  if type(a:key) isnot# v:t_list
    throw 'fila: "key" must be a list'
  endif
  for index in range(len(a:nodes))
    if a:nodes[index].key == a:key
      return index
    endif
  endfor
  return -1
endfunction

function! fila#node#find(key, nodes) abort
  let index = fila#node#index(a:key, a:nodes)
  return index is# -1 ? v:null : a:nodes[index]
endfunction

function! fila#node#children(node) abort
  if !has_key(a:node, 'children')
    return s:Promise.reject('the node does not have children')
  elseif has_key(a:node, 'children_resolver')
    return a:node.children_resolver
  endif
  let e = { 'parent': a:node }
  let c = type(a:node.children) is# v:t_func
        \ ? a:node.children()
        \ : a:node.children
  let p = (s:Promise.is_promise(c) ? c : s:Promise.resolve(c))
        \.then(s:Lambda.map_f({ v -> extend(v, e) }))
        \.finally({ -> s:Lambda.unlet(a:node, 'children_resolver') })
  let a:node.children_resolver = p
  return p
endfunction

function! fila#node#reload_at(key, nodes, comparator) abort
  let node = fila#node#find(a:key, a:nodes)
  if node is# v:null
    return s:Promise.reject(printf('no node "%s" is found', a:key))
  elseif node.status is# s:STATUS_COLLAPSED
    return s:Promise.resolve(copy(a:nodes))
  endif
  let k = node.key
  let n = len(k) - 1
  let K = n < 0 ? { v -> [] } : { v -> v.key[:n] }
  let outer = s:Promise.resolve(copy(a:nodes))
        \.then(s:Lambda.filter_f({ v -> K(v) != k  }))
  let inner = s:Promise.resolve(copy(a:nodes))
        \.then(s:Lambda.filter_f({ v -> K(v) == k  }))
        \.then(s:Lambda.filter_f({ v -> v.status is# s:STATUS_EXPANDED }))
  let descendants = inner
        \.then({v -> copy(v)})
        \.then(s:Lambda.map_f({ v -> fila#node#children(v) }))
        \.then({ v -> s:Promise.all(v) })
        \.then(s:Lambda.reduce_f({ a, v -> a + v }, []))
  return s:Promise.all([outer, inner, descendants])
        \.then(s:Lambda.reduce_f({ a, v -> a + v }, []))
        \.then({ v -> s:uniq(sort(v, a:comparator)) })
endfunction

function! fila#node#expand_at(key, nodes, comparator) abort
  let node = fila#node#find(a:key, a:nodes)
  if node is# v:null
    return s:Promise.reject(printf('no node "%s" is found', a:key))
  elseif node.status isnot# s:STATUS_COLLAPSED
    return s:Promise.resolve(copy(a:nodes))
  endif
  let p = fila#node#children(node)
        \.then({ v -> s:uniq(sort(v, a:comparator)) })
        \.then({ v -> s:extend(a:key, copy(a:nodes), v) })
  call p.then({ v -> s:Lambda.let(node, 'status', s:STATUS_EXPANDED) })
  return p
endfunction

function! fila#node#collapse_at(key, nodes, comparator) abort
  let node = fila#node#find(a:key, a:nodes)
  if node is# v:null
    return s:Promise.reject(printf('no node "%s" is found', a:key))
  elseif node.status is# s:STATUS_COLLAPSED
    return s:Promise.resolve(copy(a:nodes))
  endif
  let k = node.key
  let n = len(k) - 1
  let K = n < 0 ? { v -> [] } : { v -> v.key[:n] }
  let p = s:Promise.resolve(copy(a:nodes))
        \.then(s:Lambda.filter_f({ v -> v.key == k || K(v) != k  }))
  call p.then({ -> s:Lambda.let(node, 'status', s:STATUS_COLLAPSED) })
  return p
endfunction

function! s:uniq(nodes) abort
  return uniq(a:nodes, { a, b -> a.key != b.key })
endfunction

function! s:extend(key, nodes, new_nodes) abort
  let index = fila#node#index(a:key, a:nodes)
  return index is# -1 ? a:nodes : extend(a:nodes, a:new_nodes, index + 1)
endfunction

let g:fila#node#STATUS_COLLAPSED = s:STATUS_COLLAPSED
let g:fila#node#STATUS_EXPANDED = s:STATUS_EXPANDED
