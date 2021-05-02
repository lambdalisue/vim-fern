function! fern#mapping#drawer#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-zoom) :<C-u>call <SID>call('zoom')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-zoom:reset) :<C-u>call <SID>call('zoom_reset')<CR>
  nmap <buffer><silent> <Plug>(fern-action-zoom:half) 4<Plug>(fern-action-zoom)
  nmap <buffer><silent> <Plug>(fern-action-zoom:full) 9<Plug>(fern-action-zoom)

  if !a:disable_default_mappings
    nmap <buffer><nowait> z <Plug>(fern-action-zoom)
    nmap <buffer><nowait> Z <Plug>(fern-action-zoom:reset)
  endif
endfunction

function! s:call(name, ...) abort
  return call(
        \ 'fern#mapping#call',
        \ [funcref(printf('s:map_%s', a:name))] + a:000,
        \)
endfunction

function! s:map_zoom(helper) abort
  if !fern#internal#drawer#is_drawer()
    call fern#warn('zoom is available only on drawer')
    return
  endif
  let alpha = v:count
  if alpha <= 0 || alpha > 10
    let current = float2nr(ceil(str2float(winwidth(0)) / &columns * 10))
    let alpha = s:input_alpha(printf('Width ratio [%d -> 1-10]: ', current))
    if alpha is# v:null
      return
    endif
  endif
  let alpha = str2float(alpha)
  let width = &columns * (alpha / 10)
  execute 'vertical resize' float2nr(width)
endfunction

function! s:map_zoom_reset(helper) abort
  if !fern#internal#drawer#is_drawer()
    call fern#warn('zoom:resize is available only on drawer')
    return
  endif
  call fern#internal#drawer#resize()
endfunction

function! s:input_alpha(prompt) abort
  while v:true
    let result = input(a:prompt)
    if result ==# ''
      redraw | echo ''
      return v:null
    elseif result =~# '^\%(10\|[1-9]\)$'
      redraw | echo ''
      return result
    endif
    redraw | echo 'Please input a digit from 1 to 10'
  endwhile
endfunction
