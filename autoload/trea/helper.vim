let s:Lambda = vital#trea#import('Lambda')
let s:AsyncLambda = vital#trea#import('Async.Lambda')
let s:Promise = vital#trea#import('Async.Promise')
let s:WindowCursor = vital#trea#import('Vim.Window.Cursor')
let s:CancellationTokenSource = vital#trea#import('Async.CancellationTokenSource')

function! trea#helper#new(...) abort
  let bufnr = a:0 ? a:1 : bufnr('%')
  let trea = getbufvar(bufnr, 'trea', v:null)
  if trea is# v:null
    throw printf("the buffer %s is not properly initialized for trea", bufnr)
  endif
  let helper = extend({
        \ 'trea': trea,
        \ 'bufnr': bufnr,
        \ 'winid': bufwinid(bufnr),
        \ 'STATUS_NONE': g:trea#internal#node#STATUS_NONE,
        \ 'STATUS_COLLAPSED': g:trea#internal#node#STATUS_COLLAPSED,
        \ 'STATUS_EXPANDED': g:trea#internal#node#STATUS_EXPANDED,
        \ '__cache': {
        \   'previous_cursor_node': v:null,
        \ },
        \}, s:helper)
  lockvar 2 helper
  return helper
endfunction

function! trea#helper#call(fn, ...) abort
  return call(a:fn, [trea#helper#new()] + a:000)
endfunction

let s:helper = {}

" Sync
function! s:helper.get_root_node() abort
  return self.trea.root
endfunction

function! s:helper.get_cursor_node() abort
  let cursor = self.get_cursor()
  return get(self.trea.visible_nodes, cursor[0] - 1, v:null)
endfunction

function! s:helper.get_marked_nodes() abort
  let ms = self.trea.marks
  return filter(
        \ copy(self.trea.visible_nodes),
        \ { _, v -> index(ms, v.__key) isnot# -1 },
        \)
endfunction

function! s:helper.get_selected_nodes() abort
  if empty(self.trea.marks)
    return [self.get_cursor_node()]
  endif
  return self.get_marked_nodes()
endfunction

function! s:helper.get_cursor() abort
  return s:WindowCursor.get_cursor(self.winid)
endfunction

function! s:helper.set_cursor(cursor) abort
  call s:WindowCursor.set_cursor(self.winid, a:cursor)
endfunction

function! s:helper.save_cursor() abort
  let self.__cache.previous_cursor_node = self.get_cursor_node()
  return s:Promise.resolve()
endfunction

function! s:helper.restore_cursor() abort
  if empty(self.__cache.previous_cursor_node)
    return s:Promise.resolve()
  endif
  return self.focus_node(self.__cache.previous_cursor_node.__key)
endfunction

function! s:helper.cancel() abort
  call trea#internal#core#cancel(self.trea)
endfunction

function! s:helper.process_node(node) abort
  return trea#internal#node#process(a:node)
endfunction

function! s:helper.is_drawer() abort
  return trea#internal#drawer#parse(bufname(self.bufnr)) isnot# v:null
endfunction


" Async
function! s:helper.sleep(ms) abort
  return s:Promise.new({ resolve -> timer_start(a:ms, { -> resolve() }) })
endfunction

function! s:helper.redraw() abort
  return s:Promise.resolve()
        \.then({ -> trea#internal#renderer#render(
        \   self.trea.visible_nodes,
        \   self.trea.marks,
        \ )
        \})
        \.then({ v -> trea#lib#buffer#replace(self.bufnr, v) })
endfunction

function! s:helper.update_nodes(nodes) abort
  return self.save_cursor()
        \.then({ -> trea#internal#core#update_nodes(self.trea, a:nodes) })
        \.then({ -> self.restore_cursor() })
endfunction

function! s:helper.update_marks(marks) abort
  return trea#internal#core#update_marks(self.trea, a:marks)
endfunction

function! s:helper.expand_node(key) abort
  let node = trea#internal#node#find(a:key, self.trea.nodes)
  if empty(node)
    return s:Promise.reject(printf('failed to find a node %s', a:key))
  endif
  return s:Promise.resolve()
        \.then({ -> trea#internal#node#expand(
        \   node,
        \   self.trea.nodes,
        \   self.trea.provider,
        \   self.trea.comparator,
        \   self.trea.source.token,
        \ )
        \})
        \.then({ ns -> self.update_nodes(ns) })
endfunction

function! s:helper.collapse_node(key) abort
  let node = trea#internal#node#find(a:key, self.trea.nodes)
  if empty(node)
    return s:Promise.reject(printf('failed to find a node %s', a:key))
  endif
  return s:Promise.resolve()
        \.then({ -> trea#internal#node#collapse(
        \   node,
        \   self.trea.nodes,
        \   self.trea.provider,
        \   self.trea.comparator,
        \   self.trea.source.token,
        \ )
        \})
        \.then({ ns -> self.update_nodes(ns) })
endfunction

function! s:helper.reload_node(key) abort
  let node = trea#internal#node#find(a:key, self.trea.nodes)
  if empty(node)
    return s:Promise.reject(printf('failed to find a node %s', a:key))
  endif
  return s:Promise.resolve()
        \.then({ -> trea#internal#node#reload(
        \   node,
        \   self.trea.nodes,
        \   self.trea.provider,
        \   self.trea.comparator,
        \   self.trea.source.token,
        \ )
        \})
        \.then({ ns -> self.update_nodes(ns) })
endfunction

function! s:helper.reveal_node(key) abort
  return s:Promise.resolve()
        \.then({ -> trea#internal#node#reveal(
        \   a:key,
        \   self.trea.nodes,
        \   self.trea.provider,
        \   self.trea.comparator,
        \   self.trea.source.token,
        \ )
        \})
        \.then({ ns -> self.update_nodes(ns) })
endfunction

function! s:helper.focus_node(key, ...) abort
  let options = extend({
        \ 'offset': 0,
        \ 'previous': v:null
        \}, a:0 ? a:1 : {})
  let index = trea#internal#node#index(a:key, self.trea.visible_nodes)
  if index is# -1
    if !empty(a:key)
      return self.focus_node(a:key[:-2], options)
    endif
    return s:Promise.reject(printf('failed to find a node %s', a:key))
  endif
  let current = self.get_cursor_node()
  if options.previous is# v:null || options.previous == current
    call self.set_cursor([index + 1 + options.offset, 1])
  endif
  return s:Promise.resolve()
endfunction

function! s:helper.set_mark(key, value) abort
  let index = index(self.trea.marks, a:key)
  if !xor(index isnot# -1, a:value)
    return s:Promise.resolve()
  endif
  if a:value
    call add(self.trea.marks, a:key)
  elseif index isnot# -1
    call remove(self.trea.marks, index)
  endif
  return self.update_marks(self.trea.marks)
endfunction

function! s:helper.set_hide(value) abort
  if !xor(self.trea.hide, a:value)
    return s:Promise.resolve()
  endif
  let self.trea.hide = a:value
  return self.update_nodes(self.trea.nodes)
endfunction

function! s:helper.set_include(pattern) abort
  if self.trea.include ==# a:pattern
    return s:Promise.resolve()
  endif
  let self.trea.include = a:pattern
  return self.update_nodes(self.trea.nodes)
endfunction

function! s:helper.set_exclude(pattern) abort
  if self.trea.exclude ==# a:pattern
    return s:Promise.resolve()
  endif
  let self.trea.exclude = a:pattern
  return self.update_nodes(self.trea.nodes)
endfunction

function! s:helper.enter_tree(node) abort
  if a:node.status is# self.STATUS_NONE
    return s:Promise.reject()
  endif
  return s:Promise.resolve(a:node)
        \.then({ n -> s:enter(self.trea, n) })
endfunction

function! s:helper.leave_tree() abort
  return s:Promise.resolve(self.trea.root)
        \.then({ root -> trea#internal#node#parent(
        \   root,
        \   self.trea.provider,
        \   self.trea.source.token,
        \ )
        \})
        \.then({ n -> s:enter(self.trea, n) })
endfunction


" Private
function! s:enter(trea, node) abort
  if !has_key(a:node, 'bufname')
    return s:Promise.reject('the node does not have bufname attribute')
  endif
  return trea#internal#viewer#open(a:node.bufname, {
        \ 'base': bufname("%"),
        \})
endfunction
