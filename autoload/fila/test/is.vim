let s:Promise = vital#fila#import('Async.Promise')

function! fila#test#is#promise(value) abort
  return s:Promise.is_promise(a:value)
endfunction

function! fila#test#is#item(value) abort
  return type(a:value) is# v:t_dict
        \ && type(get(a:value, 'resource_uri')) is# v:t_string
        \ && type(get(a:value, 'label')) is# v:t_string
        \ && type(get(a:value, 'status')) is# v:t_number
        \ && type(get(a:value, 'hidden')) is# v:t_number
        \ && type(get(a:value, '__level')) is# v:t_number
endfunction

function! fila#test#is#provider(value) abort
  return type(a:value) is# v:t_dict
        \ && type(get(a:value, 'item')) is# v:t_func
        \ && type(get(a:value, 'parent')) is# v:t_func
        \ && type(get(a:value, 'children')) is# v:t_func
endfunction

function! fila#test#is#comparator(value) abort
  return type(a:value) is# v:t_dict
        \ && type(get(a:value, 'compare')) is# v:t_func
endfunction

function! fila#test#is#renderer(value) abort
  return type(a:value) is# v:t_dict
        \ && type(get(a:value, 'render')) is# v:t_func
        \ && type(get(a:value, 'syntax')) is# v:t_func
        \ && type(get(a:value, 'highlight')) is# v:t_func
endfunction
