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
  let a:node.__processing += 1
  let p = a:provider.get_parent(a:node, a:token)
        \.then({ n -> s:new(n, {
        \   '__key': [],
        \   '__owner': v:null,
        \ })
        \})
        \.then({ n -> s:Lambda.pass(n, s:Lambda.let(a:node.__cache, 'parent', n)) })
        \.finally({ -> s:Lambda.let(a:node, '__processing', a:node.__processing - 1) })
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
  let a:node.__processing += 1
  let p = a:provider.get_children(a:node, a:token)
        \.then(s:AsyncLambda.map_f({ n ->
        \   s:new(n, {
        \     '__key': a:node.__key + [n.name],
        \     '__owner': a:node,
        \   })
        \ }))
        \.then({ v -> s:Lambda.pass(v, s:Lambda.let(a:node.__cache, 'children', v)) })
        \.finally({ -> s:Lambda.let(a:node, '__processing', a:node.__processing - 1) })
  let a:node.__promise.children = p
        \.finally({ -> s:Lambda.unlet(a:node.__promise, 'children') })
  return p
endfunction

function! s:new(node, ...) abort
  let label = get(a:node, 'label', a:node.name)
  let node = extend(a:node, {
        \ 'label': label,
        \ 'hidden': get(a:node, 'hidden', 0),
        \ 'bufname': get(a:node, 'bufname', v:null),
        \ '__key': [],
        \ '__owner': v:null,
        \ '__processing': 0,
        \ '__cache': {},
        \ '__promise': {},
        \})
  let node = extend(node, a:0 ? a:1 : {})
  return node
endfunction

let g:trea#internal#node#STATUS_NONE = s:STATUS_NONE
let g:trea#internal#node#STATUS_COLLAPSED = s:STATUS_COLLAPSED
let g:trea#internal#node#STATUS_EXPANDED = s:STATUS_EXPANDED
