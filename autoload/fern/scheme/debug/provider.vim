let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#debug#provider#new(...) abort
  let tree = a:0 ? a:1 : s:tree
  return {
        \ 'get_root' : funcref('s:provider_get_root', [tree]),
        \ 'get_parent' : funcref('s:provider_get_parent', [tree]),
        \ 'get_children' : funcref('s:provider_get_children', [tree]),
        \}
endfunction

function! s:sleep(ms) abort
  return s:Promise.new({ resolve -> timer_start(a:ms, { -> resolve() }) })
endfunction

function! s:get_entry(tree, key) abort
  if !has_key(a:tree, a:key)
    return v:null
  endif
  let entry = extend({'key': a:key}, a:tree[a:key])
  return entry
endfunction

function! s:provider_get_root(tree, url) abort
  let url = matchstr(a:url, '^debug://\zs.*')
  let entry = s:get_entry(a:tree, url)
  if entry is# v:null
    throw printf('no such entry: %s', a:url)
  endif
  let node = {
        \ 'name': get(split(entry.key, '/'), -1, 'root'),
        \ 'status': has_key(entry, 'children'),
        \ '_uri': url,
        \}
  if node.status
    let node.bufname = 'fern:///debug://' . url
  endif
  return node
endfunction

function! s:provider_get_parent(tree, node, ...) abort
  let uri = matchstr(a:node._uri, '.*\ze/[^/]\{-}$')
  let uri = empty(uri) ? '/' : uri
  try
    let node = s:provider_get_root(a:tree, 'debug://' . uri)
    return s:Promise.resolve(node)
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction

function! s:provider_get_children(tree, node, ...) abort
  let uri = a:node._uri
  let entry = s:get_entry(a:tree, a:node._uri)
  if !has_key(entry, 'children')
    return s:Promise.reject(printf('no children exists for %s', entry.key))
  endif
  let base = split(uri, '/')
  try
    let children = map(
          \ copy(entry.children),
          \ { -> s:provider_get_root(a:tree, 'debug:///' . join(base + [v:val], '/')) },
          \)
    return s:sleep(get(entry, 'delay', 0)).then({ -> children })
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction


let s:tree = {
      \ '/': {
      \   'parent': v:null,
      \   'children': [
      \     'shallow',
      \     'deep',
      \     'heavy',
      \     'leaf',
      \   ],
      \ },
      \ '/shallow': {
      \   'parent': '/',
      \   'children': [
      \     'alpha',
      \     'beta',
      \     'gamma',
      \   ],
      \ },
      \ '/shallow/alpha': {
      \   'parent': '/shallow',
      \   'children': [],
      \ },
      \ '/shallow/beta': {
      \   'parent': '/shallow',
      \   'children': [],
      \ },
      \ '/shallow/gamma': {
      \   'parent': '/shallow',
      \ },
      \ '/deep': {
      \   'parent': '/',
      \   'children': [
      \     'alpha',
      \   ],
      \ },
      \ '/deep/alpha': {
      \   'parent': '/deep',
      \   'children': [
      \     'beta',
      \   ],
      \ },
      \ '/deep/alpha/beta': {
      \   'parent': '/deep/alpha',
      \   'children': [
      \     'gamma',
      \   ],
      \ },
      \ '/deep/alpha/beta/gamma': {
      \   'parent': '/deep/alpha/beta',
      \ },
      \ '/heavy': {
      \   'delay': 1000,
      \   'parent': '/',
      \   'children': [
      \     'alpha',
      \     'beta',
      \     'gamma',
      \   ],
      \ },
      \ '/heavy/alpha': {
      \   'delay': 2000,
      \   'parent': '/heavy',
      \   'children': [],
      \ },
      \ '/heavy/beta': {
      \   'delay': 3000,
      \   'parent': '/heavy',
      \   'children': [],
      \ },
      \ '/heavy/gamma': {
      \   'parent': '/heavy',
      \ },
      \ '/leaf': {
      \   'parent': '/',
      \ },
      \}
