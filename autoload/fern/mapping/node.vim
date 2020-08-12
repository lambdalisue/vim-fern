let s:Promise = vital#fern#import('Async.Promise')

function! fern#mapping#node#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-debug)         :<C-u>call <SID>call('debug')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-reload:all)    :<C-u>call <SID>call('reload_all')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-reload:cursor) :<C-u>call <SID>call('reload_cursor')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-expand)        :<C-u>call <SID>call('expand')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-collapse)      :<C-u>call <SID>call('collapse')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-reveal)        :<C-u>call <SID>call('reveal')<CR>

  nnoremap <buffer><silent> <Plug>(fern-action-enter)         :<C-u>call <SID>call('enter')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-leave)         :<C-u>call <SID>call('leave')<CR>

  nmap <buffer> <Plug>(fern-action-reload) <Plug>(fern-action-reload:all)

  if !a:disable_default_mappings
    nmap <buffer><nowait> <F5> <Plug>(fern-action-reload)
    nmap <buffer><nowait> <C-m> <Plug>(fern-action-enter)
    nmap <buffer><nowait> <C-h> <Plug>(fern-action-leave)
    nmap <buffer><nowait> l <Plug>(fern-action-expand)
    nmap <buffer><nowait> h <Plug>(fern-action-collapse)
    nmap <buffer><nowait> i <Plug>(fern-action-reveal)
    nmap <buffer><nowait> <Return> <C-m>
    nmap <buffer><nowait> <Backspace> <C-h>
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_debug(helper) abort
  let node = a:helper.sync.get_cursor_node()
  redraw | echo fern#internal#node#debug(node)
endfunction

function! s:map_reload_all(helper) abort
  let node = a:helper.sync.get_root_node()
  return a:helper.async.reload_node(node.__key)
        \.then({ -> a:helper.async.redraw() })
endfunction

function! s:map_reload_cursor(helper) abort
  let node = a:helper.sync.get_cursor_node()
  if node is# v:null
    return s:Promise.reject('no node found on a cursor line')
  endif
  return a:helper.async.reload_node(node.__key)
        \.then({ -> a:helper.async.redraw() })
endfunction

function! s:map_expand(helper) abort
  let node = a:helper.sync.get_cursor_node()
  if node is# v:null
    return s:Promise.reject('no node found on a cursor line')
  endif
  let previous = a:helper.sync.get_cursor_node()
  return a:helper.async.expand_node(node.__key)
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.focus_node(
        \   node.__key,
        \   { 'previous': previous, 'offset': 1 },
        \ )
        \})
endfunction

function! s:map_collapse(helper) abort
  let node = a:helper.sync.get_cursor_node()
  if node is# v:null
    return s:Promise.reject('no node found on a cursor line')
  endif
  let previous = a:helper.sync.get_cursor_node()
  return a:helper.async.collapse_node(node.__key)
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.focus_node(
        \   node.__key,
        \   { 'previous': previous },
        \ )
        \})
endfunction

function! s:map_reveal(helper) abort
  let path = input(
        \ 'Reveal: ',
        \ '',
        \ printf('customlist,%s', get(funcref('s:reveal_complete'), 'name')),
        \)
  if empty(path)
    return s:Promise.reject('Cancelled')
  endif
  return fern#internal#viewer#reveal(a:helper, path)
endfunction

function! s:map_enter(helper) abort
  let node = a:helper.sync.get_cursor_node()
  if node is# v:null
    return s:Promise.reject('no node found on a cursor line')
  endif
  return a:helper.async.enter_tree(node)
endfunction

function! s:map_leave(helper) abort
  return a:helper.async.leave_tree()
endfunction

function! s:reveal_complete(arglead, cmdline, cursorpos) abort
  let helper = fern#helper#new()
  let fri = fern#fri#parse(bufname('%'))
  let scheme = helper.fern.scheme
  let cmdline = fri.path
  let arglead = printf('-reveal=%s', a:arglead)
  let rs = fern#internal#complete#reveal(arglead, cmdline, a:cursorpos)
  return map(rs, { -> matchstr(v:val, '-reveal=\zs.*') })
endfunction
