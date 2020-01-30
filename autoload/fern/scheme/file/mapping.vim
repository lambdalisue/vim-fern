let s:Lambda = vital#fern#import('Lambda')
let s:Promise = vital#fern#import('Async.Promise')
let s:Prompt = vital#fern#import('Prompt')
let s:Path = vital#fern#import('System.Filepath')

let s:clipboard = {
      \ 'mode': 'copy',
      \ 'candidates': [],
      \}

let s:STATUS_EXPANDED = g:fern#internal#node#STATUS_EXPANDED

function! fern#scheme#file#mapping#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-cd)              :<C-u>call <SID>call('cd', 'cd')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-lcd)             :<C-u>call <SID>call('cd', 'lcd')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-tcd)             :<C-u>call <SID>call('cd', 'tcd')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-open:system)     :<C-u>call <SID>call('open_system')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-new-file)        :<C-u>call <SID>call('new_file')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-new-dir)         :<C-u>call <SID>call('new_dir')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-copy)            :<C-u>call <SID>call('copy')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-move)            :<C-u>call <SID>call('move')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-clipboard-copy)  :<C-u>call <SID>call('clipboard_copy')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-clipboard-move)  :<C-u>call <SID>call('clipboard_move')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-clipboard-paste) :<C-u>call <SID>call('clipboard_paste')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-clipboard-clear) :<C-u>call <SID>call('clipboard_clear')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-trash)           :<C-u>call <SID>call('trash')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-remove)          :<C-u>call <SID>call('remove')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename)          :<C-u>call <SID>call('rename')<CR>

  if !a:disable_default_mappings
    nmap <buffer><nowait> x <Plug>(fern-action-open:system)
    nmap <buffer><nowait> N <Plug>(fern-action-new-file)
    nmap <buffer><nowait> K <Plug>(fern-action-new-dir)
    nmap <buffer><nowait> c <Plug>(fern-action-copy)
    nmap <buffer><nowait> m <Plug>(fern-action-move)
    nmap <buffer><nowait> C <Plug>(fern-action-clipboard-copy)
    nmap <buffer><nowait> M <Plug>(fern-action-clipboard-move)
    nmap <buffer><nowait> P <Plug>(fern-action-clipboard-paste)
    nmap <buffer><nowait> D <Plug>(fern-action-trash)
    nmap <buffer><nowait> R <Plug>(fern-action-rename)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ "fern#internal#mapping#call",
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
  return fern#scheme#file#shutil#open(node._path, a:helper.fern.source.token)
        \.then({ -> fern#message#info(printf('%s has opened', node._path)) })
        \.finally({ -> Done() })
endfunction

function! s:map_new_file(helper) abort
  let name = s:Prompt.ask('New file: ', '', 'file')
  if empty(name)
    return s:Promise.reject('Cancelled')
  endif
  let node = a:helper.get_cursor_node()
  let node = node.status isnot# s:STATUS_EXPANDED ? node.__owner : node
  let path = s:Path.join(node._path, name)
  let key = node.__key + [name]
  let token = a:helper.fern.source.token
  let previous = a:helper.get_cursor_node()
  return fern#scheme#file#shutil#mkfile(path, token)
        \.then({ -> a:helper.reload_node(node.__key) })
        \.then({ -> a:helper.reveal_node(key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> a:helper.focus_node(key, { 'previous': previous }) })
endfunction

function! s:map_new_dir(helper) abort
  let name = s:Prompt.ask('New directory: ', '', 'dir')
  if empty(name)
    return s:Promise.reject('Cancelled')
  endif
  let node = a:helper.get_cursor_node()
  let node = node.status isnot# s:STATUS_EXPANDED ? node.__owner : node
  let path = s:Path.join(node._path, name)
  let key = node.__key + [name]
  let token = a:helper.fern.source.token
  let previous = a:helper.get_cursor_node()
  return fern#scheme#file#shutil#mkdir(path, token)
        \.then({ -> a:helper.reload_node(node.__key) })
        \.then({ -> a:helper.reveal_node(key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> a:helper.focus_node(key, { 'previous': previous }) })
endfunction

function! s:map_copy(helper) abort
  let nodes = a:helper.get_selected_nodes()
  let token = a:helper.fern.source.token
  let ps = []
  for node in nodes
    let src = node._path
    let dst = s:Prompt.ask(
          \ printf('Copy: %s -> ', src),
          \ src,
          \ isdirectory(src) ? 'dir' : 'file',
          \)
    if empty(dst) || src ==# dst
      continue
    endif
    call add(ps, fern#scheme#file#shutil#copy(src, dst, token))
  endfor
  let root = a:helper.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are copied', len(ps))) })
endfunction

function! s:map_move(helper) abort
  let nodes = a:helper.get_selected_nodes()
  let token = a:helper.fern.source.token
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
    call add(ps, fern#scheme#file#shutil#move(src, dst, token))
  endfor
  let root = a:helper.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are moved', len(ps))) })
endfunction

function! s:map_clipboard_move(helper) abort
  let nodes = a:helper.get_selected_nodes()
  let s:clipboard = {
        \ 'mode': 'move',
        \ 'candidates': map(copy(nodes), { _, v -> v._path }),
        \}
  return s:Promise.resolve()
        \.then({ -> a:helper.update_marks([]) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are saved in clipboard to move', len(nodes))) })
endfunction

function! s:map_clipboard_copy(helper) abort
  let nodes = a:helper.get_selected_nodes()
  let s:clipboard = {
        \ 'mode': 'copy',
        \ 'candidates': map(copy(nodes), { _, v -> v._path }),
        \}
  return s:Promise.resolve()
        \.then({ -> a:helper.update_marks([]) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are saved in clipboard to copy', len(nodes))) })
endfunction

function! s:map_clipboard_paste(helper) abort
  if empty(s:clipboard)
    return s:Promise.reject("Nothing to paste")
  endif

  if s:clipboard.mode ==# 'move'
    let paths = copy(s:clipboard.candidates)
    let prompt = printf("The following %d nodes will be moved", len(paths))
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
  endif

  let node = a:helper.get_cursor_node()
  let node = node.status isnot# s:STATUS_EXPANDED ? node.__owner : node
  let token = a:helper.fern.source.token
  let ps = []
  for src in s:clipboard.candidates
    let dst = s:Path.join(node._path, fnamemodify(src, ':t'))
    if s:clipboard.mode ==# 'move'
      echo printf("Move %s -> %s", src, dst)
      call add(ps, fern#scheme#file#shutil#move(src, dst, token))
    else
      echo printf("Copy %s -> %s", src, dst)
      call add(ps, fern#scheme#file#shutil#copy(src, dst, token))
    endif
  endfor
  let root = a:helper.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are proceeded', len(ps))) })
endfunction

function! s:map_clipboard_clear(helper) abort
  let s:clipboard = {
        \ 'mode': 'copy',
        \ 'candidates': [],
        \}
endfunction

function! s:map_trash(helper) abort
  let nodes = a:helper.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> v._path })
  let prompt = printf("The following %d files will be trashed", len(paths))
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
  let token = a:helper.fern.source.token
  let ps = []
  for node in nodes
    echo printf("Trash %s", node._path)
    call add(ps, fern#scheme#file#shutil#trash(node._path, token))
    let node.status = a:helper.STATUS_COLLAPSED
  endfor
  let root = a:helper.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are trashed', len(ps))) })
endfunction

function! s:map_remove(helper) abort
  let nodes = a:helper.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> v._path })
  let prompt = printf("The following %d files will be removed", len(paths))
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
  let token = a:helper.fern.source.token
  let ps = []
  for node in nodes
    echo printf("Remove %s", node._path)
    call add(ps, fern#scheme#file#shutil#remove(node._path, token))
    let node.status = a:helper.STATUS_COLLAPSED
  endfor
  let root = a:helper.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are removed', len(ps))) })
endfunction

function! s:map_rename(helper) abort
  let root = a:helper.get_root_node()
  let Factory = { -> map(copy(a:helper.get_selected_nodes()), { _, n -> n._path }) }
  let ns = {}
  return fern#internal#renamer#rename(Factory)
        \.then({ r -> s:_map_rename(a:helper, r) })
        \.then({ n -> s:Lambda.let(ns, 'n', n) })
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are renamed', ns.n)) })
endfunction

function! s:_map_rename(helper, result) abort
  let token = a:helper.fern.source.token
  let ps = []
  for pair in a:result
    let [src, dst] = pair
    if !filereadable(src) && isdirectory(src)
      echohl WarningMsg
      echo printf("%s does not exist", src)
      echohl None
      continue
    endif
    call add(ps, fern#scheme#file#shutil#move(src, dst, token))
  endfor
  return s:Promise.all(ps)
        \.then({ -> len(ps) })
endfunction
