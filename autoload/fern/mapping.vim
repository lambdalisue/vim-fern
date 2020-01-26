let s:Config = vital#fern#import('Config')
let s:Promise = vital#fern#import('Async.Promise')

function! fern#mapping#call(fn, ...) abort
  try
    call s:Promise.resolve(call('fern#helper#call', [a:fn] + a:000))
          \.catch({ e -> fern#message#error(e) })
  catch
    call fern#message#error(v:exception)
  endtry
endfunction

function! fern#mapping#smart(leaf, branch, ...) abort
  let helper = fern#helper#new()
  let node = helper.get_cursor_node()
  if node is# v:null
    return "\<Nop>"
  endif
  if node.status is# helper.STATUS_NONE
    return a:leaf
  elseif node.status is# helper.STATUS_COLLAPSED
    return a:branch
  else
    return get(a:000, 0, a:branch)
  endif
endfunction

function! fern#mapping#drawer(drawer, viewer) abort
  let helper = fern#helper#new()
  return helper.is_drawer()
        \ ? a:drawer
        \ : a:viewer
endfunction

function! fern#mapping#init(scheme) abort
  let disable_default_mappings = g:fern#mapping#disable_default_mappings
  for name in g:fern#mapping#enabled_mapping_presets
    call fern#mapping#{name}#init(disable_default_mappings)
  endfor
  call fern#scheme#call(a:scheme, 'mapping#init', disable_default_mappings)
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'disable_default_mappings': 0,
      \ 'enabled_mapping_presets': [
      \   'tree',
      \   'node',
      \   'mark',
      \   'filter',
      \ ],
      \})
