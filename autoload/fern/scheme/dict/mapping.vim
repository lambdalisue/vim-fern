let s:Prompt = vital#fern#import('Prompt')
let s:Promise = vital#fern#import('Async.Promise')

let s:STATUS_EXPANDED = g:fern#internal#node#STATUS_EXPANDED

let s:clipboard = {
      \ 'mode': 'copy',
      \ 'candidates': [],
      \}

function! fern#scheme#dict#mapping#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-new-leaf)        :<C-u>call <SID>call('new_leaf')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-new-branch)      :<C-u>call <SID>call('new_branch')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-copy)            :<C-u>call <SID>call('copy')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-move)            :<C-u>call <SID>call('move')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-clipboard-copy)  :<C-u>call <SID>call('clipboard_copy')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-clipboard-move)  :<C-u>call <SID>call('clipboard_move')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-clipboard-paste) :<C-u>call <SID>call('clipboard_paste')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-clipboard-clear) :<C-u>call <SID>call('clipboard_clear')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-remove)          :<C-u>call <SID>call('remove')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-rename)          :<C-u>call <SID>call('rename')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-edit-leaf)       :<C-u>call <SID>call('edit_leaf')<CR>

  if !a:disable_default_mappings
    nmap <buffer><nowait> N <Plug>(fern-action-new-leaf)
    nmap <buffer><nowait> K <Plug>(fern-action-new-branch)
    nmap <buffer><nowait> c <Plug>(fern-action-copy)
    nmap <buffer><nowait> m <Plug>(fern-action-move)
    nmap <buffer><nowait> C <Plug>(fern-action-clipboard-copy)
    nmap <buffer><nowait> M <Plug>(fern-action-clipboard-move)
    nmap <buffer><nowait> P <Plug>(fern-action-clipboard-paste)
    nmap <buffer><nowait> D <Plug>(fern-action-remove)
    nmap <buffer><nowait> R <Plug>(fern-action-rename)
    nmap <buffer><nowait> e <Plug>(fern-action-edit-leaf)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ "fern#internal#mapping#call",
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_new_leaf(helper) abort
  let provider = a:helper.fern.provider

  " Ask a new leaf path
  let path = provider._prompt_leaf(a:helper)

  " Get parent node of a new leaf
  let node = a:helper.get_cursor_node()
  let node = node.status isnot# a:helper.STATUS_EXPANDED ? node.__owner : node

  " Update tree
  call fern#scheme#dict#tree#create(
        \ node.concealed._value,
        \ path,
        \ provider._default_leaf(a:helper, node, path),
        \)
  call provider._update_tree(provider._tree)

  " Update UI
  let key = node.__key + split(path, '/')
  let previous = a:helper.get_cursor_node()
  return s:Promise.resolve()
        \.then({ -> a:helper.reload_node(node.__key) })
        \.then({ -> a:helper.reveal_node(key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> a:helper.focus_node(key, { 'previous': previous }) })
endfunction

function! s:map_new_branch(helper) abort
  let provider = a:helper.fern.provider

  " Ask a new branch path
  let path = provider._prompt_branch(a:helper)

  " Get parent node of a new branch
  let node = a:helper.get_cursor_node()
  let node = node.status isnot# a:helper.STATUS_EXPANDED ? node.__owner : node

  " Update tree
  call fern#scheme#dict#tree#create(
        \ node.concealed._value,
        \ path,
        \ provider._default_branch(a:helper, node, path),
        \)
  call provider._update_tree(provider._tree)

  " Update UI
  let key = node.__key + split(path, '/')
  let previous = a:helper.get_cursor_node()
  return s:Promise.resolve()
        \.then({ -> a:helper.reload_node(node.__key) })
        \.then({ -> a:helper.reveal_node(key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> a:helper.focus_node(key, { 'previous': previous }) })
endfunction

function! s:map_copy(helper) abort
  let provider = a:helper.fern.provider
  let tree = provider._tree

  let nodes = a:helper.get_selected_nodes()
  let processed = 0
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
    call fern#scheme#dict#tree#copy(tree, src, dst)
    let processed += 1
  endfor
  call provider._update_tree(tree)

  let root = a:helper.get_root_node()
  return s:Promise.resolve()
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are copied', processed)) })
endfunction

function! s:map_move(helper) abort
  let provider = a:helper.fern.provider
  let tree = provider._tree

  let nodes = a:helper.get_selected_nodes()
  let processed = 0
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
    call fern#scheme#dict#tree#move(tree, src, dst)
    let processed += 1
  endfor
  call provider._update_tree(tree)

  let root = a:helper.get_root_node()
  return s:Promise.resolve()
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are moved', processed)) })
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
  let provider = a:helper.fern.provider
  let tree = provider._tree

  let node = a:helper.get_cursor_node()
  let node = node.status isnot# s:STATUS_EXPANDED ? node.__owner : node
  let processed = 0
  for src in s:clipboard.candidates
    let dst = '/' . join(split(node._path . '/' . matchstr(src, '[^/]\+$'), '/'), '/')
    if s:clipboard.mode ==# 'move'
      echo printf("Move %s -> %s", src, dst)
      call fern#scheme#dict#tree#move(tree, src, dst)
    else
      echo printf("Copy %s -> %s", src, dst)
      call fern#scheme#dict#tree#copy(tree, src, dst)
    endif
    let processed += 1
  endfor
  call provider._update_tree(tree)

  let root = a:helper.get_root_node()
  return s:Promise.resolve()
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are proceeded', processed)) })
endfunction

function! s:map_clipboard_clear(helper) abort
  let s:clipboard = {
        \ 'mode': 'copy',
        \ 'candidates': [],
        \}
endfunction

function! s:map_remove(helper) abort
  let provider = a:helper.fern.provider

  let nodes = a:helper.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> v._path })
  let prompt = printf("The follwoing %d entries will be removed", len(paths))
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

  " Update tree
  let tree = provider._tree
  for node in nodes
    echo printf("Delete %s", node._path)
    call fern#scheme#dict#tree#remove(tree, node._path)
  endfor
  call provider._update_tree(tree)

  let root = a:helper.get_root_node()
  return s:Promise.resolve()
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are removed', len(nodes))) })
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
  let provider = a:helper.fern.provider
  let tree = provider._tree
  let proceeded = 0
  for pair in a:result
    let [src, dst] = pair
    if fern#scheme#dict#tree#exists(tree, src)
      echohl WarningMsg
      echo printf("%s does not exist", src)
      echohl None
      continue
    endif
    call fern#scheme#dict#tree#move(tree, src, dst)
    let proceeded += 1
  endfor
  call provider._update_tree(provider._tree)
  return s:Promise.resolve(proceeded)
endfunction

function! s:map_edit_leaf(helper) abort
  let provider = a:helper.fern.provider

  let node = a:helper.get_cursor_node()
  if node.status isnot# a:helper.STATUS_NONE
    return s:Promise.reject(printf("%s is not leaf", node.name))
  endif

  let value = s:Prompt.ask("New value: ", node.concealed._value)
  if value is# v:null
    return s:Promise.reject("Cancelled")
  endif

  " Update tree
  call fern#scheme#dict#tree#write(
        \ provider._tree,
        \ node._path,
        \ value,
        \ { 'overwrite': 1 },
        \)
  call provider._update_tree(provider._tree)

  let root = a:helper.get_root_node()
  let previous = a:helper.get_cursor_node()
  return s:Promise.resolve()
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
endfunction
