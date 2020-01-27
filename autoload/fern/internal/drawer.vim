function! fern#internal#drawer#open(bufname, ...) abort
  let options = extend({
        \ 'toggle': 0,
        \}, a:0 ? a:1 : {},
        \)
  if fern#internal#drawer#focus_next()
    if winnr('$') > 1
      if options.toggle
        close
        return
      endif
      let options.opener = 'edit'
    endif
  endif
  return fern#internal#viewer#open(a:bufname, options)
endfunction

function! fern#internal#drawer#init() abort
  if empty(fern#internal#drawer#parse(bufname('%')))
    return
  endif

  setlocal winfixwidth

  augroup fern_drawer_internal
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:keep_width()
    autocmd BufLeave <buffer> call s:keep_width()
  augroup END
endfunction

function! fern#internal#drawer#parse(...) abort
  let bufname = a:0 ? a:1 : bufname('%')
  let q = fern#lib#url#parse(bufname).query
  if empty(get(q, 'drawer'))
    return v:null
  endif
  return {
        \ 'width': str2nr(get(q, 'width', '30')),
        \ 'keep': !empty(get(q, 'keep', '')),
        \}
endfunction

function! fern#internal#drawer#focus_next(...) abort
  let options = extend({
        \ 'predicator': { -> 1 },
        \}, a:0 ? a:1 : {},
        \)
  let P = options.predicator
  return fern#internal#viewer#focus_next(extend(options, {
        \ 'predicator': { n ->
        \   fern#internal#drawer#parse(bufname(winbufnr(n))) isnot# v:null && P(n)
        \ }
        \}))
endfunction

function! fern#internal#drawer#do_next(command, ...) abort
  if fern#internal#drawer#focus_next(a:0 ? a:1 : {})
    execute a:command
  endif
endfunction

function! s:keep_width() abort
  let options = fern#internal#drawer#parse()
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
