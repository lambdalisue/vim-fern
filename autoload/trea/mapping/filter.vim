let s:Prompt = vital#trea#import('Prompt')

function! trea#mapping#filter#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(trea-action-hide-set)    :<C-u>call <SID>call('hide_set')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-hide-unset)  :<C-u>call <SID>call('hide_unset')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-hide-toggle) :<C-u>call <SID>call('hide_toggle')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-include)     :<C-u>call <SID>call('include')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-exclude)     :<C-u>call <SID>call('exclude')<CR>

  if !a:disable_default_mappings
    nmap <buffer><nowait> !  <Plug>(trea-action-hide-toggle)
    nmap <buffer><nowait> fi <Plug>(trea-action-include)
    nmap <buffer><nowait> fe <Plug>(trea-action-exclude)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ "trea#mapping#call",
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_hide_set(helper) abort
  return a:helper.set_hide(1)
        \.then({ -> a:helper.redraw() })
endfunction

function! s:map_hide_unset(helper) abort
  return a:helper.set_hide(0)
        \.then({ -> a:helper.redraw() })
endfunction

function! s:map_hide_toggle(helper) abort
  if a:helper.trea.hide
    return s:map_hide_unset(a:helper)
  else
    return s:map_hide_set(a:helper)
  endif
endfunction

function! s:map_include(helper) abort
  let pattern = s:Prompt.ask("Pattern: ", a:helper.trea.include)
  return a:helper.set_include(pattern)
        \.then({ -> a:helper.redraw() })
endfunction

function! s:map_exclude(helper) abort
  let pattern = s:Prompt.ask("Pattern: ", a:helper.trea.exclude)
  return a:helper.set_exclude(pattern)
        \.then({ -> a:helper.redraw() })
endfunction
