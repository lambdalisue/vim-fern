let s:QuitPre_called = 0

function! fern#internal#drawer#auto_quit#init() abort
  if g:fern#disable_drawer_auto_quit
    return
  endif

  augroup fern_internal_drawer_auto_quit_init
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:auto_quit()
  augroup END
endfunction

function! s:auto_quit_pre() abort
  let s:QuitPre_called = 1
  call timer_start(0, { -> extend(s:, {'QuitPre_called': 1}) })
endfunction

function! s:auto_quit() abort
  if !s:QuitPre_called
    return
  endif
  let s:QuitPre_called = 0
  let fri = fern#fri#parse(bufname('%'))
  let keep = get(fri.query, 'keep', g:fern#drawer_keep)
  let width = str2nr(get(fri.query, 'width', string(g:fern#drawer_width)))
  if winnr('$') isnot# 1
    " Not a last window
    return
  elseif keep
    " Add a new window to avoid being a last window
    let winid = win_getid()
    if has('nvim')
      call s:complement(winid, width)
    else
      " Use timer to avoid E242 in Vim
      call timer_start(0, { -> s:complement(winid, width) })
    endif
  else
    " This window is a last window of a current tabpage
    quit
  endif
endfunction

function! s:complement(winid, width) abort
  keepjumps call win_gotoid(a:winid)
  silent! vertical botright new
  keepjumps call win_gotoid(a:winid)
  execute 'vertical resize' a:width
endfunction

augroup fern_internal_drawer_auto_quit
  autocmd!
  autocmd QuitPre * call s:auto_quit_pre()
augroup END
