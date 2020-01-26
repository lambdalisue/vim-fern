function! fern#scheme#fern#command#init(url, options) abort
  let url = fern#lib#url#parse(a:url.path)
  let url.query = extend(a:url.query, url.query)
  call fern#scheme#call(
        \ url.scheme,
        \ 'command#init',
        \ extend(a:url, url),
        \ a:options,
        \)
endfunction
