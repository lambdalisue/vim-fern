function! fern#internal#viewer#hide_cursorline#init() abort
  if g:fern#hide_cursorline
    call s:hide_cursorline_init()
  endif
endfunction

function! s:hide_cursorline_init() abort
  augroup fern_internal_viewer_smart_cursor_line_init
    autocmd! * <buffer>
    autocmd BufEnter,WinEnter,TabLeave,CmdwinLeave,CmdlineLeave <buffer> setlocal cursorline
    autocmd BufLeave,WinLeave,TabLeave,CmdwinEnter,CmdlineEnter <buffer> setlocal nocursorline
  augroup END

  " Do NOT allow cursorlineopt=number while the cursor is hidden (Fix #182)
  if exists('+cursorlineopt')
    " NOTE:
    " Default value is `number,line` (or `both` prior to patch-8.1.2029)
    setlocal cursorlineopt&
  endif
endfunction
