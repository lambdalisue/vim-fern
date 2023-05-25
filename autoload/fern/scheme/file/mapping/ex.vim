let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#file#mapping#ex#init(disable_default_mappings) abort
  nnoremap <buffer><silent> <Plug>(fern-action-ex)  :<C-u>call <SID>call('ex')<CR>
  nnoremap <buffer><silent> <Plug>(fern-action-ex=) :<C-u>call <SID>call_without_guard('ex')<CR>
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

function! s:map_ex(helper) abort
  let nodes = a:helper.sync.get_selected_nodes()
  let nodes = filter(copy(nodes), { -> v:val._path isnot# v:null })
  if empty(nodes)
    return
  endif
  call feedkeys("\<Home>", 'in')
  let expr = join(map(copy(nodes), { _, v -> fnameescape(fnamemodify(v._path, ':~:.')) }), ' ')
  let expr = input(':', ' ' . expr, 'command')
  if empty(expr)
    return
  endif
  if a:helper.sync.is_drawer()
    call fern#internal#locator#focus(winnr('#'))
  endif
  execute expr
endfunction
