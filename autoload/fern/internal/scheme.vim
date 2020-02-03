function! fern#internal#scheme#call(scheme, name, ...) abort
  try
    return call(printf('fern#scheme#%s#%s', a:scheme, a:name), a:000)
  catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: fern#scheme#[^#]\+#.*/
    return v:null
  endtry
endfunction

function! fern#internal#scheme#exists(scheme) abort
  return fern#internal#scheme#provider(a:scheme) isnot# v:null
endfunction

function! fern#internal#scheme#provider(scheme) abort
  return fern#internal#scheme#call(a:scheme, 'provider#new')
endfunction
