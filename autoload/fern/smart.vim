let s:Promise = vital#fern#import('Async.Promise')


" For <expr> mappings
function! fern#smart#leaf(leaf, branch, ...) abort
  let helper = fern#helper#new()
  let node = helper.sync.get_cursor_node()
  if node is# v:null
    return "\<Nop>"
  endif
  if node.status is# helper.STATUS_NONE
    return a:leaf
  elseif node.status is# helper.STATUS_COLLAPSED
    return a:branch
  else
    return get(a:000, 0, a:branch)
  endif
endfunction

function! fern#smart#drawer(drawer, viewer) abort
  let helper = fern#helper#new()
  return helper.sync.is_drawer()
        \ ? a:drawer
        \ : a:viewer
endfunction

function! fern#smart#scheme(default, schemes) abort
  let helper = fern#helper#new()
  let scheme = helper.sync.get_scheme()
  if has_key(a:schemes, scheme)
    return a:schemes[scheme]
  endif
  return a:default
endfunction


" For NON <expr> mappings
function! fern#smart#ready(expr, ...) abort
  let options = extend({
        \ 'timeout': 500,
        \}, a:0 ? a:1 : {},
        \)
  call s:Promise.race([
        \ fern#hook#promise('viewer:ready'),
        \ fern#util#sleep(options.timeout)
        \])
        \.then({ -> execute(printf('normal %s', a:expr)) })
  return s:warn_on_expr_mapping(
        \ 'fern#smart#ready() cannot used in <expr> mapping',
        \)
endfunction

function! s:warn_on_expr_mapping(message) abort
  return printf("\<Esc>:echoerr '[fern] %s'\<CR>", escape(a:message, "'"))
endfunction
