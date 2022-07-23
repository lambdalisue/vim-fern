function! fern#internal#drawer#auto_resize#init() abort
  if g:fern#disable_drawer_auto_resize
    return
  endif

  if fern#internal#drawer#is_right_drawer()
    augroup fern_internal_drawer_init_right
      autocmd! * <buffer>
      autocmd BufEnter,WinEnter <buffer> call s:load_width_right()
      autocmd WinLeave <buffer> call s:save_width_right()
    augroup END
  else
    augroup fern_internal_drawer_init
      autocmd! * <buffer>
      autocmd BufEnter,WinEnter <buffer> call s:load_width()
      autocmd WinLeave <buffer> call s:save_width()
    augroup END
  endif
endfunction

function! s:count_others() abort
  let bufnr = bufnr('%')
  let bufnrs = map(range(0, winnr('$')), { -> winbufnr(v:val) })
  call filter(bufnrs, { -> bufnr isnot# v:val })
  return len(bufnrs)
endfunction

if has('nvim')
  function! s:should_ignore() abort
    return nvim_win_get_config(win_getid()).relative !=# '' || s:count_others() is# 0
  endfunction
else
  function! s:should_ignore() abort
    return s:count_others() is# 0
  endfunction
endif

function! s:save_width() abort
  if s:should_ignore()
    return
  endif
  let t:fern_drawer_auto_resize_width = winwidth(0)
endfunction

function! s:load_width() abort
  if s:should_ignore()
    return
  endif
  if !exists('t:fern_drawer_auto_resize_width')
    call fern#internal#drawer#resize()
  else
    execute 'vertical resize' t:fern_drawer_auto_resize_width
  endif
endfunction

function! s:save_width_right() abort
  if s:should_ignore()
    return
  endif
  let t:fern_drawer_auto_resize_width_right = winwidth(0)
endfunction

function! s:load_width_right() abort
  if s:should_ignore()
    return
  endif
  if !exists('t:fern_drawer_auto_resize_width_right')
    call fern#internal#drawer#resize()
  else
    execute 'vertical resize' t:fern_drawer_auto_resize_width_right
  endif
endfunction
