let s:Promise = vital#fern#import('Async.Promise')
let s:WindowCursor = vital#fern#import('Vim.Window.Cursor')

function! fern#mapping#tree#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-cancel) :<C-u>call <SID>call('cancel')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-redraw) :<C-u>call <SID>call('redraw')<CR>

  if !a:disable_default_mappings
    nmap <buffer><nowait> <C-c> <Plug>(fern-action-cancel)
    nmap <buffer><nowait> <C-l> <Plug>(fern-action-redraw)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_cancel(helper) abort
  call a:helper.sync.cancel()
  return a:helper.async.redraw()
endfunction

function! s:map_redraw(helper) abort
  return a:helper.async.redraw()
endfunction
