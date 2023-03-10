let s:root = expand('<sfile>:p:h')
let s:Config = vital#fern#import('Config')

" Define Public constant
const g:fern#STATUS_NONE = 0
const g:fern#STATUS_COLLAPSED = 1
const g:fern#STATUS_EXPANDED = 2

const g:fern#DEBUG = 0
const g:fern#INFO = 1
const g:fern#WARN = 2
const g:fern#ERROR = 3

" Define Public variables
call s:Config.config(expand('<sfile>:p'), {
      \ 'profile': 0,
      \ 'logfile': v:null,
      \ 'loglevel': g:fern#INFO,
      \ 'opener': 'edit',
      \ 'hide_cursor': 0,
      \ 'keepalt_on_edit': 0,
      \ 'keepjumps_on_edit': 0,
      \ 'disable_auto_buffer_delete': 0,
      \ 'disable_auto_buffer_rename': 0,
      \ 'disable_default_mappings': 0,
      \ 'disable_viewer_spinner': has('win32') && !has('gui_running'),
      \ 'disable_viewer_auto_duplication': 0,
      \ 'disable_drawer_auto_winfixwidth': 0,
      \ 'disable_drawer_auto_resize': 0,
      \ 'disable_drawer_smart_quit': get(g:, 'disable_drawer_auto_quit', 0),
      \ 'disable_drawer_hover_popup': 0,
      \ 'disable_drawer_tabpage_isolation': 0,
      \ 'disable_drawer_auto_restore_focus': 0,
      \ 'default_hidden': 0,
      \ 'default_include': '',
      \ 'default_exclude': '',
      \ 'renderer': 'default',
      \ 'renderers': {},
      \ 'enable_textprop_support': 0,
      \ 'comparator': 'default',
      \ 'comparators': {},
      \ 'drawer_width': 30,
      \ 'drawer_keep': v:false,
      \ 'drawer_hover_popup_delay': 0,
      \ 'mark_symbol': '*',
      \ 'window_selector_use_popup': 0,
      \})

function! fern#version() abort
  if !executable('git')
    echohl ErrorMsg
    echo '[fern] "git" is not executable'
    echohl None
    return
  endif
  let r = system(printf('git -C %s describe --tags --always --dirty', s:root))
  echo printf('[fern] %s', r)
endfunction
