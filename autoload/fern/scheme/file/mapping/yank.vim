function! fern#scheme#file#mapping#yank#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-yank:path) :<C-u>call <SID>call('yank_path')<CR>

  nmap <buffer> <Plug>(fern-action-yank) <Plug>(fern-action-yank:path)
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_yank_path(helper) abort
  let node = a:helper.sync.get_cursor_node()
  let value = node._path
  call setreg(v:register, value)
  redraw | echo "The node 'path' has yanked."
endfunction
