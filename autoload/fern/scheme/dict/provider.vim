let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#dict#provider#new(...) abort
  let tree = a:0 ? a:1 : {}
  return {
        \ 'get_node': funcref('s:get_node', [tree]),
        \ 'get_parent': funcref('s:get_parent'),
        \ 'get_children': funcref('s:get_children'),
        \}
endfunction

function! s:get_node(tree, url) abort
  let meta = s:parse_url(a:url)
  if empty(meta.varname)
    let tree = a:tree
  else
    sandbox let tree = eval(meta.varname)
  endif
  let cursor = tree
  let path = []
  let node = s:node(meta, path, 'root', cursor, v:null)
  for term in split(meta.path, '/')
    if !has_key(cursor, term)
      throw printf("no %s exists: %s", term, a:url)
    endif
    call add(path, term)
    let node = s:node(meta, path, term, cursor[term], node)
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
          \ { _, v -> s:node(a:node._meta, a:node._path + [v], v, ref[v], a:node)},
          \)
    return s:Promise.resolve(children)
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction

function! s:parse_url(url) abort
  let url = fern#lib#url#parse(a:url)
  let m = matchlist(url.path, '^\([^/]*\)/\(.*\)$')
  if empty(m)
    return s:parse_url(a:url . '/')
  endif
  return {
        \ 'varname': fern#lib#url#decode(m[1]),
        \ 'path': m[2],
        \}
endfunction

function! s:node(meta, path, name, value, parent) abort
  let status = type(a:value) is# v:t_dict
  let varname = fern#lib#url#encode(a:meta.varname)
  let bufname = status ? printf('dict:%s/%s', varname, join(a:path, '/')) : v:null
  return {
        \ 'name': a:name,
        \ 'status': status,
        \ 'bufname': bufname,
        \ 'concealed': {
        \   '_value': a:value,
        \   '_parent': a:parent,
        \ },
        \ '_path': a:path,
        \ '_meta': a:meta,
        \}
endfunction
