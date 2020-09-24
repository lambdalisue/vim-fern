function! fern#mapping#yank#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-yank:label) :<C-u>call <SID>call('yank', 'label')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-yank:badge) :<C-u>call <SID>call('yank', 'badge')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-yank:bufname) :<C-u>call <SID>call('yank', 'bufname')<CR>

  nmap <buffer> <Plug>(fern-action-yank) <Plug>(fern-action-yank:bufname)

  if !a:disable_default_mappings
    nmap <buffer><nowait> y <Plug>(fern-action-yank)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_yank(helper, attr) abort
  let node = a:helper.sync.get_cursor_node()
  let value = get(node, a:attr, '')
  call setreg(v:register, value)
  redraw | echo printf("The node '%s' has yanked.", a:attr)
endfunction
