let s:Promise = vital#trea#import('Async.Promise')

function! trea#mapping#mark#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(trea-action-mark-clear)  :<C-u>call <SID>call('mark_clear')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-mark-toggle) :<C-u>call <SID>call('mark_toggle')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-mark-set)    :<C-u>call <SID>call('mark_set')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-mark-unset   :<C-u>call <SID>call('mark_unset')<CR>
  vnoremap <buffer><silent> <Plug>(trea-action-mark-set)    :call <SID>call('mark_set')<CR>
  vnoremap <buffer><silent> <Plug>(trea-action-mark-unset)  :call <SID>call('mark_unset')<CR>
  vnoremap <buffer><silent> <Plug>(trea-action-mark-toggle) :call <SID>call('mark_toggle')<CR>

  if !a:disable_default_mappings
    nmap <buffer><nowait> <C-j> <Plug>(trea-action-mark-toggle)j
    nmap <buffer><nowait> <C-k> k<Plug>(trea-action-mark-toggle)
    nmap <buffer><nowait> -     <Plug>(trea-action-mark-toggle)
    vmap <buffer><nowait> -     <Plug>(trea-action-mark-toggle)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ "trea#mapping#call",
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_mark_set(helper) abort
  let node = a:helper.get_cursor_node()
  if node is# v:null
    return s:Promise.reject("no node found on a cursor line")
  endif
  return a:helper.set_mark(node.__key, 1)
        \.then({ -> a:helper.redraw() })
endfunction

function! s:map_mark_unset(helper) abort
  let node = a:helper.get_cursor_node()
  if node is# v:null
    return s:Promise.reject("no node found on a cursor line")
  endif
  return a:helper.set_mark(node.__key, 0)
        \.then({ -> a:helper.redraw() })
endfunction

function! s:map_mark_toggle(helper) abort
  let node = a:helper.get_cursor_node()
  if node is# v:null
    return s:Promise.reject("no node found on a cursor line")
  endif
  if index(a:helper.trea.marks, node.__key) is# -1
    return s:map_mark_set(a:helper)
  else
    return s:map_mark_unset(a:helper)
  endif
endfunction

function! s:map_mark_clear(helper) abort
  return self.update_marks([])
endfunction
