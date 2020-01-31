let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#file#mapping#cd#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-cd)  :<C-u>call <SID>call('cd', 'cd')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-lcd) :<C-u>call <SID>call('cd', 'lcd')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-tcd) :<C-u>call <SID>call('cd', 'tcd')<CR>
endfunction

function! s:call(name, ...) abort
  return call(
        \ "fern#internal#mapping#call",
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_cd(helper, command) abort
  let node = a:helper.get_cursor_node()
  if a:command ==# 'tcd' && !exists(':tcd')
    let winid = win_getid()
    silent execute printf(
          \ 'keepalt keepjumps %d,%dwindo lcd %s',
          \ 1, winnr('$'), fnameescape(node._path),
          \)
    call win_gotoid(winid)
  else
    execute a:command fnameescape(node._path)
  endif
  return s:Promise.resolve()
endfunction
