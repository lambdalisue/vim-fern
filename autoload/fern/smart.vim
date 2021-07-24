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

function! fern#smart#drawer(drawer, viewer, ...) abort
  let helper = fern#helper#new()
  if a:0 is# 0
    return helper.sync.is_drawer()
          \ ? a:drawer
          \ : a:viewer
  else
    return helper.sync.is_drawer()
          \ ? helper.sync.is_right_drawer()
          \   ? a:viewer
          \   : a:drawer
          \ : a:1
  endif
endfunction

function! fern#smart#scheme(default, schemes) abort
  let helper = fern#helper#new()
  let scheme = helper.sync.get_scheme()
  if has_key(a:schemes, scheme)
    return a:schemes[scheme]
  endif
  return a:default
endfunction
