if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal cursorline
setlocal nolist nowrap nospell

if exists('&cursorlineopt')
  setlocal cursorlineopt=both
endif
