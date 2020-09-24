function! fern#mapping#drawer#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-zoom:half) :<C-u>call <SID>call('zoom', 0.4)<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-zoom:full) :<C-u>call <SID>call('zoom', 0.9)<CR>

  nmap <buffer> <Plug>(fern-action-zoom) <Plug>(fern-action-zoom:half)

  if !a:disable_default_mappings
    nmap <buffer><nowait> z <Plug>(fern-action-zoom)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_zoom(helper, alpha) abort
  if fern#internal#drawer#is_drawer()
    let width = &columns * a:alpha
    execute printf('%d wincmd |', float2nr(width))
  endif
endfunction
