let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#dict#provider#new(...) abort
  return {
        \ 'get_root': funcref('s:get_root'),
        \ 'get_parent': funcref('s:get_parent'),
        \ 'get_children': funcref('s:get_children'),
        \ '_tree': a:0 ? a:1 : deepcopy(s:sample_tree),
        \ '_parse_url': { u -> split(matchstr(u, '^dict:\zs.*$'), '/') },
        \ '_update_tree': { -> 0 },
        \ '_extend_node': { n -> n },
        \ '_prompt_leaf': funcref('s:_prompt', ['leaf']),
        \ '_prompt_branch': funcref('s:_prompt', ['branch']),
        \ '_default_leaf': { -> '' },
        \ '_default_branch': { -> {} },
        \}
endfunction

function! s:get_root(url) abort dict
  let terms = self._parse_url(a:url)
  let path = []
  let cursor = self._tree
  let node = s:node(self, path, 'root', cursor, v:null)
  for term in terms
    if !has_key(cursor, term)
      throw printf('no %s exists: %s', term, a:url)
    endif
    call add(path, term)
    let cursor = cursor[term]
    let node = s:node(self, path, term, cursor, node)
  endfor
  return node
endfunction

function! s:get_parent(node, ...) abort
  let parent = a:node.concealed._parent
  let parent = parent is# v:null ? copy(a:node) : parent
  return s:Promise.resolve(parent)
endfunction

function! s:get_children(node, ...) abort dict
  try
    if a:node.status is# 0
      throw printf('%s node is leaf', a:node.name)
    endif
    let ref = a:node.concealed._value
    let base = split(a:node._path, '/')
    let children = map(
          \ keys(ref),
          \ { _, v -> s:node(self, base + [v], v, ref[v], a:node)},
          \)
    return s:Promise.resolve(children)
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction

function! s:node(provider, path, name, value, parent) abort
  let path = '/' . join(a:path, '/')
  let status = type(a:value) is# v:t_dict
  let bufname = status ? printf('dict://%s', path) : v:null
  let label = status
        \ ? a:name
        \ : printf('%s [%s]', a:name, a:value)
  let node = {
        \ 'name': a:name,
        \ 'label': label,
        \ 'status': status,
        \ 'bufname': bufname,
        \ 'concealed': {
        \   '_value': a:value,
        \   '_parent': a:parent,
        \ },
        \ '_path': path,
        \}
  return a:provider._extend_node(node)
endfunction

function! s:_prompt(label, helper) abort
  let path = input(printf('New %s: ', a:label), '')
  if empty(path)
    throw 'Cancelled'
  endif
  return path
endfunction


let s:sample_tree = {
      \ 'shallow': {
      \   'alpha': {},
      \   'beta': {},
      \   'gamma': 'value',
      \ },
      \ 'deep': {
      \   'alpha': {
      \     'beta': {
      \       'gamma': 'value',
      \     },
      \   },
      \ },
      \ 'leaf': 'value',
      \}
