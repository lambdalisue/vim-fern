function! fern#internal#viewer#auto_duplication#init() abort
  if g:fern#disable_viewer_auto_duplication ||
    \ (g:fern#disable_drawer_tabpage_isolation && fern#internal#drawer#is_drawer())
    return
  endif

  augroup fern_internal_viewer_auto_duplication_init
    autocmd! * <buffer>
    autocmd WinEnter <buffer> nested call s:duplicate()
  augroup END
endfunction

function! s:duplicate() abort
  if s:count_non_popup_windows('%') < 2
    return
  endif
  " Only one window is allowed to display one fern buffer.
  " So create a new fern buffer with same options
  let fri = fern#fri#parse(bufname('%'))
  let fri.authority = ''
  let bufname = fern#fri#format(fri)
  execute printf('silent! keepalt edit %s', fnameescape(bufname))
endfunction

function! s:count_non_popup_windows(expr) abort
  let winids = win_findbuf(bufnr(a:expr))
  return len(filter(winids, {_, v -> !s:is_popup_window(v)}))
endfunction

if exists('*win_gettype')
  function! s:is_popup_window(winid) abort
    return win_gettype(a:winid) ==# 'popup'
  endfunction
elseif exists('*nvim_win_get_config')
  function! s:is_popup_window(winid) abort
    return nvim_win_get_config(a:winid).relative !=# ''
  endfunction
else
  function! s:is_popup_window(winid) abort
    return getbufvar(winbufnr(a:winid), '&buftype') ==# 'popup'
  endfunction
endif
