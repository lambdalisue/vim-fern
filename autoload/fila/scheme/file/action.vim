let s:Path = vital#fila#import('System.Filepath')
let s:Prompt = vital#fila#import('Prompt')
let s:Promise = vital#fila#import('Async.Promise')
let s:Revelator = vital#fila#import('App.Revelator')

let s:STATUS_COLLAPSED = g:fila#node#STATUS_COLLAPSED
let s:STATUS_EXPANDED = g:fila#node#STATUS_EXPANDED

function! fila#scheme#file#action#define(action) abort
  call a:action.define('cd', funcref('s:cd', ['cd']))
  call a:action.define('lcd', funcref('s:cd', ['lcd']))
  call a:action.define('tcd', funcref('s:cd', ['tcd']))
  call a:action.define('open:system', funcref('s:open_system'))
  call a:action.define('new:file', funcref('s:new_file'), {
        \ 'repeat': 0,
        \})
  call a:action.define('new:directory', funcref('s:new_directory'), {
        \ 'repeat': 0,
        \})
  call a:action.define('move', funcref('s:move'), {
        \ 'repeat': 0,
        \ 'mapping_mode': 'nv',
        \})
  call a:action.define('copy:clipboard', funcref('s:copy_clipboard'), {
        \ 'hidden': 1,
        \ 'repeat': 0,
        \ 'mapping_mode': 'nv',
        \})
  call a:action.define('paste:clipboard', funcref('s:paste_clipboard'), {
        \ 'hidden': 1,
        \ 'repeat': 0,
        \})
  call a:action.define('clear:clipboard:', funcref('s:clear_clipboard'), {
        \ 'hidden': 1,
        \ 'repeat': 0,
        \})
  call a:action.define('delete:trash', funcref('s:delete_trash'), {
        \ 'hidden': 1,
        \ 'mapping_mode': 'nv',
        \})
  call a:action.define('delete:remove', funcref('s:delete_remove'), {
        \ 'hidden': 1,
        \ 'mapping_mode': 'nv',
        \})
  call a:action.define('copy', 'copy:clipboard', {
        \ 'repeat': 0,
        \ 'mapping_mode': 'nv',
        \})
  call a:action.define('paste', 'paste:clipboard', {
        \ 'repeat': 0,
        \ 'mapping_mode': 'nv',
        \})
  call a:action.define('delete', 'delete:trash', {
        \ 'mapping_mode': 'nv',
        \})
endfunction

function! s:cd(command, range, params, helper) abort
  let root = a:helper.get_root_node()
  if a:command ==# 'tcd' && !exists(':tcd')
    let winid = win_getid()
    silent execute printf(
          \ 'keepjumps %d,%dwindo lcd %s',
          \ 1, winnr('$'), fnameescape(root.__path),
          \)
    call win_gotoid(winid)
  else
    execute a:command fnameescape(root.__path)
  endif
endfunction

function! s:open_system(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  let path = node.__path
  call fila#scheme#file#util#open(node.__path)
        \.then({ -> fila#message#notify('%s is opened', path) })
        \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:new_file(range, params, helper) abort
  let name = s:Prompt.ask('New file: ', '', 'file')
  if empty(name)
    throw s:Revelator.info('Cancelled')
  endif
  let node = a:helper.get_cursor_node(a:range)
  if !fila#node#is_expanded(node)
    if has_key(node, 'parent')
      let node = node.parent
    endif
  endif
  let path = s:Path.join(node.__path, name)
  let winid = win_getid()
  call fila#scheme#file#util#new_file(path)
        \.then({ -> a:helper.reload_node(node) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> a:helper.cursor_node(winid, fila#scheme#file#node#new(path)) })
        \.then({ -> fila#message#notify('%s is created', name) })
        \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:new_directory(range, params, helper) abort
  let name = s:Prompt.ask('New directory: ', '', 'file')
  if empty(name)
    return
  endif
  let node = a:helper.get_cursor_node(a:range)
  if !fila#node#is_expanded(node)
    if has_key(node, 'parent')
      let node = node.parent
    endif
  endif
  let path = s:Path.join(node.__path, name)
  let winid = win_getid()
  call fila#scheme#file#util#new_directory(path)
        \.then({ -> a:helper.reload_node(node) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> a:helper.cursor_node(winid, fila#scheme#file#node#new(path)) })
        \.then({ -> fila#message#notify('%s is created', name) })
        \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:move(range, params, helper) abort
  let nodes = a:helper.get_marked_nodes()
  if empty(nodes)
    let nodes = a:helper.get_selection_nodes(a:range)
  endif
  let ps = []
  for node in nodes
    let src = s:Path.remove_last_separator(node.__path)
    let dst = s:Prompt.ask(
          \ printf('Move %s -> ', src),
          \ src,
          \)
    if empty(dst) || node.__path ==# dst
      continue
    endif
    call add(ps, fila#scheme#file#util#move(src, dst))
  endfor
  call s:Promise.all(ps)
        \.then({ -> a:helper.set_marks([]) })
        \.then({ -> a:helper.reload_node(a:helper.get_root_node()) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fila#message#notify('%d items are moved', len(nodes)) })
        \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:copy_clipboard(range, params, helper) abort
  let nodes = a:helper.get_marked_nodes()
  if empty(nodes)
    let nodes = a:helper.get_selection_nodes(a:range)
  endif
  let g:fila_file_clipboard = map(copy(nodes), { -> s:Path.remove_last_separator(v:val.__path) })
  call a:helper.set_marks([])
  call a:helper.redraw()
        \.then({ -> fila#message#notify('%d items are copied', len(g:fila_file_clipboard)) })
        \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:paste_clipboard(range, params, helper) abort
  if !exists('g:fila_file_clipboard')
    throw s:Revelator.info('nothing to paste')
  endif
  let node = a:helper.get_cursor_node(a:range)
  if !fila#node#is_expanded(node)
    if has_key(node, 'parent')
      let node = node.parent
    endif
  endif
  let ps =[]
  for src in g:fila_file_clipboard
    let dst = s:Path.join(node.__path, fnamemodify(src, ':t'))
    call fila#message#echo(
          \ 'coping %s to %s ...',
          \ src, dst,
          \)
    call add(ps, fila#scheme#file#util#copy(src, dst))
  endfor
  call s:Promise.all(ps)
        \.then({ -> a:helper.reload_node(node) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fila#message#notify('%d items are copied', len(g:fila_file_clipboard)) })
        \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:clear_clipboard(range, params, helper) abort
  silent! unlet! g:fila_file_clipboard
endfunction

function! s:delete_trash(range, params, helper) abort
  let nodes = a:helper.get_marked_nodes()
  if empty(nodes)
    let nodes = a:helper.get_selection_nodes(a:range)
  endif
  let names = map(nodes, { -> v:val.__path })
  let prompt = printf('The following %d files will be trashed', len(names))
  for name in names[:5]
    let prompt .= "\n" . name
  endfor
  if len(names) > 5
    let prompt .= "\n" . '...'
  endif
  let prompt .= "\nAre you sure? (Y[es]/no): "
  if !s:Prompt.confirm(prompt, v:true)
    throw s:Revelator.info('Cancelled')
  endif
  let ps = []
  for name in names
    call fila#message#echo(
          \ 'deleting %s ...', name,
          \)
    call add(ps, fila#scheme#file#util#trash(name))
  endfor
  call s:Promise.all(ps)
        \.then({ -> a:helper.reload_node(a:helper.get_root_node()) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fila#message#notify('%d items are trashed', len(nodes)) })
        \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:delete_remove(range, params, helper) abort
  let nodes = a:helper.get_marked_nodes()
  if empty(nodes)
    let nodes = a:helper.get_selection_nodes(a:range)
  endif
  let names = map(nodes, { -> v:val.__path })
  let prompt = printf('The following %d files will be removed', len(names))
  for name in names[:5]
    let prompt .= "\n" . name
  endfor
  if len(names) > 5
    let prompt .= "\n" . '...'
  endif
  let prompt .= "\nAre you sure? (Y[es]/no): "
  if !s:Prompt.confirm(prompt, v:true)
    throw s:Revelator.info('Cancelled')
  endif
  let ps = []
  for name in names
    call fila#message#echo(
          \ 'deleting %s ...', name,
          \)
    call add(ps, fila#scheme#file#util#remove(name))
  endfor
  call s:Promise.all(ps)
        \.then({ -> a:helper.reload_node(a:helper.get_root_node()) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fila#message#notify('%d items are removed', len(nodes)) })
        \.catch({ e -> fila#error#handle(e) })
endfunction
