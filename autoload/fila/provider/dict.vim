" NOTE:
" Do NOT use Promise on this provider while some assume that this
" provider is SYNCHRONOUS. In other words, you can assume that this
" provider is synchronous for testing or whatever.
let s:STATUS_NONE      = g:fila#tree#item#STATUS_NONE
let s:STATUS_COLLAPSED = g:fila#tree#item#STATUS_COLLAPSED


function! fila#provider#dict#new(tree) abort
  return {
        \ 'item': funcref('s:provider_item', [a:tree]),
        \ 'parent': funcref('s:provider_parent', [a:tree]),
        \ 'children': funcref('s:provider_children', [a:tree]),
        \}
endfunction

function! s:provider_item(tree, resource_uri) abort dict
  let resource = s:find(a:tree, a:resource_uri)
  if type(resource) is# v:t_dict
    return fila#tree#item#new(a:resource_uri, s:STATUS_COLLAPSED)
  else
    return fila#tree#item#new(a:resource_uri, s:STATUS_NONE)
  endif
endfunction

function! s:provider_parent(tree, resource_uri) abort dict
  call s:find(a:tree, a:resource_uri)
  if empty(a:resource_uri)
    return ''
  endif
  return join(split(a:resource_uri, '/', 1)[:-2], '/')
endfunction

function! s:provider_children(tree, resource_uri) abort
  let resource = s:find(a:tree, a:resource_uri)
  if type(resource) isnot# v:t_dict
    throw fila#error#new('resource is not dict', {
          \ 'resource_uri': a:resource_uri,
          \ 'resource': resource,
          \})
  endif
  let prefix = empty(a:resource_uri) ? '' : a:resource_uri . '/'
  return map(keys(resource), { -> prefix . v:val })
endfunction

function! s:find(tree, resource_uri) abort
  if empty(a:resource_uri)
    return a:tree
  endif
  let terms = split(a:resource_uri, '/', 1)
  let cursor = a:tree
  for term in terms
    if cursor is# v:null || type(cursor) isnot# v:t_dict
      throw fila#error#new('resource does not exist', {
            \ 'resource_uri': a:resource_uri,
            \})
    endif
    let cursor = get(cursor, term, v:null)
  endfor
  if cursor is# v:null
    throw fila#error#new('resource does not exist', {
          \ 'resource_uri': a:resource_uri,
          \})
  endif
  return cursor
endfunction
