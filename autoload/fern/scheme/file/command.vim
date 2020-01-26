function! fern#scheme#file#command#init(url, options) abort
  let a:url.authority = {
        \ 'userinfo': '',
        \ 'host': '',
        \ 'port': '',
        \}
  let a:url.path = s:norm_path(a:url.path, 1)
  let a:url.query.reveal = empty(a:url.query.reveal)
        \ ? a:url.query.reveal
        \ : s:norm_path(expand(a:url.query.reveal), 0)
endfunction

function! s:norm_path(path, force_directory) abort
  let path = a:path =~# '^file://'
        \ ? fern#lib#url#parse(a:path).path
        \ : simplify(fnamemodify(a:path, ':p'))
  if a:force_directory
    let path = filereadable(path) && !isdirectory(path)
          \ ? fnamemodify(path, ':h')
          \ : path
  endif
  let path = fnamemodify(path, ':gs?\\?/?')
  return path
endfunction
