let s:Lambda = vital#trea#import('Lambda')
let s:Promise = vital#trea#import('Async.Promise')
let s:Prompt = vital#trea#import('Prompt')
let s:Path = vital#trea#import('System.Filepath')

let s:clipboard = []

let s:STATUS_EXPANDED = g:trea#internal#node#STATUS_EXPANDED

function! trea#scheme#file#mapping#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(trea-action-cd:cd)            :<C-u>call <SID>call('cd', 'cd')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-cd:lcd)           :<C-u>call <SID>call('cd', 'lcd')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-cd:tcd)           :<C-u>call <SID>call('cd', 'tcd')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-open:system)      :<C-u>call <SID>call('open_system')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-mkfile)           :<C-u>call <SID>call('mkfile')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-mkdir)            :<C-u>call <SID>call('mkdir')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-move)             :<C-u>call <SID>call('move')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-clipboard-copy)   :<C-u>call <SID>call('clipboard_copy')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-clipboard-paste)  :<C-u>call <SID>call('clipboard_paste')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-clipboard-clear)  :<C-u>call <SID>call('clipboard_clear')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-trash)            :<C-u>call <SID>call('trash')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-remove)           :<C-u>call <SID>call('remove')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-rename)           :<C-u>call <SID>call('rename')<CR>

  " Alias
  nmap <buffer> <Plug>(trea-action-cd) <Plug>(trea-action-cd:tcd)

  if !a:disable_default_mappings
    nmap <buffer><nowait> x <Plug>(trea-action-open:system)
    nmap <buffer><nowait> N <Plug>(trea-action-mkfile)
    nmap <buffer><nowait> K <Plug>(trea-action-mkdir)
    nmap <buffer><nowait> m <Plug>(trea-action-move)
    nmap <buffer><nowait> c <Plug>(trea-action-clipboard-copy)
    nmap <buffer><nowait> p <Plug>(trea-action-clipboard-paste)
    nmap <buffer><nowait> d <Plug>(trea-action-trash)
    nmap <buffer><nowait> R <Plug>(trea-action-rename)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ "trea#mapping#call",
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_cd(helper, command) abort
  let path = a:helper.get_root_node()._path
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
  let node = a:helper.get_cursor_node()
  let Done = a:helper.process_node(node)
  return trea#scheme#file#shutil#open(node._path, a:helper.trea.source.token)
        \.then({ -> trea#message#info(printf('%s has opened', node._path)) })
        \.finally({ -> Done() })
endfunction

function! s:map_mkfile(helper) abort
  let name = s:Prompt.ask('New file: ', '', 'file')
  if empty(name)
    return s:Promise.reject('Cancelled')
  endif
  let node = a:helper.get_cursor_node()
  let node = node.status isnot# s:STATUS_EXPANDED ? node.__owner : node
  let path = s:Path.join(node._path, name)
  let key = node.__key + [name]
  let token = a:helper.trea.source.token
  let previous = a:helper.get_cursor_node()
  return trea#scheme#file#shutil#mkfile(path, token)
        \.then({ -> a:helper.reload_node(node.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> a:helper.focus_node(key, { 'previous': previous }) })
endfunction

function! s:map_mkdir(helper) abort
  let name = s:Prompt.ask('New directory: ', '', 'file')
  if empty(name)
    return s:Promise.reject('Cancelled')
  endif
  let node = a:helper.get_cursor_node()
  let node = node.status isnot# s:STATUS_EXPANDED ? node.__owner : node
  let path = s:Path.join(node._path, name)
  let key = node.__key + [name]
  let token = a:helper.trea.source.token
  let previous = a:helper.get_cursor_node()
  return trea#scheme#file#shutil#mkdir(path, token)
        \.then({ -> a:helper.reload_node(node.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> a:helper.focus_node(key, { 'previous': previous }) })
endfunction

function! s:map_move(helper) abort
  let nodes = a:helper.get_selected_nodes()
  let token = a:helper.trea.source.token
  let ps = []
  for node in nodes
    let src = node._path
    let dst = s:Prompt.ask(
          \ printf('Move: %s -> ', src),
          \ src,
          \ isdirectory(src) ? 'dir' : 'file',
          \)
    if empty(dst) || src ==# dst
      continue
    endif
    call add(ps, trea#scheme#file#shutil#move(src, dst, token))
  endfor
  let root = a:helper.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> trea#message#info(printf('%d items are moved', len(ps))) })
endfunction

function! s:map_clipboard_copy(helper) abort
  let nodes = a:helper.get_selected_nodes()
  let s:clipboard = map(
        \ copy(nodes),
        \ { _, v -> v._path },
        \)
  return s:Promise.resolve()
        \.then({ -> a:helper.clear_marks() })
        \.then({ -> a:helper.redraw() })
        \.then({ -> trea#message#info(printf('%d items are stacked', len(ps))) })
endfunction

function! s:map_clipboard_paste(helper) abort
  if empty(s:clipboard)
    return s:Promise.reject("Nothing to paste")
  endif
  let node = a:helper.get_cursor_node()
  let node = node.status isnot# s:STATUS_EXPANDED ? node.__owner : node
  let token = a:helper.trea.source.token
  let ps = []
  for src in s:clipboard
    let dst = s:Path.join(node._path, fnamemodify(src, ':t'))
    call trea#message#info(printf("Copy %s -> %s", src, dst))
    call add(ps, trea#scheme#file#shutil#copy(src, dst, token))
  endfor
  let root = a:helper.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> trea#message#info(printf('%d items are copied', len(ps))) })
endfunction

function! s:map_clipboard_clear(helper) abort
  let s:clipboard = []
endfunction

function! s:map_trash(helper) abort
  let nodes = a:helper.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> v._path })
  let prompt = printf("The follwoing %d files will be trached", len(paths))
  for path in paths[:5]
    let prompt .= "\n" . path
  endfor
  if len(paths) > 5
    let prompt .= "\n..."
  endif
  let prompt .= "\nAre you sure to continue (Y[es]/no): "
  if !s:Prompt.confirm(prompt)
    return s:Promise.reject("Cancelled")
  endif
  let token = a:helper.trea.source.token
  let ps = []
  for path in paths
    call trea#message#info(printf("Delete %s", path))
    call add(ps, trea#scheme#file#shutil#trash(path, token))
  endfor
  let root = a:helper.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> trea#message#info(printf('%d items are trashed', len(ps))) })
endfunction

function! s:map_remove(helper) abort
  let nodes = a:helper.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> v._path })
  let prompt = printf("The follwoing %d files will be removed", len(paths))
  for path in paths[:5]
    let prompt .= "\n" . path
  endfor
  if len(paths) > 5
    let prompt .= "\n..."
  endif
  let prompt .= "\nAre you sure to continue (Y[es]/no): "
  if !s:Prompt.confirm(prompt)
    return s:Promise.reject("Cancelled")
  endif
  let token = a:helper.trea.source.token
  let ps = []
  for path in paths
    call trea#message#info(printf("Delete %s", path))
    call add(ps, trea#scheme#file#shutil#remove(path, token))
  endfor
  let root = a:helper.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> trea#message#info(printf('%d items are removed', len(ps))) })
endfunction

function! s:map_rename(helper) abort
  let root = a:helper.get_root_node()
  let Factory = { -> map(copy(a:helper.get_selected_nodes()), { _, n -> n._path }) }
  let ns = {}
  return trea#internal#renamer#rename(Factory)
        \.then({ r -> s:_map_rename(a:helper, r) })
        \.then({ n -> s:Lambda.let(ns, 'n', n) })
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> trea#message#info(printf('%d items are renamed', ns.n)) })
endfunction

function! s:_map_rename(helper, result) abort
  let token = a:helper.trea.source.token
  let ps = []
  for pair in a:result
    let [src, dst] = pair
    if !filereadable(src) && isdirectory(src)
      call trea#message#error(printf("%s does not exist", src))
      continue
    endif
    call add(ps, trea#scheme#file#shutil#move(src, dst, token))
  endfor
  return s:Promise.all(ps)
        \.then({ -> len(ps) })
endfunction
