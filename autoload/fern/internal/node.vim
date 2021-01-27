let s:Promise = vital#fern#import('Async.Promise')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')

let s:STATUS_NONE = g:fern#STATUS_NONE
let s:STATUS_COLLAPSED = g:fern#STATUS_COLLAPSED
let s:STATUS_EXPANDED = g:fern#STATUS_EXPANDED

function! fern#internal#node#debug(node) abort
  if a:node is# v:null
    return v:null
  endif
  let meta = extend(copy(a:node), {
        \ '__owner': a:node.__owner is# v:null ? '' : a:node.__owner.label,
        \ 'concealed': keys(a:node.concealed),
        \})
  let size = max(map(keys(meta), { -> len(v:val) }))
  let text = ''
  for name in sort(keys(meta))
    let prefix = name . ': ' . repeat(' ', size - len(name))
    let text .= printf("%s%s\n", prefix, meta[name])
  endfor
  return text
endfunction

function! fern#internal#node#process(node) abort
  let a:node.__processing += 1
  return { -> s:Lambda.let(a:node, '__processing', a:node.__processing - 1) }
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
  return s:new(a:provider.get_root(a:url))
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
  let l:Profile = fern#profile#start('fern#internal#node#parent')
  let l:Done = fern#internal#node#process(a:node)
  let p = a:provider.get_parent(a:node, a:token)
        \.then({ n -> s:new(n, {
        \   '__key': [],
        \   '__owner': v:null,
        \ })
        \})
        \.then({ n -> s:Lambda.pass(n, s:Lambda.let(a:node.concealed, '__cache_parent', n)) })
        \.finally({ -> Done() })
        \.finally({ -> Profile() })
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
  let l:Profile = fern#profile#start('fern#internal#node#children')
  let l:Done = fern#internal#node#process(a:node)
  let p = a:provider.get_children(a:node, a:token)
        \.then(s:AsyncLambda.map_f({ n ->
        \   s:new(n, {
        \     '__key': a:node.__key + [n.name],
        \     '__owner': a:node,
        \   })
        \ }))
        \.then({ v -> s:Lambda.pass(v, s:Lambda.let(a:node.concealed, '__cache_children', v)) })
        \.finally({ -> Done() })
        \.finally({ -> Profile() })
  let a:node.concealed.__promise_children = p
        \.finally({ -> s:Lambda.unlet(a:node.concealed, '__promise_children') })
  return p
endfunction

function! fern#internal#node#expand(node, nodes, provider, comparator, token) abort
  if a:node.status is# s:STATUS_NONE
    return s:Promise.reject('cannot expand leaf node')
  elseif a:node.status is# s:STATUS_EXPANDED
    return s:Promise.resolve(a:nodes)
  elseif has_key(a:node.concealed, '__promise_expand')
    return a:node.concealed.__promise_expand
  elseif has_key(a:node, 'concealed.__promise_collapse')
    return a:node.concealed.__promise_collapse
  endif
  let l:Profile = fern#profile#start('fern#internal#node#expand')
  let l:Done = fern#internal#node#process(a:node)
  let p = fern#internal#node#children(a:node, a:provider, a:token)
        \.finally({ -> Profile('children') })
        \.then({ v -> s:sort(v, a:comparator.compare) })
        \.finally({ -> Profile('sort') })
        \.then({ v -> s:extend(a:node.__key, a:nodes, v) })
        \.finally({ -> Profile('extend') })
        \.finally({ -> Done() })
        \.finally({ -> Profile() })
  call p.then({ -> s:Lambda.let(a:node, 'status', s:STATUS_EXPANDED) })
  let a:node.concealed.__promise_expand = p
        \.finally({ -> s:Lambda.unlet(a:node.concealed, '__promise_expand') })
  return p
endfunction

function! fern#internal#node#collapse(node, nodes, provider, comparator, token) abort
  if a:node.status is# s:STATUS_NONE
    return s:Promise.reject('cannot collapse leaf node')
  elseif a:node.status is# s:STATUS_COLLAPSED
    return s:Promise.resolve(a:nodes)
  elseif has_key(a:node.concealed, '__promise_expand')
    return a:node.concealed.__promise_expand
  elseif has_key(a:node, 'concealed.__promise_collapse')
    return a:node.concealed.__promise_collapse
  endif
  let l:Profile = fern#profile#start('fern#internal#node#collapse')
  let k = a:node.__key
  let n = len(k) - 1
  let l:K = n < 0 ? { v -> [] } : { v -> v.__key[:n] }
  let l:Done = fern#internal#node#process(a:node)
  let p = s:Promise.resolve(a:nodes)
        \.then(s:AsyncLambda.filter_f({ v -> v.__key == k || K(v) != k  }))
        \.finally({ -> Done() })
        \.finally({ -> Profile() })
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
  let l:Profile = fern#profile#start('fern#internal#node#reload')
  let k = a:node.__key
  let n = len(k) - 1
  let l:K = n < 0 ? { v -> [] } : { v -> v.__key[:n] }
  let outer = s:Promise.resolve(copy(a:nodes))
        \.then(s:AsyncLambda.filter_f({ v -> K(v) != k  }))
  let inner = s:Promise.resolve(copy(a:nodes))
        \.then(s:AsyncLambda.filter_f({ v -> K(v) == k  }))
        \.then(s:AsyncLambda.filter_f({ v -> v.status is# s:STATUS_EXPANDED }))
        \.then(s:AsyncLambda.map_f({ v ->
        \   fern#internal#node#children(v, a:provider, a:token, {
        \    'cache': 0,
        \   }).then({ children ->
        \     s:Lambda.if(v.status is# s:STATUS_EXPANDED, { -> [v] + children }, { -> [v]})
        \   }).catch({ error ->
        \     s:Lambda.pass([], fern#logger#warn(error))
        \   })
        \ }))
        \.then({ v -> s:Promise.all(v) })
        \.then(s:AsyncLambda.reduce_f({ a, v -> a + v }, []))
        \.then({ v -> s:sort(v, { a, b -> fern#util#compare(b.status, a.status) }) })
  let l:Done = fern#internal#node#process(a:node)
  return s:Promise.all([outer, inner])
        \.finally({ -> Profile('all') })
        \.then(s:AsyncLambda.reduce_f({ a, v -> a + v }, []))
        \.finally({ -> Profile('reduce') })
        \.then({ v -> s:sort(v, a:comparator.compare) })
        \.finally({ -> Profile('sort') })
        \.then({ v -> s:uniq(v) })
        \.finally({ -> Profile('uniq') })
        \.finally({ -> Done() })
        \.finally({ -> Profile() })
endfunction

function! fern#internal#node#reveal(key, nodes, provider, comparator, token) abort
  if a:key == a:nodes[0].__key
    return s:Promise.resolve(a:nodes)
  endif
  let l:Profile = fern#profile#start('fern#internal#node#reveal')
  return s:expand_recursively(0, a:key, a:nodes, a:provider, a:comparator, a:token)
        \.finally({ -> Profile() })
endfunction

function! s:new(node, ...) abort
  let node = extend(a:node, {
        \ 'label': get(a:node, 'label', a:node.name),
        \ 'badge': get(a:node, 'badge', ''),
        \ 'hidden': get(a:node, 'hidden', 0),
        \ 'bufname': get(a:node, 'bufname', v:null),
        \ 'concealed': get(a:node, 'concealed', {}),
        \ '__processing': 0,
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

function! s:expand_recursively(index, key, nodes, provider, comparator, token) abort
  let node = fern#internal#node#find(a:key[:a:index], a:nodes)
  if node is# v:null || node.status is# s:STATUS_NONE
    return s:Promise.resolve(a:nodes)
  endif
  return fern#internal#node#expand(node, a:nodes, a:provider, a:comparator, a:token)
        \.then({ ns -> s:Lambda.if(
        \   a:index < len(a:key) - 1,
        \   { -> s:expand_recursively(a:index + 1, a:key, ns, a:provider, a:comparator, a:token) },
        \   { -> ns },
        \ )})
endfunction
