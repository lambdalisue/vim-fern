function! fern#internal#viewer#hide_cursor#init() abort
  if !g:fern#hide_cursor
    return
  endif
  call s:hide_cursor_init()
endfunction

function! s:hide_cursor_init() abort
  augroup fern_internal_viewer_smart_cursor_init
    autocmd! * <buffer>
    autocmd BufEnter,WinEnter,TabLeave,CmdwinLeave,CmdlineLeave <buffer> setlocal cursorline
    autocmd BufLeave,WinLeave,TabLeave,CmdwinEnter,CmdlineEnter <buffer> setlocal nocursorline
    autocmd BufEnter,WinEnter,TabLeave,CmdwinLeave,CmdlineLeave <buffer> call fern#internal#cursor#hide()
    autocmd BufLeave,WinLeave,TabLeave,CmdwinEnter,CmdlineEnter <buffer> call fern#internal#cursor#restore()
    autocmd VimLeave <buffer> call fern#internal#cursor#restore()
  augroup END

  " Do NOT allow cursorlineopt=number while the cursor is hidden (Fix #182)
  if exists('+cursorlineopt')
    " NOTE:
    " Default value is `number,line` (or `both` prior to patch-8.1.2029)
    setlocal cursorlineopt&
  endif
endfunction
