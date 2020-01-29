function! fern#internal#drawer#open(fri, ...) abort
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
  return fern#internal#viewer#open(a:fri, options)
endfunction

function! fern#internal#drawer#init() abort
  if !fern#internal#drawer#is_drawer()
    return
  endif

  setlocal winfixwidth

  augroup fern_drawer_internal
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:keep_width()
    autocmd BufLeave <buffer> call s:keep_width()
  augroup END
endfunction

function! fern#internal#drawer#focus_next(...) abort
  let options = extend({
        \ 'predicator': { -> 1 },
        \}, a:0 ? a:1 : {},
        \)
  let P = options.predicator
  return fern#internal#viewer#focus_next(extend(options, {
        \ 'predicator': { n ->
        \   fern#internal#drawer#is_drawer(bufname(winbufnr(n))) && P(n)
        \ }
        \}))
endfunction

function! fern#internal#drawer#do_next(command, ...) abort
  if fern#internal#drawer#focus_next(a:0 ? a:1 : {})
    execute a:command
  endif
endfunction

function! fern#internal#drawer#is_drawer(...) abort
  let bufname = a:0 ? a:1 : bufname('%')
  let fri = fern#internal#bufname#parse(bufname)
  return fri.scheme ==# 'fern' && fri.authority =~# '\<drawer\>'
endfunction

function! s:keep_width() abort
  let fri = fern#internal#bufname#parse(bufname('%'))
  let width = str2nr(get(fri.query, 'width', '50'))
  let keep = str2nr(get(fri.query, 'keep', v:false))
  if winnr('$') isnot# 1
    execute 'vertical resize' width
    return
  elseif tabpagenr('$') isnot# 1
    close
  elseif !keep
    quit
  else
    vertical botright new
    keepjumps wincmd p
    execute 'vertical resize' width
  endif
endfunction
