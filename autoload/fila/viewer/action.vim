let s:Dict = vital#fila#import('Data.Dict')
let s:Action = vital#fila#import('App.Action')
let s:Lambda = vital#fila#import('Lambda')
let s:Promise = vital#fila#import('Async.Promise')
let s:Revelator = vital#fila#import('App.Revelator')

function! fila#viewer#action#get() abort
  return s:Action.get()
endfunction

function! fila#viewer#action#call(...) abort
  let action = fila#viewer#action#get()
  let result = call(action.call, a:000, action)
  retur s:Promise.is_promise(result) ? result : s:Promise.resolve(result)
endfunction

function! fila#viewer#action#_init() abort
  let action = s:Action.new({
        \ 'args': { -> [fila#node#helper#new()] },
        \})
  call action.init()
endfunction

function! fila#viewer#action#_define() abort
  let action = fila#viewer#action#get()

  call action.define('sleep', funcref('s:sleep'), {
        \ 'hidden': 1,
        \})
  call action.define('echo', funcref('s:echo'), {
        \ 'hidden': 1,
        \ 'mapping_mode': 'nv',
        \})
  call action.define('yank', funcref('s:yank'), {
        \ 'mapping_mode': 'nv',
        \})
  call action.define('edit', funcref('s:edit'))
  call action.define('edit:side', funcref('s:edit_side'))
  call action.define('enter', funcref('s:enter'), {
        \ 'hidden': 1,
        \})
  call action.define('leave', funcref('s:leave'), {
        \ 'hidden': 1,
        \})
  call action.define('reload', funcref('s:reload'), {
        \ 'hidden': 1,
        \})
  call action.define('expand', funcref('s:expand'), {
        \ 'hidden': 1,
        \})
  call action.define('collapse', funcref('s:collapse'), {
        \ 'hidden': 1,
        \})
  call action.define('enter-or-edit', funcref('s:enter_or_edit'), {
        \ 'hidden': 2,
        \})
  call action.define('expand-or-edit', funcref('s:expand_or_edit'), {
        \ 'hidden': 2,
        \})
  call action.define('expand-or-collapse', funcref('s:expand_or_collapse'), {
        \ 'hidden': 2,
        \})
  call action.define('mark:set', funcref('s:mark_set'), {
        \ 'hidden': 1,
        \ 'mapping_mode': 'nv',
        \})
  call action.define('mark:unset', funcref('s:mark_unset'), {
        \ 'hidden': 1,
        \ 'mapping_mode': 'nv',
        \})
  call action.define('mark:toggle', funcref('s:mark_toggle'), {
        \ 'hidden': 1,
        \ 'mapping_mode': 'nv',
        \})
  call action.define('mark:clear', funcref('s:mark_clear'))
  call action.define('hidden:set', funcref('s:hidden_set'), {
        \ 'hidden': 1,
        \})
  call action.define('hidden:unset', funcref('s:hidden_unset'), {
        \ 'hidden': 1,
        \})
  call action.define('hidden:toggle', funcref('s:hidden_toggle'), {
        \ 'hidden': 1,
        \})
  call action.define('edit:select', 'edit select')
  call action.define('edit:split', 'edit split')
  call action.define('edit:vsplit', 'edit vsplit')
  call action.define('edit:tabedit', 'edit tabedit')
  call action.define('edit:pedit', 'edit pedit')
  call action.define('edit:above', 'edit leftabove split')
  call action.define('edit:left', 'edit leftabove vsplit')
  call action.define('edit:below', 'edit rightbelow split')
  call action.define('edit:right', 'edit rightbelow vsplit')
  call action.define('edit:top', 'edit topleft split')
  call action.define('edit:leftest', 'edit topleft vsplit')
  call action.define('edit:bottom', 'edit botright split')
  call action.define('edit:rightest', 'edit botright vsplit')
  call action.define('mark', 'mark:toggle', {
        \ 'mapping_mode': 'nv',
        \})
  call action.define('hidden', 'hidden:toggle')
endfunction

function! s:sleep(range, params, helper) abort
  execute printf('sleep %dm', v:count)
endfunction

function! s:echo(range, params, helper) abort
  let nodes = a:helper.get_marked_nodes()
  if empty(nodes)
    let nodes = a:helper.get_selection_nodes(a:range)
  endif
  for node in nodes
    echo printf('key     : %s', node.key)
    echo printf('text    : %s', node.text)
    echo printf('hidden  : %s', node.hidden)
    echo printf('status  : %s', node.status)
    echo printf('parent  : %s', has_key(node, 'parent'))
    echo printf('children: %s', has_key(node, 'children'))
    echo printf('bufname : %s', get(node, 'bufname', ''))
    echo printf('remains : %s', s:Dict.omit(copy(node), [
          \ 'key', 'text', 'hidden', 'status', 'parent', 'children', 'bufname',
          \]))
  endfor
endfunction

function! s:yank(range, params, helper) abort
  let nodes = a:helper.get_marked_nodes()
  if empty(nodes)
    let nodes = a:helper.get_selection_nodes(a:range)
  endif
  let buffer = map(copy(nodes), { -> get(v:val, 'bufname', '') })
  call setreg(v:register, join(buffer, '\n'))
endfunction

function! s:edit(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  if !has_key(node, 'bufname')
    throw s:Revelator.info('the node does not have bufname')
  endif
  return fila#lib#buffer#open(node.bufname, {
        \ 'opener': empty(a:params) ? 'edit' : a:params,
        \ 'locator': fila#viewer#drawer#is_drawer(win_getid()),
        \})
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:edit_side(range, params, helper) abort
  if fila#viewer#drawer#is_drawer(win_getid())
    return fila#viewer#action#call('edit:left')
  else
    return fila#viewer#action#call('edit:right')
  endif
endfunction

function! s:enter(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  if !has_key(node, 'bufname')
    throw s:Revelator.info('the node does not have bufname')
  endif
  let winid = win_getid()
  return a:helper.enter_node(node)
        \.then({ h -> h.cursor_node(winid, node, 1) })
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:leave(range, params, helper) abort
  let root = a:helper.get_root_node()
  if !has_key(root, 'parent') || !has_key(root.parent, 'bufname')
    throw s:Revelator.info('the node does not have bufname')
  endif
  let node = root.parent
  let winid = win_getid()
  return a:helper.enter_node(node)
        \.then({ h -> h.cursor_node(winid, root) })
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:reload(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  if !fila#node#is_expanded(node)
    return s:Promise.resolve()
  endif
  let winid = win_getid()
  return a:helper.reload_node(node)
        \.then({ h -> h.redraw() })
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:expand(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  if !fila#node#is_branch(node) || fila#node#is_expanded(node)
    return fila#viewer#action#call('reload')
  endif
  let winid = win_getid()
  return a:helper.expand_node(node)
        \.then({ h -> h.redraw() })
        \.then({ h -> h.cursor_node(winid, node, 1) })
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:collapse(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  if !fila#node#is_branch(node) || !fila#node#is_expanded(node)
    if !has_key(node, 'parent') || !fila#node#is_branch(node.parent) || !fila#node#is_expanded(node.parent)
      return s:Promise.resolve()
    endif
    let node = node.parent
  endif
  if node is# a:helper.get_root_node()
    return s:Promise.resolve()
  endif
  let winid = win_getid()
  return a:helper.collapse_node(node)
        \.then({ h -> h.redraw() })
        \.then({ h -> h.cursor_node(winid, node) })
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:enter_or_edit(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  return fila#node#is_branch(node)
        \ ? fila#viewer#action#call('enter')
        \ : fila#viewer#action#call('edit')
endfunction

function! s:expand_or_edit(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  return fila#node#is_branch(node)
        \ ? fila#viewer#action#call('expand')
        \ : fila#viewer#action#call('edit')
endfunction

function! s:expand_or_collapse(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  return fila#node#is_expanded(node) || !fila#node#is_branch(node)
        \ ? fila#viewer#action#call('collapse')
        \ : fila#viewer#action#call('expand')
endfunction

function! s:mark_set(range, params, helper) abort
  let nodes = a:helper.get_selection_nodes(a:range)
  let marks = a:helper.get_marks()
  for node in nodes
    call add(marks, node.key)
  endfor
  call a:helper.set_marks(uniq(marks))
  return a:helper.redraw()
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:mark_unset(range, params, helper) abort
  let nodes = a:helper.get_selection_nodes(a:range)
  let marks = a:helper.get_marks()
  for node in nodes
    let index = index(marks, node.key)
    if index isnot# -1
      call remove(marks, index)
    endif
  endfor
  call a:helper.set_marks(uniq(marks))
  return a:helper.redraw()
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:mark_toggle(range, params, helper) abort
  let nodes = a:helper.get_selection_nodes(a:range)
  let marks = a:helper.get_marks()
  for node in nodes
    let index = index(marks, node.key)
    if index isnot# -1
      call remove(marks, index)
    else
      call add(marks, node.key)
    endif
  endfor
  call a:helper.set_marks(uniq(marks))
  return a:helper.redraw()
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:mark_clear(range, params, helper) abort
  call a:helper.set_marks([])
  return a:helper.redraw()
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:hidden_set(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  let winid = win_getid()
  call a:helper.set_hidden(1)
  return a:helper.redraw()
        \.then({ h -> h.cursor_node(winid, node) })
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:hidden_unset(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  let winid = win_getid()
  call cursor(1, 1)
  call a:helper.set_hidden(0)
  return a:helper.redraw()
        \.then({ h -> h.cursor_node(winid, node) })
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:hidden_toggle(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  let winid = win_getid()
  if a:helper.get_hidden()
    call cursor(1, 1)
  endif
  call a:helper.set_hidden(!a:helper.get_hidden())
  return a:helper.redraw()
        \.then({ h -> h.cursor_node(winid, node) })
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction
