function! fern#scheme#file#complete#url(arglead, cmdline, cursorpos) abort
  let path = '/' . fern#fri#parse(a:arglead).path
  let path = fern#internal#filepath#to_slash(path)
  let suffix = a:arglead =~# '/$' ? '/' : ''
  let rs = getcompletion(fern#internal#filepath#from_slash(path) . suffix, 'dir')
  call map(rs, { -> fern#internal#filepath#to_slash(v:val) })
  call map(rs, { -> s:to_fri(v:val) })
  return rs
endfunction

function! fern#scheme#file#complete#reveal(arglead, cmdline, cursorpos) abort
  let base = '/' . fern#fri#parse(matchstr(a:cmdline, '\<file:///\S*')).path
  let path = matchstr(a:arglead, '^-reveal=\zs.*')
  if path ==# ''
    let path = base
    let suffix = '/'
  else
    let path = fern#internal#filepath#to_slash(path)
    let path = fern#internal#path#absolute(path, base)
    let suffix = a:arglead =~# '/$' ? '/' : ''
  endif
  let rs = getcompletion(fern#internal#filepath#from_slash(path) . suffix, 'file')
  call map(rs, { -> fern#internal#filepath#to_slash(v:val) })
  call map(rs, { -> fern#internal#path#relative(v:val, base) })
  call map(rs, { -> printf('-reveal=%s', v:val) })
  return rs
endfunction

function! s:to_fri(path) abort
  return fern#fri#format({
        \ 'scheme': 'file',
        \ 'authority': '',
        \ 'path': a:path[1:],
        \ 'query': {},
        \ 'fragment': '',
        \})
endfunction
