function! fern#mapping#filter#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-hidden:set)    :<C-u>call <SID>call('hidden_set')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-hidden:unset)  :<C-u>call <SID>call('hidden_unset')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-hidden:toggle) :<C-u>call <SID>call('hidden_toggle')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-include)       :<C-u>call <SID>call('include')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-exclude)       :<C-u>call <SID>call('exclude')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-include=)      :<C-u>call <SID>call_without_guard('include')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-exclude=)      :<C-u>call <SID>call_without_guard('exclude')<CR>

  " Alias
  nmap <buffer> <Plug>(fern-action-hidden) <Plug>(fern-action-hidden:toggle)

  if !a:disable_default_mappings
    nmap <buffer><nowait> !  <Plug>(fern-action-hidden)
    nmap <buffer><nowait> fi <Plug>(fern-action-include)
    nmap <buffer><nowait> fe <Plug>(fern-action-exclude)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:call_without_guard(name, ...) abort
  return call(
        \ 'fern#mapping#call_without_guard',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_hidden_set(helper) abort
  return a:helper.async.set_hidden(1)
        \.then({ -> a:helper.async.redraw() })
endfunction

function! s:map_hidden_unset(helper) abort
  return a:helper.async.set_hidden(0)
        \.then({ -> a:helper.async.redraw() })
endfunction

function! s:map_hidden_toggle(helper) abort
  if a:helper.fern.hidden
    return s:map_hidden_unset(a:helper)
  else
    return s:map_hidden_set(a:helper)
  endif
endfunction

function! s:map_include(helper) abort
  let pattern = input('Pattern: ', a:helper.fern.include)
  return a:helper.async.set_include(pattern)
        \.then({ -> a:helper.async.redraw() })
endfunction

function! s:map_exclude(helper) abort
  let pattern = input('Pattern: ', a:helper.fern.exclude)
  return a:helper.async.set_exclude(pattern)
        \.then({ -> a:helper.async.redraw() })
endfunction
