let s:Promise = vital#trea#import('Async.Promise')
let s:Lambda = vital#trea#import('Lambda')
let s:AsyncLambda = vital#trea#import('Async.Lambda')

let s:STATUS_NONE = 0
let s:STATUS_COLLAPSED = 1
let s:STATUS_EXPANDED = 2

function! trea#internal#node#debug(node) abort
  if a:node is# v:null
    return v:null
  endif
  let meta = extend(copy(a:node), {
        \ '__owner': a:node.__owner is# v:null ? '' : a:node.__owner.label,
        \ '__cache': keys(a:node.__cache),
        \ '__promise': keys(a:node.__promise),
        \})
  let size = max(map(keys(meta), { -> len(v:val) }))
  let text = ""
  for name in sort(keys(meta))
    let prefix = name . ": " . repeat(" ", size - len(name))
    let text .= printf("%s%s\n", prefix, meta[name])
  endfor
  return text
endfunction

function! trea#internal#node#index(key, nodes) abort
  if type(a:key) isnot# v:t_list
    throw 'trea: "key" must be a list'
  endif
  for index in range(len(a:nodes))
    if a:nodes[index].__key == a:key
      return index
    endif
  endfor
  return -1
endfunction

function! trea#internal#node#find(key, nodes) abort
  let index = trea#internal#node#index(a:key, a:nodes)
  return index is# -1 ? v:null : a:nodes[index]
endfunction

function! trea#internal#node#root(url, provider) abort
  return s:new(a:provider.get_node(a:url))
endfunction

function! trea#internal#node#parent(node, provider, token, ...) abort
  let options = extend({
        \ 'cache': 1,
        \}, a:0 ? a:1 : {})
  if has_key(a:node.__cache, 'parent') && options.cache
    return s:Promise.resolve(a:node.__cache.parent)
  elseif has_key(a:node.__promise, 'parent')
    return a:node.__promise.parent
  endif
  let a:node.processing += 1
  let p = a:provider.get_parent(a:node, a:token)
        \.then({ n -> s:new(n, {
        \   '__key': [],
        \   '__owner': v:null,
        \ })
        \})
        \.then({ n -> s:Lambda.pass(n, s:Lambda.let(a:node.__cache, 'parent', n)) })
        \.finally({ -> s:Lambda.let(a:node, 'processing', a:node.processing - 1) })
  let a:node.__promise.parent = p
        \.finally({ -> s:Lambda.unlet(a:node.__promise, 'parent') })
  return p
endfunction

function! trea#internal#node#children(node, provider, token, ...) abort
  let options = extend({
        \ 'cache': 1,
        \}, a:0 ? a:1 : {})
  if a:node.status is# s:STATUS_NONE
    return s:Promise.reject('leaf node does not have children')
  elseif has_key(a:node.__cache, 'children') && options.cache
    return s:AsyncLambda.map(
          \ a:node.__cache.children,
          \ { v -> extend(v, { 'status': v.status > 0 }) },
          \)
  elseif has_key(a:node.__promise, 'children')
    return a:node.__promise.children
  endif
  let a:node.processing += 1
  let p = a:provider.get_children(a:node, a:token)
        \.then(s:AsyncLambda.map_f({ n ->
        \   s:new(n, {
        \     '__key': a:node.__key + [n.name],
        \     '__owner': a:node,
        \   })
        \ }))
        \.then({ v -> s:Lambda.pass(v, s:Lambda.let(a:node.__cache, 'children', v)) })
        \.finally({ -> s:Lambda.let(a:node, 'processing', a:node.processing - 1) })
  let a:node.__promise.children = p
        \.finally({ -> s:Lambda.unlet(a:node.__promise, 'children') })
  return p
endfunction

function! trea#internal#node#expand(node, nodes, provider, comparator, token) abort
  if a:node.status is# s:STATUS_NONE
    " To improve UX, reload owner instead
    return trea#internal#node#reload(
          \ a:node.__owner,
          \ a:nodes,
          \ a:provider,
          \ a:comparator,
          \ a:token,
          \)
  elseif a:node.status is# s:STATUS_EXPANDED
    " To improve UX, reload instead
    return trea#internal#node#reload(
          \ a:node,
          \ a:nodes,
          \ a:provider,
          \ a:comparator,
          \ a:token,
          \)
  elseif has_key(a:node.__promise, 'expand')
    return a:node.__promise.expand
  elseif has_key(a:node, '__promise.collapse')
    return a:node.__promise.collapse
  endif
  let a:node.processing += 1
  let p = trea#internal#node#children(a:node, a:provider, a:token)
        \.then({ v -> s:sort(v, a:comparator) })
        \.then({ v -> s:extend(a:node.__key, a:nodes, v) })
        \.finally({ -> s:Lambda.let(a:node, 'processing', a:node.processing - 1) })
  call p.then({ -> s:Lambda.let(a:node, 'status', s:STATUS_EXPANDED) })
  let a:node.__promise.expand = p
        \.finally({ -> s:Lambda.unlet(a:node.__promise, 'expand') })
  return p
endfunction

function! trea#internal#node#collapse(node, nodes, provider, comparator, token) abort
  if a:node.__owner is# v:null
    " To improve UX, root node should NOT be collapsed and reload instead.
    return trea#internal#node#reload(
          \ a:node,
          \ a:nodes,
          \ a:provider,
          \ a:comparator,
          \ a:token,
          \)
  elseif a:node.status isnot# s:STATUS_EXPANDED
    " To improve UX, collapse a owner node instead
    return trea#internal#node#collapse(
          \ a:node.__owner,
          \ a:nodes,
          \ a:provider,
          \ a:comparator,
          \ a:token,
          \)
  elseif has_key(a:node.__promise, 'expand')
    return a:node.__promise.expand
  elseif has_key(a:node, '__promise.collapse')
    return a:node.__promise.collapse
  endif
  let k = a:node.__key
  let n = len(k) - 1
  let K = n < 0 ? { v -> [] } : { v -> v.__key[:n] }
  let a:node.processing += 1
  let p = s:Promise.resolve(a:nodes)
        \.then(s:AsyncLambda.filter_f({ v -> v.__key == k || K(v) != k  }))
        \.finally({ -> s:Lambda.let(a:node, 'processing', a:node.processing - 1) })
  call p.then({ -> s:Lambda.let(a:node, 'status', s:STATUS_COLLAPSED) })
  let a:node.__promise.collapse = p
        \.finally({ -> s:Lambda.unlet(a:node.__promise, 'collapse') })
  return p
endfunction

function! trea#internal#node#reload(node, nodes, provider, comparator, token) abort
  if a:node.status is# s:STATUS_NONE || a:node.status is# s:STATUS_COLLAPSED
    return s:Promise.resolve(copy(a:nodes))
  elseif has_key(a:node.__promise, 'expand')
    return a:node.__promise.expand
  elseif has_key(a:node.__promise, 'collapse')
    return a:node.__promise.collapse
  endif
  let k = a:node.__key
  let n = len(k) - 1
  let K = n < 0 ? { v -> [] } : { v -> v.__key[:n] }
  let outer = s:Promise.resolve(copy(a:nodes))
        \.then(s:AsyncLambda.filter_f({ v -> K(v) != k  }))
  let inner = s:Promise.resolve(copy(a:nodes))
        \.then(s:AsyncLambda.filter_f({ v -> K(v) == k  }))
        \.then(s:AsyncLambda.filter_f({ v -> v.status is# s:STATUS_EXPANDED }))
  let descendants = inner
        \.then({v -> copy(v)})
        \.then(s:AsyncLambda.map_f({ v ->
        \   trea#internal#node#children(v, a:provider, a:token, { 'cache': 0 }).then({ children ->
        \     s:Lambda.if(v.status is# s:STATUS_EXPANDED, { -> children }, { -> []})
        \   })
        \ }))
        \.then({ v -> s:Promise.all(v) })
        \.then(s:AsyncLambda.reduce_f({ a, v -> a + v }, []))
  let a:node.processing += 1
  return s:Promise.all([outer, inner, descendants])
        \.then(s:AsyncLambda.reduce_f({ a, v -> a + v }, []))
        \.then({ v -> s:sort(v, a:comparator) })
        \.then({ v -> s:uniq(v) })
        \.finally({ -> s:Lambda.let(a:node, 'processing', a:node.processing - 1) })
endfunction

function! trea#internal#node#reveal(key, nodes, provider, comparator, token) abort
  if a:key == a:nodes[0].__key
    return s:Promise.resolve(a:nodes)
  endif
  let n = len(a:nodes[0].__key) - 1
  let k = copy(a:key)
  let ks = []
  while len(k) - 1 > n
    call add(ks, copy(k))
    call remove(k, -1)
  endwhile
  return s:expand_recursively(ks, a:nodes, a:provider, a:comparator, a:token)
endfunction

function! s:new(node, ...) abort
  let label = get(a:node, 'label', a:node.name)
  let node = extend(a:node, {
        \ 'label': label,
        \ 'hidden': get(a:node, 'hidden', 0),
        \ 'bufname': get(a:node, 'bufname', v:null),
        \ 'processing': 0,
        \ '__key': [],
        \ '__owner': v:null,
        \ '__cache': {},
        \ '__promise': {},
        \})
  let node = extend(node, a:0 ? a:1 : {})
  return node
endfunction

function! s:uniq(nodes) abort
  return s:Promise.resolve(uniq(a:nodes, { a, b -> a.__key != b.__key }))
endfunction

function! s:sort(nodes, compare) abort
  return s:Promise.resolve(sort(a:nodes, a:compare))
endfunction

function! s:extend(key, nodes, new_nodes) abort
  let index = trea#internal#node#index(a:key, a:nodes)
  return index is# -1 ? a:nodes : extend(a:nodes, a:new_nodes, index + 1)
endfunction

function! s:expand_recursively(keys, nodes, provider, comparator, token) abort
  let node = trea#internal#node#find(a:keys[-1], a:nodes)
  if node is# v:null
    return s:Promise.reject(printf(
          \ 'no node %s exists',
          \ a:keys[-1],
          \))
  endif
  return trea#internal#node#expand(node, a:nodes, a:provider, a:comparator, a:token)
        \.then({ v -> s:Lambda.pass(v, remove(a:keys, -1)) })
        \.then({ v -> s:Lambda.if(
        \   len(a:keys) > 1,
        \   { -> s:expand_recursively(a:keys, v, a:provider, a:comparator, a:token) },
        \   { -> v },
        \ )})
endfunction

let g:trea#internal#node#STATUS_NONE = s:STATUS_NONE
let g:trea#internal#node#STATUS_COLLAPSED = s:STATUS_COLLAPSED
let g:trea#internal#node#STATUS_EXPANDED = s:STATUS_EXPANDED
