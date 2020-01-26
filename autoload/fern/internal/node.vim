let s:Promise = vital#fern#import('Async.Promise')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')

let s:STATUS_NONE = 0
let s:STATUS_COLLAPSED = 1
let s:STATUS_EXPANDED = 2

function! fern#internal#node#debug(node) abort
  if a:node is# v:null
    return v:null
  endif
  let meta = extend(copy(a:node), {
        \ '__owner': a:node.__owner is# v:null ? '' : a:node.__owner.label,
        \ 'concealed': keys(a:node.concealed),
        \})
  let size = max(map(keys(meta), { -> len(v:val) }))
  let text = ""
  for name in sort(keys(meta))
    let prefix = name . ": " . repeat(" ", size - len(name))
    let text .= printf("%s%s\n", prefix, meta[name])
  endfor
  return text
endfunction

function! fern#internal#node#process(node) abort
  let a:node.processing += 1
  return { -> s:Lambda.let(a:node, 'processing', a:node.processing - 1) }
endfunction

function! fern#internal#node#index(key, nodes) abort
  if type(a:key) isnot# v:t_list
    throw 'fern: "key" must be a list'
  endif
  for index in range(len(a:nodes))
    if a:nodes[index].__key == a:key
      return index
    endif
  endfor
  return -1
endfunction

function! fern#internal#node#find(key, nodes) abort
  let index = fern#internal#node#index(a:key, a:nodes)
  return index is# -1 ? v:null : a:nodes[index]
endfunction

function! fern#internal#node#root(url, provider) abort
  return s:new(a:provider.get_node(a:url))
endfunction

function! fern#internal#node#parent(node, provider, token, ...) abort
  let options = extend({
        \ 'cache': 1,
        \}, a:0 ? a:1 : {})
  if has_key(a:node.concealed, '__cache_parent') && options.cache
    return s:Promise.resolve(a:node.concealed.__cache_parent)
  elseif has_key(a:node.concealed, '__promise_parent')
    return a:node.concealed.__promise_parent
  endif
  let Done = fern#internal#node#process(a:node)
  let p = a:provider.get_parent(a:node, a:token)
        \.then({ n -> s:new(n, {
        \   '__key': [],
        \   '__owner': v:null,
        \ })
        \})
        \.then({ n -> s:Lambda.pass(n, s:Lambda.let(a:node.concealed, '__cache_parent', n)) })
        \.finally({ -> Done() })
  let a:node.concealed.__promise_parent = p
        \.finally({ -> s:Lambda.unlet(a:node.concealed, '__promise_parent') })
  return p
endfunction

function! fern#internal#node#children(node, provider, token, ...) abort
  let options = extend({
        \ 'cache': 1,
        \}, a:0 ? a:1 : {})
  if a:node.status is# s:STATUS_NONE
    return s:Promise.reject('leaf node does not have children')
  elseif has_key(a:node.concealed, '__cache_children') && options.cache
    return s:AsyncLambda.map(
          \ a:node.concealed.__cache_children,
          \ { v -> extend(v, { 'status': v.status > 0 }) },
          \)
  elseif has_key(a:node.concealed, '__promise_children')
    return a:node.concealed.__promise_children
  endif
  let Done = fern#internal#node#process(a:node)
  let p = a:provider.get_children(a:node, a:token)
        \.then(s:AsyncLambda.map_f({ n ->
        \   s:new(n, {
        \     '__key': a:node.__key + [n.name],
        \     '__owner': a:node,
        \   })
        \ }))
        \.then({ v -> s:Lambda.pass(v, s:Lambda.let(a:node.concealed, '__cache_children', v)) })
        \.finally({ -> Done() })
  let a:node.concealed.__promise_children = p
        \.finally({ -> s:Lambda.unlet(a:node.concealed, '__promise_children') })
  return p
endfunction

function! fern#internal#node#expand(node, nodes, provider, comparator, token) abort
  if a:node.status is# s:STATUS_NONE
    " To improve UX, reload owner instead
    return fern#internal#node#reload(
          \ a:node.__owner,
          \ a:nodes,
          \ a:provider,
          \ a:comparator,
          \ a:token,
          \)
  elseif a:node.status is# s:STATUS_EXPANDED
    " To improve UX, reload instead
    return fern#internal#node#reload(
          \ a:node,
          \ a:nodes,
          \ a:provider,
          \ a:comparator,
          \ a:token,
          \)
  elseif has_key(a:node.concealed, '__promise_expand')
    return a:node.concealed.__promise_expand
  elseif has_key(a:node, 'concealed.__promise_collapse')
    return a:node.concealed.__promise_collapse
  endif
  let Done = fern#internal#node#process(a:node)
  let p = fern#internal#node#children(a:node, a:provider, a:token)
        \.then({ v -> s:sort(v, a:comparator) })
        \.then({ v -> s:extend(a:node.__key, a:nodes, v) })
        \.finally({ -> Done() })
  call p.then({ -> s:Lambda.let(a:node, 'status', s:STATUS_EXPANDED) })
  let a:node.concealed.__promise_expand = p
        \.finally({ -> s:Lambda.unlet(a:node.concealed, '__promise_expand') })
  return p
endfunction

function! fern#internal#node#collapse(node, nodes, provider, comparator, token) abort
  if a:node.__owner is# v:null
    " To improve UX, root node should NOT be collapsed and reload instead.
    return fern#internal#node#reload(
          \ a:node,
          \ a:nodes,
          \ a:provider,
          \ a:comparator,
          \ a:token,
          \)
  elseif a:node.status isnot# s:STATUS_EXPANDED
    " To improve UX, collapse a owner node instead
    return fern#internal#node#collapse(
          \ a:node.__owner,
          \ a:nodes,
          \ a:provider,
          \ a:comparator,
          \ a:token,
          \)
  elseif has_key(a:node.concealed, '__promise_expand')
    return a:node.concealed.__promise_expand
  elseif has_key(a:node, 'concealed.__promise_collapse')
    return a:node.concealed.__promise_collapse
  endif
  let k = a:node.__key
  let n = len(k) - 1
  let K = n < 0 ? { v -> [] } : { v -> v.__key[:n] }
  let Done = fern#internal#node#process(a:node)
  let p = s:Promise.resolve(a:nodes)
        \.then(s:AsyncLambda.filter_f({ v -> v.__key == k || K(v) != k  }))
        \.finally({ -> Done() })
  call p.then({ -> s:Lambda.let(a:node, 'status', s:STATUS_COLLAPSED) })
  let a:node.concealed.__promise_collapse = p
        \.finally({ -> s:Lambda.unlet(a:node.concealed, '__promise_collapse') })
  return p
endfunction

function! fern#internal#node#reload(node, nodes, provider, comparator, token) abort
  if a:node.status is# s:STATUS_NONE || a:node.status is# s:STATUS_COLLAPSED
    return s:Promise.resolve(copy(a:nodes))
  elseif has_key(a:node.concealed, '__promise_expand')
    return a:node.concealed.__promise_expand
  elseif has_key(a:node.concealed, '__promise_collapse')
    return a:node.concealed.__promise_collapse
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
        \   fern#internal#node#children(v, a:provider, a:token, { 'cache': 0 }).then({ children ->
        \     s:Lambda.if(v.status is# s:STATUS_EXPANDED, { -> children }, { -> []})
        \   })
        \ }))
        \.then({ v -> s:Promise.all(v) })
        \.then(s:AsyncLambda.reduce_f({ a, v -> a + v }, []))
  let Done = fern#internal#node#process(a:node)
  return s:Promise.all([outer, inner, descendants])
        \.then(s:AsyncLambda.reduce_f({ a, v -> a + v }, []))
        \.then({ v -> s:sort(v, a:comparator) })
        \.then({ v -> s:uniq(v) })
        \.finally({ -> Done() })
endfunction

function! fern#internal#node#reveal(key, nodes, provider, comparator, token) abort
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
        \ 'concealed': get(a:node, 'concealed', {}),
        \ 'processing': 0,
        \ '__key': [],
        \ '__owner': v:null,
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
  let index = fern#internal#node#index(a:key, a:nodes)
  return index is# -1 ? a:nodes : extend(a:nodes, a:new_nodes, index + 1)
endfunction

function! s:expand_recursively(keys, nodes, provider, comparator, token) abort
  let node = fern#internal#node#find(a:keys[-1], a:nodes)
  if node is# v:null
    return s:Promise.resolve(a:nodes)
  endif
  return fern#internal#node#expand(node, a:nodes, a:provider, a:comparator, a:token)
        \.then({ v -> s:Lambda.pass(v, remove(a:keys, -1)) })
        \.then({ v -> s:Lambda.if(
        \   len(a:keys) > 1,
        \   { -> s:expand_recursively(a:keys, v, a:provider, a:comparator, a:token) },
        \   { -> v },
        \ )})
endfunction

let g:fern#internal#node#STATUS_NONE = s:STATUS_NONE
let g:fern#internal#node#STATUS_COLLAPSED = s:STATUS_COLLAPSED
let g:fern#internal#node#STATUS_EXPANDED = s:STATUS_EXPANDED
