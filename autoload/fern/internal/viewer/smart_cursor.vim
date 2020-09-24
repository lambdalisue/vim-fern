function! fern#internal#viewer#smart_cursor#init() abort
  if g:fern#disable_viewer_smart_cursor
    return
  endif
  if g:fern#smart_cursor ==# 'stick'
    call s:stick_cursor_init()
  elseif g:fern#smart_cursor ==# 'hide'
    call s:hide_cursor_init()
  else
    call fern#logger#warn(printf(
          \ '"%s" is not valid g:fern#smart_cursor. Use "stick" instead.',
          \ g:fern#smart_cursor,
          \))
    call s:stick_cursor_init()
  endif
endfunction

function! s:hide_cursor_init() abort
  augroup fern_internal_viewer_smart_cursor_init
    autocmd! * <buffer>
    autocmd BufEnter,WinEnter,CmdwinLeave,CmdlineLeave <buffer> setlocal cursorline
    autocmd BufLeave,WinLeave,CmdwinEnter,CmdlineEnter <buffer> setlocal nocursorline
    autocmd BufEnter,WinEnter,CmdwinLeave,CmdlineLeave <buffer> call fern#internal#cursor#hide()
    autocmd BufLeave,WinLeave,CmdwinEnter,CmdlineEnter <buffer> call fern#internal#cursor#restore()
    autocmd VimLeave <buffer> call fern#internal#cursor#restore()
  augroup END

" Do NOT allow cursorlineopt=number while the cursor is hidden (Fix #182)
  if exists('+cursorlineopt')
    setlocal cursorlineopt=number,line
  endif
endfunction

function! s:stick_cursor_init() abort
  augroup fern_internal_viewer_smart_cursor_init
    autocmd! * <buffer>
    autocmd CursorMoved,CursorMovedI <buffer> call cursor(line('.'), 1, 0)
  augroup END
endfunction
