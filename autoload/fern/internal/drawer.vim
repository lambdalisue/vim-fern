function! fern#internal#drawer#open(fri, ...) abort
  let options = extend({
        \ 'toggle': 0,
        \}, a:0 ? a:1 : {},
        \)
  if s:focus_next()
    if winnr('$') > 1
      if options.toggle
        close
        return
      endif
      let options.opener = 'edit'
    endif
  endif
  return fern#internal#viewer#open(a:fri, options)
endfunction

function! fern#internal#drawer#init() abort
  if !fern#internal#drawer#is_drawer()
    return
  endif

  setlocal winfixwidth

  augroup fern_drawer_internal
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:auto_quit()
    autocmd BufEnter <buffer> call s:auto_resize()
    autocmd BufLeave <buffer> call s:auto_resize()
  augroup END
endfunction

function! fern#internal#drawer#is_drawer(...) abort
  let bufname = a:0 ? a:1 : bufname('%')
  let fri = fern#fri#parse(bufname)
  return fri.scheme ==# 'fern' && fri.authority =~# '\<drawer\>'
endfunction

function! s:focus_next() abort
  let winnr = fern#internal#window#find(
        \ { w -> fern#internal#drawer#is_drawer(bufname(winbufnr(w))) },
        \)
  if winnr is# 0
    return
  endif
  noautocmd call win_gotoid(win_getid(winnr))
  return 1
endfunction

function! s:auto_resize() abort
  let fri = fern#internal#bufname#parse(bufname('%'))
  let width = str2nr(get(fri.query, 'width', string(g:fern#drawer_width)))
  execute 'vertical resize' width
endfunction

function! s:auto_quit() abort
  let fri = fern#internal#bufname#parse(bufname('%'))
  let keep = get(fri.query, 'keep', g:fern#drawer_keep)
  let width = str2nr(get(fri.query, 'width', string(g:fern#drawer_width)))
  if winnr('$') isnot# 1
    " Not a last window
    return
  elseif keep
    " Add a new window to avoid being a last window
    vertical botright new
    keepjumps wincmd p
    execute 'vertical resize' width
  else
    " This window is a last window of a current tabpage
    quit
  endif
endfunction
