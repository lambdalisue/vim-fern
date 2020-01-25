function! fern#scheme#fern#command#norm(url) abort
  return fern#lib#url#parse(a:url.path)
endfunction
