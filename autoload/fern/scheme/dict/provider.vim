let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#dict#provider#new(...) abort
  return {
        \ 'get_node': funcref('s:get_node'),
        \ 'get_parent': funcref('s:get_parent'),
        \ 'get_children': funcref('s:get_children'),
        \ '_tree': a:0 ? a:1 : deepcopy(s:sample_tree),
        \}
endfunction

function! s:get_node(url) abort dict
  let path = []
  let cursor = self._tree
  let node = s:node(path, 'root', cursor, v:null)
  for term in split(matchstr(a:url, 'dict:\zs.*'), '/')
    if !has_key(cursor, term)
      throw printf("no %s exists: %s", term, a:url)
    endif
    call add(path, term)
    let node = s:node(path, term, cursor[term], node)
  endfor
  return node
endfunction

function! s:get_parent(node, ...) abort
  let parent = a:node.concealed._parent
  let parent = parent is# v:null ? copy(a:node) : parent
  return s:Promise.resolve(parent)
endfunction

function! s:get_children(node, ...) abort
  try
    if a:node.status is# 0
      throw printf("%s node is leaf", a:node.name)
    endif
    let ref = a:node.concealed._value
    let children = map(
          \ keys(ref),
          \ { _, v -> s:node(a:node._path + [v], v, ref[v], a:node)},
          \)
    return s:Promise.resolve(children)
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction

function! s:node(path, name, value, parent) abort
  let status = type(a:value) is# v:t_dict
  let bufname = status ? printf('dict:/%s', join(a:path, '/')) : v:null
  return {
        \ 'name': a:name,
        \ 'status': status,
        \ 'bufname': bufname,
        \ 'concealed': {
        \   '_value': a:value,
        \   '_parent': a:parent,
        \ },
        \ '_path': a:path,
        \}
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
