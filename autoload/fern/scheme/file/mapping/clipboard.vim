let s:Promise = vital#fern#import('Async.Promise')
let s:Prompt = vital#fern#import('Prompt')
let s:Path = vital#fern#import('System.Filepath')

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
        \ "fern#internal#mapping#call",
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
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
  let node = node.status isnot# a:helper.STATUS_EXPANDED ? node.__owner : node
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
