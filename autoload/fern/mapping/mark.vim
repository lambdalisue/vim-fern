let s:Promise = vital#fern#import('Async.Promise')
let s:AsyncLambda = vital#fern#import('Async.Lambda')

function! fern#mapping#mark#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-mark:clear)  :<C-u>call <SID>call('mark_clear')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-mark:set)    :<C-u>call <SID>call('mark_set')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-mark:unset   :<C-u>call <SID>call('mark_unset')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-mark:toggle) :<C-u>call <SID>call('mark_toggle')<CR>
  vnoremap <buffer><silent> <Plug>(fern-action-mark:set)    :call <SID>call('mark_set')<CR>
  vnoremap <buffer><silent> <Plug>(fern-action-mark:unset)  :call <SID>call('mark_unset')<CR>
  vnoremap <buffer><silent> <Plug>(fern-action-mark:toggle) :call <SID>call('mark_toggle')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-mark-children:set:node)    :<C-u>call <SID>call('mark_children_set', { -> 1 })<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-mark-children:unset:node)  :<C-u>call <SID>call('mark_children_unset', { -> 1 })<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-mark-children:toggle:node) :<C-u>call <SID>call('mark_children_toggle', { -> 1 })<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-mark-children:set:leaf)    :<C-u>call <SID>call('mark_children_set', { n -> n.status is# 0 })<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-mark-children:unset:leaf)  :<C-u>call <SID>call('mark_children_unset', { n -> n.status is# 0 })<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-mark-children:toggle:leaf) :<C-u>call <SID>call('mark_children_toggle', { n -> n.status is# 0 })<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-mark-children:set:branch)    :<C-u>call <SID>call('mark_children_set', { n -> n.status isnot# 0 })<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-mark-children:unset:branch)  :<C-u>call <SID>call('mark_children_unset', { n -> n.status isnot# 0 })<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-mark-children:toggle:branch) :<C-u>call <SID>call('mark_children_toggle', { n -> n.status isnot# 0 })<CR>

  " Alias
  nmap <buffer> <Plug>(fern-action-mark) <Plug>(fern-action-mark:toggle)
  vmap <buffer> <Plug>(fern-action-mark) <Plug>(fern-action-mark:toggle)
  nmap <buffer> <Plug>(fern-action-mark-children:set) <Plug>(fern-action-mark-children:set:node)
  nmap <buffer> <Plug>(fern-action-mark-children:unset) <Plug>(fern-action-mark-children:unset:node)
  nmap <buffer> <Plug>(fern-action-mark-children:toggle) <Plug>(fern-action-mark-children:toggle:node)
  nmap <buffer> <Plug>(fern-action-mark-children) <Plug>(fern-action-mark-children:toggle)

  if !a:disable_default_mappings
    nmap <buffer><nowait> <C-j> <Plug>(fern-action-mark)j
    nmap <buffer><nowait> <C-k> k<Plug>(fern-action-mark)
    nmap <buffer><nowait> -     <Plug>(fern-action-mark)
    vmap <buffer><nowait> -     <Plug>(fern-action-mark)
  endif

  " DEPRECATED:
  nmap <buffer><silent><expr> <Plug>(fern-action-mark-clear)
        \ <SID>deprecated('fern-action-mark-clear', 'fern-action-mark:clear')
  nmap <buffer><silent><expr> <Plug>(fern-action-mark-set)
        \ <SID>deprecated('fern-action-mark-set', 'fern-action-mark:set')
  nmap <buffer><silent><expr> <Plug>(fern-action-mark-unset)
        \ <SID>deprecated('fern-action-mark-unset', 'fern-action-mark:unset')
  nmap <buffer><silent><expr> <Plug>(fern-action-mark-toggle)
        \ <SID>deprecated('fern-action-mark-toggle', 'fern-action-mark:toggle')
  vmap <buffer><silent><expr> <Plug>(fern-action-mark-clear)
        \ <SID>deprecated('fern-action-mark-clear', 'fern-action-mark:clear')
  vmap <buffer><silent><expr> <Plug>(fern-action-mark-set)
        \ <SID>deprecated('fern-action-mark-set', 'fern-action-mark:set')
  vmap <buffer><silent><expr> <Plug>(fern-action-mark-unset)
        \ <SID>deprecated('fern-action-mark-unset', 'fern-action-mark:unset')
  vmap <buffer><silent><expr> <Plug>(fern-action-mark-toggle)
        \ <SID>deprecated('fern-action-mark-toggle', 'fern-action-mark:toggle')
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_mark_set(helper) abort
  let node = a:helper.sync.get_cursor_node()
  if node is# v:null
    return s:Promise.reject('no node found on a cursor line')
  endif
  return a:helper.async.set_mark(node.__key, 1)
        \.then({ -> a:helper.async.remark() })
endfunction

function! s:map_mark_unset(helper) abort
  let node = a:helper.sync.get_cursor_node()
  if node is# v:null
    return s:Promise.reject('no node found on a cursor line')
  endif
  return a:helper.async.set_mark(node.__key, 0)
        \.then({ -> a:helper.async.remark() })
endfunction

function! s:map_mark_toggle(helper) abort
  let node = a:helper.sync.get_cursor_node()
  if node is# v:null
    return s:Promise.reject('no node found on a cursor line')
  endif
  if index(a:helper.fern.marks, node.__key) is# -1
    return s:map_mark_set(a:helper)
  else
    return s:map_mark_unset(a:helper)
  endif
endfunction

function! s:map_mark_children_set(helper, condition) abort
  let node = a:helper.sync.get_cursor_node()
  if node is# v:null
    return s:Promise.reject('no node found on a cursor line')
  endif
  let h = a:helper
  let m = a:helper.fern.marks
  return a:helper.async.expand_node(node.__key)
        \.then({ -> h.async.get_child_nodes(node.__key) })
        \.then(s:AsyncLambda.filter_f({ n -> a:condition(n) }))
        \.then(s:AsyncLambda.map_f({ n -> n.__key }))
        \.then(s:AsyncLambda.map_f({ k -> h.async.set_mark(k, 1) }))
        \.then({ -> h.async.redraw() })
endfunction

function! s:map_mark_children_unset(helper, condition) abort
  let node = a:helper.sync.get_cursor_node()
  if node is# v:null
    return s:Promise.reject('no node found on a cursor line')
  endif
  let h = a:helper
  let m = a:helper.fern.marks
  return a:helper.async.expand_node(node.__key)
        \.then({ -> h.async.get_child_nodes(node.__key) })
        \.then(s:AsyncLambda.filter_f({ n -> a:condition(n) }))
        \.then(s:AsyncLambda.map_f({ n -> n.__key }))
        \.then(s:AsyncLambda.map_f({ k -> h.async.set_mark(k, 0) }))
        \.then({ -> h.async.redraw() })
endfunction

function! s:map_mark_children_toggle(helper, condition) abort
  let node = a:helper.sync.get_cursor_node()
  if node is# v:null
    return s:Promise.reject('no node found on a cursor line')
  endif
  let h = a:helper
  let m = a:helper.fern.marks
  return a:helper.async.expand_node(node.__key)
        \.then({ -> h.async.get_child_nodes(node.__key) })
        \.then(s:AsyncLambda.filter_f({ n -> a:condition(n) }))
        \.then(s:AsyncLambda.map_f({ n -> n.__key }))
        \.then(s:AsyncLambda.map_f({ k -> h.async.set_mark(k, index(m, k) is# -1) }))
        \.then({ -> h.async.redraw() })
endfunction

function! s:map_mark_clear(helper) abort
  return a:helper.async.update_marks([])
        \.then({ -> a:helper.async.remark() })
endfunction
