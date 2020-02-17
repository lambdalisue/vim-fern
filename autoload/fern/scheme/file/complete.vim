function! fern#scheme#file#complete#url(arglead, cmdline, cursorpos) abort
  let path = '/' . fern#fri#parse(a:arglead).path
  let path = fern#internal#filepath#to_slash(path)
  let rs = getcompletion(fern#internal#filepath#from_slash(path), 'dir')
  call map(rs, { -> fern#internal#filepath#to_slash(v:val) })
  call map(rs, { -> s:to_fri(v:val) })
  return rs
endfunction

function! fern#scheme#file#complete#reveal(arglead, cmdline, cursorpos) abort
  let base = '/' . fern#fri#parse(matchstr(a:cmdline, '\<file:///\S*')).path
  let path = matchstr(a:arglead, '^-reveal=\zs.*')
  let path = fern#internal#filepath#to_slash(path)
  let path = fern#internal#path#absolute(path, base)
  let rs = getcompletion(fern#internal#filepath#from_slash(path), 'dir')
  call map(rs, { -> fern#internal#filepath#to_slash(v:val) })
  call map(rs, { -> fern#internal#path#relative(v:val, base) })
  call map(rs, { -> printf('-reveal=%s', v:val) })
  return rs
endfunction

function! s:to_fri(path) abort
  return fern#fri#format({
        \ 'scheme': 'file',
        \ 'authority': '',
        \ 'path': a:path,
        \ 'query': {},
        \ 'fragment': '',
        \})
endfunction
