let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#file#mapping#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-new-path)  :<C-u>call <SID>call('new_path')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-new-file)  :<C-u>call <SID>call('new_file')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-new-dir)   :<C-u>call <SID>call('new_dir')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-new-path=) :<C-u>call <SID>call_without_guard('new_path')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-new-file=) :<C-u>call <SID>call_without_guard('new_file')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-new-dir=)  :<C-u>call <SID>call_without_guard('new_dir')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-copy)      :<C-u>call <SID>call('copy')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-move)      :<C-u>call <SID>call('move')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-trash)     :<C-u>call <SID>call('trash')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-trash=)    :<C-u>call <SID>call_without_guard('trash')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-remove)    :<C-u>call <SID>call('remove')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-remove=)   :<C-u>call <SID>call_without_guard('remove')<CR>

  if !a:disable_default_mappings
    nmap <buffer><nowait> N <Plug>(fern-action-new-file)
    nmap <buffer><nowait> K <Plug>(fern-action-new-dir)
    nmap <buffer><nowait> c <Plug>(fern-action-copy)
    nmap <buffer><nowait> m <Plug>(fern-action-move)
    nmap <buffer><nowait> D <Plug>(fern-action-trash)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:call_without_guard(name, ...) abort
  return call(
        \ 'fern#mapping#call_without_guard',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_cd(helper, command) abort
  let path = a:helper.sync.get_cursor_node()._path
  if a:command ==# 'tcd' && !exists(':tcd')
    let winid = win_getid()
    silent execute printf(
          \ 'keepalt keepjumps %d,%dwindo lcd %s',
          \ 1, winnr('$'), fnameescape(path),
          \)
    call win_gotoid(winid)
  else
    execute a:command fnameescape(path)
  endif
  return s:Promise.resolve()
endfunction

function! s:map_open_system(helper) abort
  let node = a:helper.sync.get_cursor_node()
  let l:Done = a:helper.sync.process_node(node)
  return fern#scheme#file#shutil#open(node._path, a:helper.fern.source.token)
        \.then({ -> a:helper.sync.echo(printf('%s has opened', node._path)) })
        \.finally({ -> Done() })
endfunction

function! s:map_new_path(helper) abort
  let name = input(
        \ "(Hint: Ends with '/' create a directory instead of a file)\nNew path: ",
        \ '',
        \ 'file',
        \)
  if empty(name)
    return s:Promise.reject('Cancelled')
  endif
  return name[-1:] ==# '/'
        \ ? s:new_dir(a:helper, name)
        \ : s:new_file(a:helper, name)
endfunction

function! s:map_new_file(helper) abort
  let name = input('New file: ', '', 'file')
  if empty(name)
    return s:Promise.reject('Cancelled')
  endif
  return s:new_file(a:helper, name)
endfunction

function! s:map_new_dir(helper) abort
  let name = input('New directory: ', '', 'dir')
  if empty(name)
    return s:Promise.reject('Cancelled')
  endif
  return s:new_dir(a:helper, name)
endfunction

function! s:map_copy(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let token = a:helper.fern.source.token
  let ps = []
  for node in nodes
    let src = node._path
    let dst = input(
          \ printf('Copy: %s -> ', src),
          \ src,
          \ isdirectory(src) ? 'dir' : 'file',
          \)
    if empty(dst) || src ==# dst
      continue
    endif
    call add(ps, fern#scheme#file#shutil#copy(src, dst, token))
  endfor
  let root = a:helper.sync.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> a:helper.async.collapse_modified_nodes(nodes) })
        \.then({ -> a:helper.async.reload_node(root.__key) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.echo(printf('%d items are copied', len(ps))) })
endfunction

function! s:map_move(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let token = a:helper.fern.source.token
  let ps = []
  let bufutil_pairs = []
  for node in nodes
    let src = node._path
    let dst = input(
          \ printf('Move: %s -> ', src),
          \ src,
          \ isdirectory(src) ? 'dir' : 'file',
          \)
    if empty(dst) || src ==# dst
      continue
    endif
    call add(ps, fern#scheme#file#shutil#move(src, dst, token))
    call add(bufutil_pairs, [src, dst])
  endfor
  let root = a:helper.sync.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> s:auto_buffer_rename(bufutil_pairs) })
        \.then({ -> a:helper.async.collapse_modified_nodes(nodes) })
        \.then({ -> a:helper.async.reload_node(root.__key) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.echo(printf('%d items are moved', len(ps))) })
endfunction

function! s:map_trash(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> v._path })
  let prompt = printf('The following %d files will be trashed', len(paths))
  for path in paths[:5]
    let prompt .= "\n" . path
  endfor
  if len(paths) > 5
    let prompt .= "\n..."
  endif
  let prompt .= "\nAre you sure to continue (Y[es]/no): "
  if !fern#internal#prompt#confirm(prompt)
    return s:Promise.reject('Cancelled')
  endif
  let token = a:helper.fern.source.token
  let ps = []
  let bufutil_paths = []
  for node in nodes
    let path = node._path
    echo printf('Trash %s', path)
    call add(ps, fern#scheme#file#shutil#trash(path, token))
    call add(bufutil_paths, path)
  endfor
  let root = a:helper.sync.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> s:auto_buffer_delete(bufutil_paths) })
        \.then({ -> a:helper.async.collapse_modified_nodes(nodes) })
        \.then({ -> a:helper.async.reload_node(root.__key) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.echo(printf('%d items are trashed', len(ps))) })
endfunction

function! s:map_remove(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> v._path })
  let prompt = printf('The following %d files will be removed', len(paths))
  for path in paths[:5]
    let prompt .= "\n" . path
  endfor
  if len(paths) > 5
    let prompt .= "\n..."
  endif
  let prompt .= "\nAre you sure to continue (Y[es]/no): "
  if !fern#internal#prompt#confirm(prompt)
    return s:Promise.reject('Cancelled')
  endif
  let token = a:helper.fern.source.token
  let ps = []
  let bufutil_paths = []
  for node in nodes
    let path = node._path
    echo printf('Remove %s', path)
    call add(ps, fern#scheme#file#shutil#remove(path, token))
    call add(bufutil_paths, path)
  endfor
  let root = a:helper.sync.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> s:auto_buffer_delete(bufutil_paths) })
        \.then({ -> a:helper.async.collapse_modified_nodes(nodes) })
        \.then({ -> a:helper.async.reload_node(root.__key) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.echo(printf('%d items are removed', len(ps))) })
endfunction

function! s:new_file(helper, name) abort
  let node = a:helper.sync.get_cursor_node()
  let node = node.status isnot# a:helper.STATUS_EXPANDED ? node.__owner : node
  let path = fern#internal#filepath#to_slash(node._path)
  let path = join([path, a:name], '/')
  let path = fern#internal#filepath#from_slash(path)
  let key = node.__key + [a:name]
  let token = a:helper.fern.source.token
  let previous = a:helper.sync.get_cursor_node()
  return fern#scheme#file#shutil#mkfile(path, token)
        \.then({ -> a:helper.async.reload_node(node.__key) })
        \.then({ -> a:helper.async.reveal_node(key) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.focus_node(key, { 'previous': previous }) })
endfunction

function! s:new_dir(helper, name) abort
  let node = a:helper.sync.get_cursor_node()
  let node = node.status isnot# a:helper.STATUS_EXPANDED ? node.__owner : node
  let path = fern#internal#filepath#to_slash(node._path)
  let path = join([path, a:name], '/')
  let path = fern#internal#filepath#from_slash(path)
  let key = node.__key + [a:name]
  let token = a:helper.fern.source.token
  let previous = a:helper.sync.get_cursor_node()
  return fern#scheme#file#shutil#mkdir(path, token)
        \.then({ -> a:helper.async.reload_node(node.__key) })
        \.then({ -> a:helper.async.reveal_node(key) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.focus_node(key, { 'previous': previous }) })
endfunction

function! s:auto_buffer_rename(bufutil_pairs) abort
  if !g:fern#disable_auto_buffer_rename
    call fern#internal#buffer#renames(a:bufutil_pairs)
  endif
endfunction

function! s:auto_buffer_delete(bufutil_paths) abort
  if !g:fern#disable_auto_buffer_delete
    call fern#internal#buffer#removes(a:bufutil_paths)
  endif
endfunction

let g:fern#scheme#file#mapping#mappings = get(g:, 'fern#scheme#file#mapping#mappings', [
      \ 'cd',
      \ 'clipboard',
      \ 'ex',
      \ 'grep',
      \ 'rename',
      \ 'system',
      \ 'terminal',
      \ 'yank',
      \])
