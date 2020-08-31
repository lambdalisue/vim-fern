if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal cursorline
setlocal nolist nowrap nospell

" Do NOT allow cursorlineopt=number while fern.vim hide cursor on
" its buffer unless g:fern#disable_viewer_hide_cursor has specified
" Fix #182
if exists('+cursorlineopt') && !g:fern#disable_viewer_hide_cursor
  setlocal cursorlineopt=number,line
endif
