let s:Promise = vital#fern#import('Async.Promise')
let s:WindowCursor = vital#fern#import('Vim.Window.Cursor')

function! fern#helper#sync#new(helper) abort
  let sync = extend({ 'helper': a:helper }, s:sync)
  let sync.__cache = {
        \ 'previous_cursor_node': v:null,
        \}
  return sync
endfunction

let s:sync = {}

function! s:sync_winid() abort dict
  let helper = self.helper
  if win_id2tabwin(helper.winid) != [0, 0]
    return helper.winid
  endif
  " Original window has disappeared
  let winids = win_findbuf(helper.bufnr)
  let helper.winid = len(winids) is# 0 ? -1 : winids[0]
  return helper.winid
endfunction
let s:sync.winid = funcref('s:sync_winid')

function! s:sync_echo(message, ...) abort dict
  let hl = a:0 ? a:1 : 'None'
  try
    execute printf('echohl %s', hl)
    echo a:message
  finally
    echohl None
  endtry
endfunction
let s:sync.echo = funcref('s:sync_echo')

function! s:sync_echomsg(message, ...) abort dict
  let hl = a:0 ? a:1 : 'None'
  try
    execute printf('echohl %s', hl)
    echomsg a:message
  finally
    echohl None
  endtry
endfunction
let s:sync.echomsg = funcref('s:sync_echomsg')

function! s:sync_get_root_node() abort dict
  let helper = self.helper
  let fern = helper.fern
  return fern.root
endfunction
let s:sync.get_root_node = funcref('s:sync_get_root_node')

function! s:sync_get_cursor_node() abort dict
  let helper = self.helper
  let fern = helper.fern
  let cursor = self.get_cursor()
  let index = fern.renderer.index(cursor[0])
  return get(fern.visible_nodes, index, v:null)
endfunction
let s:sync.get_cursor_node = funcref('s:sync_get_cursor_node')

function! s:sync_get_marked_nodes() abort dict
  let helper = self.helper
  let fern = helper.fern
  let ms = fern.marks
  return filter(
        \ copy(fern.visible_nodes),
        \ { _, v -> index(ms, v.__key) isnot# -1 },
        \)
endfunction
let s:sync.get_marked_nodes = funcref('s:sync_get_marked_nodes')

function! s:sync_get_selected_nodes() abort dict
  let helper = self.helper
  let fern = helper.fern
  if empty(fern.marks)
    return [self.get_cursor_node()]
  endif
  return self.get_marked_nodes()
endfunction
let s:sync.get_selected_nodes = funcref('s:sync_get_selected_nodes')

function! s:sync_get_cursor() abort dict
  let helper = self.helper
  let fern = helper.fern
  let winid = self.winid()
  if winid is# -1
    return [0, 0]
  endif
  return s:WindowCursor.get_cursor(winid)
endfunction
let s:sync.get_cursor = funcref('s:sync_get_cursor')

function! s:sync_set_cursor(cursor) abort dict
  let helper = self.helper
  let fern = helper.fern
  let winid = self.winid()
  if winid is# -1
    return
  endif
  call s:WindowCursor.set_cursor(winid, a:cursor)
  call setbufvar(helper.bufnr, 'fern_cursor', a:cursor)
endfunction
let s:sync.set_cursor = funcref('s:sync_set_cursor')

function! s:sync_save_cursor() abort dict
  let helper = self.helper
  let fern = helper.fern
  let self.__cache.previous_cursor_node = self.get_cursor_node()
  return s:Promise.resolve()
endfunction
let s:sync.save_cursor = funcref('s:sync_save_cursor')

function! s:sync_restore_cursor() abort dict
  let helper = self.helper
  let fern = helper.fern
  if empty(self.__cache.previous_cursor_node)
    return s:Promise.resolve()
  endif
  return self.focus_node(self.__cache.previous_cursor_node.__key)
endfunction
let s:sync.restore_cursor = funcref('s:sync_restore_cursor')

function! s:sync_cancel() abort dict
  let helper = self.helper
  let fern = helper.fern
  call fern#internal#core#cancel(fern)
endfunction
let s:sync.cancel = funcref('s:sync_cancel')

function! s:sync_is_drawer() abort dict
  let helper = self.helper
  let fern = helper.fern
  return fern#internal#drawer#is_drawer(bufname(helper.bufnr))
endfunction
let s:sync.is_drawer = funcref('s:sync_is_drawer')

function! s:sync_is_left_drawer() abort dict
  let helper = self.helper
  let fern = helper.fern
  return fern#internal#drawer#is_left_drawer(bufname(helper.bufnr))
endfunction
let s:sync.is_left_drawer = funcref('s:sync_is_left_drawer')

function! s:sync_is_right_drawer() abort dict
  let helper = self.helper
  let fern = helper.fern
  return fern#internal#drawer#is_right_drawer(bufname(helper.bufnr))
endfunction
let s:sync.is_right_drawer = funcref('s:sync_is_right_drawer')

function! s:sync_get_scheme() abort dict
  let helper = self.helper
  let fern = helper.fern
  let fri = fern#fri#parse(bufname(helper.bufnr))
  let fri = fern#fri#parse(fri.path)
  return fri.scheme
endfunction
let s:sync.get_scheme = funcref('s:sync_get_scheme')

function! s:sync_process_node(node) abort dict
  return fern#internal#node#process(a:node)
endfunction
let s:sync.process_node = funcref('s:sync_process_node')

function! s:sync_focus_node(key, ...) abort dict
  let helper = self.helper
  let fern = helper.fern
  let options = extend({
        \ 'offset': 0,
        \ 'previous': v:null
        \}, a:0 ? a:1 : {})
  let index = fern#internal#node#index(a:key, fern.visible_nodes)
  if index is# -1
    if !empty(a:key)
      return self.focus_node(a:key[:-2], options)
    endif
    throw printf('failed to find a node %s', a:key)
  endif
  let current = self.get_cursor_node()
  if options.previous is# v:null || options.previous == current
    let lnum = fern.renderer.lnum(index + options.offset)
    call self.set_cursor([lnum, 1])
  endif
endfunction
let s:sync.focus_node = funcref('s:sync_focus_node')
