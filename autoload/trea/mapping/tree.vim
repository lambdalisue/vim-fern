let s:Promise = vital#trea#import('Async.Promise')
let s:Prompt = vital#trea#import('Prompt')
let s:WindowCursor = vital#trea#import('Vim.Window.Cursor')

function! trea#mapping#tree#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(trea-action-cancel) :<C-u>call <SID>call('cancel')<CR>
  nnoremap <buffer><silent> <Plug>(trea-action-redraw) :<C-u>call <SID>call('redraw')<CR>

  if !a:disable_default_mappings
    nmap <buffer><nowait> <C-c> <Plug>(trea-action-cancel)
    nmap <buffer><nowait> <C-l> <Plug>(trea-action-redraw)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ "trea#mapping#call",
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_cancel(helper) abort
  call a:helper.cancel()
  return a:helper.redraw()
endfunction

function! s:map_redraw(helper) abort
  return a:helper.redraw()
endfunction
