let s:Prompt = vital#fern#import('Prompt')
let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#dict#mapping#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-new-leaf) :<C-u>call <SID>call('new_leaf')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-new-branch) :<C-u>call <SID>call('new_branch')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-remove) :<C-u>call <SID>call('remove')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-edit-leaf) :<C-u>call <SID>call('edit_leaf')<CR>

  if !a:disable_default_mappings
    nmap <buffer><nowait> N <Plug>(fern-action-new-leaf)
    nmap <buffer><nowait> K <Plug>(fern-action-new-branch)
    nmap <buffer><nowait> d <Plug>(fern-action-remove)
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
  call fern#scheme#dict#tree#set(node.concealed._value, path, "", {
        \ 'create_parents': 1,
        \})
  call provider._update_tree(provider._tree)

  " Update UI
  let key = node.__key + path
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
  call fern#scheme#dict#tree#set(node.concealed._value, path, {}, {
        \ 'create_parents': 1,
        \})
  call provider._update_tree(provider._tree)

  " Update UI
  let key = node.__key + path
  let previous = a:helper.get_cursor_node()
  return s:Promise.resolve()
        \.then({ -> a:helper.reload_node(node.__key) })
        \.then({ -> a:helper.reveal_node(key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> a:helper.focus_node(key, { 'previous': previous }) })
endfunction

function! s:map_remove(helper) abort
  let provider = a:helper.fern.provider

  let nodes = a:helper.get_selected_nodes()
  let paths = map(copy(nodes), { _, v -> v._path })
  let prompt = printf("The follwoing %d entries will be removed", len(paths))
  for path in paths[:5]
    let prompt .= "\n" . join(path, '/')
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
  for path in paths
    call fern#message#info(printf("Delete %s", join(path, '/')))
    call fern#scheme#dict#tree#pop(tree, path)
  endfor
  call provider._update_tree(tree)

  let root = a:helper.get_root_node()
  return s:Promise.resolve()
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
        \.then({ -> fern#message#info(printf('%d items are removed', len(paths))) })
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
  call fern#scheme#dict#tree#set(provider._tree, node._path, value, {
        \ 'overwrite': 1,
        \})
  call provider._update_tree(provider._tree)

  let root = a:helper.get_root_node()
  let previous = a:helper.get_cursor_node()
  return s:Promise.resolve()
        \.then({ -> a:helper.reload_node(root.__key) })
        \.then({ -> a:helper.redraw() })
endfunction
