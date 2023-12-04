function! fern#internal#viewer#hide_cursor#init() abort
  if g:fern#hide_cursor
    call s:hide_cursor_init()
  endif
endfunction

function! s:hide_cursor_init() abort
  augroup fern_internal_viewer_smart_cursor_init
    autocmd! * <buffer>
    autocmd BufEnter,WinEnter,TabLeave,CmdwinLeave,CmdlineLeave <buffer> call fern#internal#cursor#hide()
    autocmd BufLeave,WinLeave,TabLeave,CmdwinEnter,CmdlineEnter <buffer> call fern#internal#cursor#restore()
    autocmd VimLeave <buffer> call fern#internal#cursor#restore()
  augroup END
endfunction
