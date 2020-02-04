let s:Path = vital#fern#import('System.Filepath')
let s:is_windows = has('win32')

function! fern#scheme#file#complete#url(arglead, cmdline, cursorpos) abort
  let fri = fern#fri#parse(a:arglead)
  let path = s:Path.from_slash(fri.path)
  let path = !s:is_windows ? '/' . path : path
  return map(
        \ getcompletion(path, 'dir'),
        \ { _, v -> s:to_fri(v) },
        \)
endfunction

function! fern#scheme#file#complete#reveal(arglead, cmdline, cursorpos) abort
  let base = fern#fri#parse(matchstr(a:cmdline, '\<file:///\S*')).path
  let base = s:Path.from_slash(base)
  let base = !s:is_windows ? '/' . base : base
  let path = matchstr(a:arglead, '^-reveal=\zs.*')
  let path = s:Path.from_slash(path)
  let n = len(base)
  let rs = getcompletion(s:Path.join(base, path), 'dir')
  let rs = map(rs, { -> v:val[n :] })
  return map(rs, { -> printf('-reveal=%s', s:to_path(v:val)) })
endfunction

function! s:to_path(path) abort
  let path = s:Path.to_slash(a:path)
  let path = fern#fri#encode(path)
  return join(split(path, '/'), '/')
endfunction

function! s:to_fri(path) abort
  let fri = {
        \ 'scheme': 'file',
        \ 'authority': '',
        \ 'path': s:to_path(a:path),
        \ 'query': {},
        \ 'fragment': '',
        \}
  return fern#fri#format(fri)
endfunction
