let s:Promise = vital#fern#import('Async.Promise')
let s:AsyncLambda = vital#fern#import('Async.Lambda')

function! fern#helper#async#new(helper) abort
  let async = extend({ 'helper': a:helper }, s:async)
  return async
endfunction

let s:async = {}

function! s:async_sleep(ms) abort dict
  return fern#util#sleep(a:ms)
endfunction
let s:async.sleep = funcref('s:async_sleep')

function! s:async_redraw() abort dict
  let l:Profile = fern#profile#start('fern#helper:helper.async.redraw')
  let helper = self.helper
  let fern = helper.fern
  return s:Promise.resolve()
        \.then({ -> fern.renderer.render(fern.visible_nodes) })
        \.then({ v -> fern#internal#buffer#replace(helper.bufnr, v) })
        \.then({ -> helper.async.remark() })
        \.then({ -> fern#hook#emit('viewer:redraw', helper) })
        \.finally({ -> Profile() })
endfunction
let s:async.redraw = funcref('s:async_redraw')

function! s:async_remark() abort dict
  let l:Profile = fern#profile#start('fern#helper:helper.async.remark')
  let helper = self.helper
  let fern = helper.fern
  let marks = fern.marks
  return s:Promise.resolve(fern.visible_nodes)
        \.then(s:AsyncLambda.map_f({ n, i -> index(marks, n.__key) isnot# -1 ? i + 1 : 0 }))
        \.then(s:AsyncLambda.filter_f({ v -> v isnot# 0 }))
        \.then({ v -> fern#internal#mark#replace(helper.bufnr, v) })
        \.then({ -> fern#hook#emit('viewer:remark', helper) })
        \.finally({ -> Profile() })
endfunction
let s:async.remark = funcref('s:async_remark')

function! s:async_get_child_nodes(key) abort dict
  let helper = self.helper
  let fern = helper.fern
  let node = fern#internal#node#find(a:key, fern.nodes)
  if empty(node)
    return s:Promise.reject(printf('failed to find a node %s', a:key))
  endif
  let l:Profile = fern#profile#start('fern#helper:helper.async.get_child_nodes')
  return s:Promise.resolve()
        \.then({ -> fern#internal#node#children(
        \   node,
        \   fern.provider,
        \   fern.source.token,
        \ )
        \})
        \.finally({ -> Profile() })
endfunction
let s:async.get_child_nodes = funcref('s:async_get_child_nodes')

function! s:async_set_mark(key, value) abort dict
  let helper = self.helper
  let fern = helper.fern
  let index = index(fern.marks, a:key)
  if !xor(index isnot# -1, a:value)
    return s:Promise.resolve()
  endif
  if a:value
    call add(fern.marks, a:key)
  elseif index isnot# -1
    call remove(fern.marks, index)
  endif
  return self.update_marks(fern.marks)
endfunction
let s:async.set_mark = funcref('s:async_set_mark')

function! s:async_set_hidden(value) abort dict
  let helper = self.helper
  let fern = helper.fern
  if !xor(fern.hidden, a:value)
    return s:Promise.resolve()
  endif
  let fern.hidden = a:value
  return self.update_nodes(fern.nodes)
endfunction
let s:async.set_hidden = funcref('s:async_set_hidden')

function! s:async_set_include(pattern) abort dict
  let helper = self.helper
  let fern = helper.fern
  if fern.include ==# a:pattern
    return s:Promise.resolve()
  endif
  let fern.include = a:pattern
  return self.update_nodes(fern.nodes)
endfunction
let s:async.set_include = funcref('s:async_set_include')

function! s:async_set_exclude(pattern) abort dict
  let helper = self.helper
  let fern = helper.fern
  if fern.exclude ==# a:pattern
    return s:Promise.resolve()
  endif
  let fern.exclude = a:pattern
  return self.update_nodes(fern.nodes)
endfunction
let s:async.set_exclude = funcref('s:async_set_exclude')

function! s:async_update_nodes(nodes) abort dict
  let l:Profile = fern#profile#start('fern#helper:helper.async.update_nodes')
  let helper = self.helper
  let fern = helper.fern
  return helper.sync.save_cursor()
        \.then({ -> fern#internal#core#update_nodes(fern, a:nodes) })
        \.then({ -> helper.sync.restore_cursor() })
        \.finally({ -> Profile() })
endfunction
let s:async.update_nodes = funcref('s:async_update_nodes')

function! s:async_update_marks(marks) abort dict
  let l:Profile = fern#profile#start('fern#helper:helper.async.update_marks')
  let helper = self.helper
  let fern = helper.fern
  return fern#internal#core#update_marks(fern, a:marks)
        \.finally({ -> Profile() })
endfunction
let s:async.update_marks = funcref('s:async_update_marks')

function! s:async_expand_node(key) abort dict
  let helper = self.helper
  let fern = helper.fern
  let node = fern#internal#node#find(a:key, fern.nodes)
  if empty(node)
    return s:Promise.reject(printf('failed to find a node %s', a:key))
  elseif node.status is# helper.STATUS_NONE
    " To improve UX, reload owner instead
    return self.reload_node(node.__owner.__key)
  elseif node.status is# helper.STATUS_EXPANDED
    " To improve UX, reload instead
    return self.reload_node(node.__key)
  endif
  let l:Profile = fern#profile#start('fern#helper:helper.async.expand_node')
  return s:Promise.resolve()
        \.then({ -> fern#internal#node#expand(
        \   node,
        \   fern.nodes,
        \   fern.provider,
        \   fern.comparator,
        \   fern.source.token,
        \ )
        \})
        \.then({ ns -> self.update_nodes(ns) })
        \.finally({ -> Profile() })
endfunction
let s:async.expand_node = funcref('s:async_expand_node')

function! s:async_collapse_node(key) abort dict
  let helper = self.helper
  let fern = helper.fern
  let node = fern#internal#node#find(a:key, fern.nodes)
  if empty(node)
    return s:Promise.reject(printf('failed to find a node %s', a:key))
  elseif node.__owner is# v:null
    " To improve UX, root node should NOT be collapsed and reload instead.
    return self.reload_node(node.__key)
  elseif node.status isnot# helper.STATUS_EXPANDED
    " To improve UX, collapse a owner node instead
    return self.collapse_node(node.__owner.__key)
  endif
  let l:Profile = fern#profile#start('fern#helper:helper.async.collapse_node')
  return s:Promise.resolve()
        \.then({ -> fern#internal#node#collapse(
        \   node,
        \   fern.nodes,
        \   fern.provider,
        \   fern.comparator,
        \   fern.source.token,
        \ )
        \})
        \.then({ ns -> self.update_nodes(ns) })
        \.finally({ -> Profile() })
endfunction
let s:async.collapse_node = funcref('s:async_collapse_node')

function! s:async_reload_node(key) abort dict
  let helper = self.helper
  let fern = helper.fern
  let node = fern#internal#node#find(a:key, fern.nodes)
  if empty(node)
    return s:Promise.reject(printf('failed to find a node %s', a:key))
  endif
  let l:Profile = fern#profile#start('fern#helper:helper.async.reload_node')
  return s:Promise.resolve()
        \.then({ -> fern#internal#node#reload(
        \   node,
        \   fern.nodes,
        \   fern.provider,
        \   fern.comparator,
        \   fern.source.token,
        \ )
        \})
        \.then({ ns -> self.update_nodes(ns) })
        \.finally({ -> Profile() })
endfunction
let s:async.reload_node = funcref('s:async_reload_node')

function! s:async_reveal_node(key) abort dict
  let helper = self.helper
  let fern = helper.fern
  let l:Profile = fern#profile#start('fern#helper:helper.async.reveal_node')
  return s:Promise.resolve()
        \.then({ -> fern#internal#node#reveal(
        \   a:key,
        \   fern.nodes,
        \   fern.provider,
        \   fern.comparator,
        \   fern.source.token,
        \ )
        \})
        \.then({ ns -> self.update_nodes(ns) })
        \.finally({ -> Profile() })
endfunction
let s:async.reveal_node = funcref('s:async_reveal_node')

function! s:async_enter_tree(node) abort dict
  let helper = self.helper
  let fern = helper.fern
  if a:node.status is# helper.STATUS_NONE
    return s:Promise.reject()
  endif
  let saved = {
        \ 'hidden': fern.hidden,
        \ 'include': fern.include,
        \ 'exclude': fern.exclude,
        \}
  return s:Promise.resolve(a:node)
        \.then({ n -> s:enter(fern, n) })
        \.then({ bufnr -> fern#helper#new(bufnr) })
        \.then({ helper -> s:async_enter_tree_post(helper, saved) })
endfunction
function! s:async_enter_tree_post(helper, saved) abort
  let fern = a:helper.fern
  let fern.hidden = a:saved.hidden
  let fern.include = a:saved.include
  let fern.exclude = a:saved.exclude
  return a:helper.async.update_nodes(fern.nodes)
        \.then({ -> a:helper.async.redraw() })
endfunction
let s:async.enter_tree = funcref('s:async_enter_tree')

function! s:async_leave_tree() abort dict
  let helper = self.helper
  let fern = helper.fern
  let root = helper.sync.get_root_node()
  let saved = {
        \ 'name': root.name,
        \ 'hidden': fern.hidden,
        \ 'include': fern.include,
        \ 'exclude': fern.exclude,
        \}
  return s:Promise.resolve()
        \.then({ -> fern#internal#node#parent(
        \   root,
        \   fern.provider,
        \   fern.source.token,
        \ )
        \})
        \.then({ n -> s:enter(fern, n) })
        \.then({ bufnr -> fern#helper#new(bufnr) })
        \.then({ helper -> s:async_leave_tree_post(helper, saved) })
endfunction
function! s:async_leave_tree_post(helper, saved) abort
  let fern = a:helper.fern
  let fern.hidden = a:saved.hidden
  let fern.include = a:saved.include
  let fern.exclude = a:saved.exclude
  return a:helper.async.update_nodes(fern.nodes)
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.focus_node([a:saved.name]) })
endfunction
let s:async.leave_tree = funcref('s:async_leave_tree')

function! s:async_collapse_modified_nodes(nodes) abort dict
  let helper = self.helper
  let fern = helper.fern
  let ps = []
  for node in a:nodes
    if node.__owner is# v:null || node.status isnot# helper.STATUS_EXPANDED
      continue
    endif
    let p = fern#internal#node#collapse(
          \ node,
          \ fern.nodes,
          \ fern.provider,
          \ fern.comparator,
          \ fern.source.token,
          \)
          \.then({ ns -> self.update_nodes(ns) })
    call add(ps, p)
  endfor
  let l:Profile = fern#profile#start('fern#helper:helper.async.collapse_modified_nodes')
  return s:Promise.all(ps)
        \.finally({ -> Profile() })
endfunction
let s:async.collapse_modified_nodes = funcref('s:async_collapse_modified_nodes')


" Private
function! s:enter(fern, node) abort
  if !has_key(a:node, 'bufname')
    return s:Promise.reject('the node does not have bufname attribute')
  endif
  try
    let cur = fern#fri#parse(bufname('%'))
    let fri = fern#fri#parse(a:node.bufname)
    let fri.authority = cur.authority
    let fri.query = cur.query
    return fern#internal#viewer#open(fri, {})
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction
