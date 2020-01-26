function! fern#scheme#dict#tree#get(tree, path, ...) abort
  let default = a:0 ? a:1 : v:null
  let node = s:dig(a:tree, a:path, 0)
  return node is# v:null ? default : node
endfunction

function! fern#scheme#dict#tree#set(tree, path, value, ...) abort
  if empty(a:path)
    throw "path cannot be empty to set value in a tree"
  endif
  let options = extend({
        \ 'create_parents': 0,
        \ 'overwrite': 0,
        \}, a:0 ? a:1 : {},
        \)
  let name = a:path[-1]
  let path = a:path[:-2]
  let parent = s:dig(a:tree, path, options.create_parents)
  if parent is# v:null
    throw printf("parent nodes of a node '%s' does not exist", join(a:path, '/'))
  endif
  if has_key(parent, name) && !options.overwrite
    throw printf("a node '%s' has already exist", join(a:path, '/'))
  endif
  let parent[name] = a:value
  return parent[name]
endfunction

function! fern#scheme#dict#tree#pop(tree, path, ...) abort
  if empty(a:path)
    throw "path cannot be empty to pop value from a tree"
  endif
  let default = a:0 ? a:1 : v:null
  let name = a:path[-1]
  let path = a:path[:-2]
  let parent = s:dig(a:tree, path, 0)
  if parent is# v:null || !has_key(parent, name)
    return default
  endif
  return remove(parent, name)
endfunction

function! s:dig(tree, path, create) abort
  let cursor = a:tree
  for term in a:path
    if !has_key(cursor, term)
      if !a:create
        return v:null
      endif
      let cursor[term] = {}
    endif
    let cursor = cursor[term]
  endfor
  return cursor
endfunction

