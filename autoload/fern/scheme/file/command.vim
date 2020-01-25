function! fern#scheme#file#command#norm(url) abort
  let path = s:norm_path(a:url.path)
  let path = filereadable(path) ? fnamemodify(path, ':h') : path

  if !empty(get(a:url.query, 'reveal'))
    let a:url.query.reveal = s:norm_reveal(path, a:url.query.reveal)
  endif

  return extend(a:url, { 'path': path })
endfunction

function! s:norm_path(path) abort
  let path = simplify(expand(a:path))
  let path = fnamemodify(path, ':p')
  let path = fnamemodify(path, ':gs?\\?/?')
  return path
endfunction

function! s:norm_reveal(path, reveal) abort
  let reveal = s:norm_path(a:reveal)
  if reveal =~# '^' . fern#lib#string#escape_pattern(a:path)
    return reveal[len(a:path):]
  endif
  return fnamemodify(reveal, ':.')
endfunction
