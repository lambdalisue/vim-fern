function! fern#internal#viewer#hide_cursor#init() abort
  if g:fern#disable_viewer_hide_cursor
    return
  endif

  augroup fern_internal_viewer_hide_cursor_init
    autocmd! * <buffer>
    autocmd BufEnter,WinEnter,CmdwinLeave,CmdlineLeave <buffer> setlocal cursorline
    autocmd BufLeave,WinLeave,CmdwinEnter,CmdlineEnter <buffer> setlocal nocursorline
    autocmd BufEnter,WinEnter,CmdwinLeave,CmdlineLeave <buffer> call fern#internal#cursor#hide()
    autocmd BufLeave,WinLeave,CmdwinEnter,CmdlineEnter <buffer> call fern#internal#cursor#restore()
    autocmd VimLeave <buffer> call fern#internal#cursor#restore()
  augroup END
endfunction
