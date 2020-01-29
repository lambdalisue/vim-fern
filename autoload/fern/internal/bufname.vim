function! fern#internal#bufname#parse(bufname) abort
  let bufname = a:bufname[-1:] ==# '$'
        \ ? a:bufname[:-2]
        \ : a:bufname
  if bufname[:6] ==# 'fern://'
    return fern#fri#parse(bufname)
  endif
  let expr = bufname =~# '[^\w]\+://'
        \ ? s:from_uri(bufname)
        \ : s:from_local(bufname)
  let fri = fern#fri#parse(expr)
  let out = {
        \ 'scheme': 'fern',
        \ 'authority': '',
        \ 'path': '',
        \ 'query': fri.query,
        \ 'fragment': '',
        \}
  let fri.query = {}
  let fri.fragment = {}
  let out.path = fern#fri#format(fri)
  return out
endfunction

function! s:from_uri(uri) abort
  " escape characters which cannot be used in Windows
  let uri = substitute(a:uri, '?', '%3F', 'g')
  let uri = substitute(uri, '*', '%2A', 'g')
  return uri
endfunction

function! s:from_local(path) abort
  return fern#scheme#file#fri#to_fri(a:path)
endfunction
