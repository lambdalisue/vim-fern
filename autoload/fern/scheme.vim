function! fern#scheme#call(scheme, name, ...) abort
  try
    return call(printf("fern#scheme#%s#%s", a:scheme, a:name), a:000)
  catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: fern#scheme#[^#]\+#.*/
    return v:null
  endtry
endfunction

function! fern#scheme#exists(scheme) abort
  return fern#scheme#provider(a:scheme) isnot# v:null
endfunction

function! fern#scheme#provider(scheme) abort
  return fern#scheme#call(a:scheme, 'provider#new')
endfunction
