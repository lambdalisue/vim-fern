let s:Config = vital#trea#import('Config')
let s:Promise = vital#trea#import('Async.Promise')

function! trea#mapping#call(fn, ...) abort
  try
    call s:Promise.resolve(call('trea#helper#call', [a:fn] + a:000))
          \.catch({ e -> trea#message#error(e) })
  catch
    call trea#message#error(v:exception)
  endtry
endfunction

function! trea#mapping#smart(leaf, branch, ...) abort
  let helper = trea#helper#new()
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

function! trea#mapping#init(scheme) abort
  let disable_default_mappings = g:trea#mapping#disable_default_mappings
  for name in g:trea#mapping#enabled_mapping_presets
    call trea#mapping#{name}#init(disable_default_mappings)
  endfor
  try
    call trea#scheme#{a:scheme}#mapping#init(disable_default_mappings)
  catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: trea#scheme#[^#]\+#mapping#init/
    " the scheme does not provide mappings, ignore
  endtry
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
