let s:Config = vital#fern#import('Config')
let s:Promise = vital#fern#import('Async.Promise')

function! fern#mapping#call(fn, ...) abort
  try
    call inputsave()
    call s:Promise.resolve(call('fern#helper#call', [a:fn] + a:000))
          \.catch({ e -> fern#logger#error(e) })
  catch
    call fern#logger#error(v:exception)
  finally
    call inputrestore()
  endtry
endfunction

function! fern#mapping#init(scheme) abort
  let disable_default_mappings = g:fern#disable_default_mappings
  for name in g:fern#mapping#mappings
    call fern#mapping#{name}#init(disable_default_mappings)
  endfor
  call fern#internal#scheme#mapping_init(a:scheme, disable_default_mappings)
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'mappings': [
      \   'drawer',
      \   'filter',
      \   'mark',
      \   'node',
      \   'open',
      \   'tree',
      \   'wait',
      \ ],
      \})
