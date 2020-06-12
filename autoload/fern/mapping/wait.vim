let s:Config = vital#fern#import('Config')
let s:Promise = vital#fern#import('Async.Promise')

function! fern#mapping#wait#init(disable_default_mappings) abort
  nnoremap <buffer><silent>
        \ <Plug>(fern-wait-viewer:ready)
        \ :<C-u>call <SID>call('hook', 'viewer:ready')<CR>
  nmap <buffer> <Plug>(fern-wait) <Plug>(fern-wait-viewer:ready)
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_hook(helper, hook) abort
  let [_, err] = s:Promise.wait(
        \ fern#hook#promise(a:hook),
        \ {
        \   'interval': g:fern#mapping#wait#interval,
        \   'timeout': g:fern#mapping#wait#timeout,
        \ },
        \)
  if err isnot# v:null
    throw printf(
          \ '[fern] Failed to wait hook "%s": %s',
          \ a:hook,
          \ err,
          \)
  endif
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'interval': 100,
      \ 'timeout': 1000,
      \})
