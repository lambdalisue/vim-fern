let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#file#mapping#cd#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-cd:root)  :<C-u>call <SID>call('cd_root', 'cd')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-lcd:root) :<C-u>call <SID>call('cd_root', 'lcd')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-tcd:root) :<C-u>call <SID>call('cd_root', 'tcd')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-cd:cursor)  :<C-u>call <SID>call('cd_cursor', 'cd')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-lcd:cursor) :<C-u>call <SID>call('cd_cursor', 'lcd')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-tcd:cursor) :<C-u>call <SID>call('cd_cursor', 'tcd')<CR>

  nmap <buffer> <Plug>(fern-action-cd) <Plug>(fern-action-cd:cursor)
  nmap <buffer> <Plug>(fern-action-lcd) <Plug>(fern-action-lcd:cursor)
  nmap <buffer> <Plug>(fern-action-tcd) <Plug>(fern-action-tcd:cursor)
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_cd_root(helper, command) abort
  if a:command ==# 'lcd'
    if fern#internal#window#select()
      return s:Promise.resolve()
    endif
  endif
  return s:cd(a:helper.sync.get_root_node(), a:helper, a:command)
endfunction

function! s:map_cd_cursor(helper, command) abort
  if a:command ==# 'lcd'
    if fern#internal#window#select()
      return s:Promise.resolve()
    endif
  endif
  return s:cd(a:helper.sync.get_cursor_node(), a:helper, a:command)
endfunction

function! s:cd(node, helper, command) abort
  if a:command ==# 'tcd' && !exists(':tcd')
    let winid = win_getid()
    silent execute printf(
          \ 'keepalt keepjumps %d,%dwindo lcd %s',
          \ 1, winnr('$'), fnameescape(a:node._path),
          \)
    call win_gotoid(winid)
  else
    execute a:command fnameescape(a:node._path)
  endif
  return s:Promise.resolve()
endfunction
