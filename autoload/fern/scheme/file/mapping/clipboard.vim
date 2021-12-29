let s:Promise = vital#fern#import('Async.Promise')

let s:clipboard = {
      \ 'mode': 'copy',
      \ 'candidates': [],
      \}

function! fern#scheme#file#mapping#clipboard#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-clipboard-copy)  :<C-u>call <SID>call('clipboard_copy')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-clipboard-move)  :<C-u>call <SID>call('clipboard_move')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-clipboard-paste) :<C-u>call <SID>call('clipboard_paste')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-clipboard-clear) :<C-u>call <SID>call('clipboard_clear')<CR>

  if !a:disable_default_mappings
    nmap <buffer><nowait> C <Plug>(fern-action-clipboard-copy)
    nmap <buffer><nowait> M <Plug>(fern-action-clipboard-move)
    nmap <buffer><nowait> P <Plug>(fern-action-clipboard-paste)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_clipboard_move(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let s:clipboard = {
        \ 'mode': 'move',
        \ 'candidates': copy(nodes),
        \}
  return s:Promise.resolve()
        \.then({ -> a:helper.async.update_marks([]) })
        \.then({ -> a:helper.async.remark() })
        \.then({ -> a:helper.sync.echo(printf('%d items are saved in clipboard to move', len(nodes))) })
endfunction

function! s:map_clipboard_copy(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let s:clipboard = {
        \ 'mode': 'copy',
        \ 'candidates': copy(nodes),
        \}
  return s:Promise.resolve()
        \.then({ -> a:helper.async.update_marks([]) })
        \.then({ -> a:helper.async.remark() })
        \.then({ -> a:helper.sync.echo(printf('%d items are saved in clipboard to copy', len(nodes))) })
endfunction

function! s:map_clipboard_paste(helper) abort
  if empty(s:clipboard)
    return s:Promise.reject('Nothing to paste')
  endif

  if s:clipboard.mode ==# 'move'
    let paths = map(copy(s:clipboard.candidates), { -> v:val._path })
    let prompt = printf('The following %d nodes will be moved', len(paths))
    for path in paths[:5]
      let prompt .= "\n" . path
    endfor
    if len(paths) > 5
      let prompt .= "\n..."
    endif
    let prompt .= "\nAre you sure to continue (y[es]/n[o]): "
    if !fern#internal#prompt#confirm(prompt)
      return s:Promise.reject('Cancelled')
    endif
  endif

  let node = a:helper.sync.get_cursor_node()
  let node = node.status isnot# a:helper.STATUS_EXPANDED ? node.__owner : node
  let base = fern#internal#filepath#to_slash(node._path)
  let token = a:helper.fern.source.token
  let ps = []
  for src in s:clipboard.candidates
    let name = fern#internal#filepath#to_slash(src._path)
    let name = fern#internal#path#basename(name)
    let dst = fern#internal#filepath#from_slash(join([base, name], '/'))
    if s:clipboard.mode ==# 'move'
      echo printf('Move %s -> %s', src._path, dst)
      call add(ps, fern#scheme#file#shutil#move(src._path, dst, token))
    else
      echo printf('Copy %s -> %s', src._path, dst)
      call add(ps, fern#scheme#file#shutil#copy(src._path, dst, token))
    endif
  endfor
  let root = a:helper.sync.get_root_node()
  return s:Promise.all(ps)
        \.then({ -> a:helper.async.collapse_modified_nodes(s:clipboard.candidates) })
        \.then({ -> a:helper.async.reload_node(root.__key) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.echo(printf('%d items are proceeded', len(ps))) })
endfunction

function! s:map_clipboard_clear(helper) abort
  let s:clipboard = {
        \ 'mode': 'copy',
        \ 'candidates': [],
        \}
endfunction
