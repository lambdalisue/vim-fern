" Constant variable
let g:fila#tree#item#STATUS_NONE      = 0
let g:fila#tree#item#STATUS_COLLAPSED = 1
let g:fila#tree#item#STATUS_EXPANDED  = 2
lockvar g:fila#tree#item#STATUS_NONE
lockvar g:fila#tree#item#STATUS_COLLAPSED
lockvar g:fila#tree#item#STATUS_EXPANDED

" Alias
let s:STATUS_NONE      = g:fila#tree#item#STATUS_NONE
let s:STATUS_COLLAPSED = g:fila#tree#item#STATUS_COLLAPSED
let s:STATUS_EXPANDED  = g:fila#tree#item#STATUS_EXPANDED


function! fila#tree#item#uri(uri) abort
  return s:uri(a:uri)
endfunction

function! fila#tree#item#new(resource_uri, ...) abort
  let status = a:0 ? a:1 : s:STATUS_COLLAPSED
  let props = a:0 > 1 ? a:2 : {}
  return s:new(s:uri(a:resource_uri), status, props)
endfunction

function! s:uri(uri) abort
  return join(filter(split(a:uri, '/'), '!empty(v:val)'), '/')
endfunction

function! s:new(resource_uri, status, props) abort
  let item = extend({
        \ 'label': split(a:resource_uri, '/')[-1],
        \ 'hidden': 0,
        \ '__level': len(split(a:resource_uri, '/')),
        \}, a:props,
        \)
  let item.resource_uri = a:resource_uri
  let item.status = a:status
  return item
endfunction
