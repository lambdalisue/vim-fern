function! trea#internal#drawer#init() abort
  if empty(trea#internal#drawer#parse(bufname('%')))
    return
  endif

  setlocal winfixwidth

  augroup trea_drawer_internal
    autocmd! *
    autocmd BufEnter <buffer> call s:keep_width()
    autocmd BufLeave <buffer> call s:keep_width()
  augroup END
endfunction

function! trea#internal#drawer#parse(...) abort
  let bufname = a:0 ? a:1 : bufname('%')
  let q = trea#lib#url#parse(bufname).query
  if empty(get(q, 'drawer'))
    return v:null
  endif
  return {
        \ 'width': str2nr(get(q, 'width', '30')),
        \ 'keep': !empty(get(q, 'keep', '')),
        \}
endfunction

function! trea#internal#drawer#focus_next(...) abort
  let options = extend({
        \ 'predicator': { -> 1 },
        \}, a:0 ? a:1 : {},
        \)
  let P = { n -> trea#internal#drawer#parse(bufname(winbufnr(n))) isnot# v:null && options.predicator(n) }
  return trea#internal#viewer#focus_next(extend(options, {
        \ 'predicator': P,
        \}))
endfunction

function! trea#internal#drawer#do_next(command, ...) abort
  if trea#internal#drawer#focus_next(a:0 ? a:1 : {})
    execute a:command
  endif
endfunction

function! s:keep_width() abort
  let options = trea#internal#drawer#parse()
  if winnr('$') isnot# 1
    execute 'vertical resize' options.width
    return
  elseif tabpagenr('$') isnot# 1
    close
  elseif !options.keep
    quit
  else
    vertical botright new
    keepjumps wincmd p
    execute 'vertical resize' options.width
  endif
endfunction
