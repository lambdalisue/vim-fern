function! fern#internal#mapping#call(...) abort
  call fern#util#deprecated('fern#internal#mapping#call', 'fern#mapping#call')
  return call('fern#mapping#call', a:000)
endfunction

let g:fern#internal#mapping#mappings = g:fern#mapping#mappings
