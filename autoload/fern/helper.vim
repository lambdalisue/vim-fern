let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:Promise = vital#fern#import('Async.Promise')
let s:WindowCursor = vital#fern#import('Vim.Window.Cursor')
let s:CancellationTokenSource = vital#fern#import('Async.CancellationTokenSource')

function! fern#helper#new(...) abort
  let bufnr = a:0 ? a:1 : bufnr('%')
  let fern = getbufvar(bufnr, 'fern', v:null)
  if fern is# v:null
    throw printf("the buffer %s is not properly initialized for fern", bufnr)
  endif
  let helper = extend({
        \ 'fern': fern,
        \ 'bufnr': bufnr,
        \ 'winid': bufwinid(bufnr),
        \ 'STATUS_NONE': g:fern#internal#node#STATUS_NONE,
        \ 'STATUS_COLLAPSED': g:fern#internal#node#STATUS_COLLAPSED,
        \ 'STATUS_EXPANDED': g:fern#internal#node#STATUS_EXPANDED,
        \ '__cache': {
        \   'previous_cursor_node': v:null,
        \ },
        \}, s:helper)
  lockvar 2 helper
  return helper
endfunction

function! fern#helper#call(fn, ...) abort
  return call(a:fn, [fern#helper#new()] + a:000)
endfunction

let s:helper = {}

" Sync
function! s:helper.get_root_node() abort
  return self.fern.root
endfunction

function! s:helper.get_cursor_node() abort
  let cursor = self.get_cursor()
  return get(self.fern.visible_nodes, cursor[0] - 1, v:null)
endfunction

function! s:helper.get_marked_nodes() abort
  let ms = self.fern.marks
  return filter(
        \ copy(self.fern.visible_nodes),
        \ { _, v -> index(ms, v.__key) isnot# -1 },
        \)
endfunction

function! s:helper.get_selected_nodes() abort
  if empty(self.fern.marks)
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
  call fern#internal#core#cancel(self.fern)
endfunction

function! s:helper.process_node(node) abort
  return fern#internal#node#process(a:node)
endfunction

function! s:helper.is_drawer() abort
  return fern#internal#drawer#is_drawer(bufname(self.bufnr))
endfunction


" Async
function! s:helper.sleep(ms) abort
  return s:Promise.new({ resolve -> timer_start(a:ms, { -> resolve() }) })
endfunction

function! s:helper.redraw() abort
  let Profile = fern#profile#start("fern#helper:helper.redraw")
  return s:Promise.resolve()
        \.then({ -> fern#internal#renderer#render(
        \   self.fern.visible_nodes,
        \   self.fern.marks,
        \ )
        \})
        \.then({ v -> fern#lib#buffer#replace(self.bufnr, v) })
        \.finally({ -> Profile() })
endfunction

function! s:helper.update_nodes(nodes) abort
  let Profile = fern#profile#start("fern#helper:helper.update_nodes")
  return self.save_cursor()
        \.then({ -> fern#internal#core#update_nodes(self.fern, a:nodes) })
        \.then({ -> self.restore_cursor() })
        \.finally({ -> Profile() })
endfunction

function! s:helper.update_marks(marks) abort
  let Profile = fern#profile#start("fern#helper:helper.update_marks")
  return fern#internal#core#update_marks(self.fern, a:marks)
        \.finally({ -> Profile() })
endfunction

function! s:helper.expand_node(key) abort
  let node = fern#internal#node#find(a:key, self.fern.nodes)
  if empty(node)
    return s:Promise.reject(printf('failed to find a node %s', a:key))
  elseif node.status is# self.STATUS_NONE
    " To improve UX, reload owner instead
    return self.reload_node(node.__owner.__key)
  elseif node.status is# self.STATUS_EXPANDED
    " To improve UX, reload instead
    return self.reload_node(node.__key)
  endif
  let Profile = fern#profile#start("fern#helper:helper.expand_node")
  return s:Promise.resolve()
        \.then({ -> fern#internal#node#expand(
        \   node,
        \   self.fern.nodes,
        \   self.fern.provider,
        \   self.fern.comparator,
        \   self.fern.source.token,
        \ )
        \})
        \.then({ ns -> self.update_nodes(ns) })
        \.finally({ -> Profile() })
endfunction

function! s:helper.collapse_node(key) abort
  let node = fern#internal#node#find(a:key, self.fern.nodes)
  if empty(node)
    return s:Promise.reject(printf('failed to find a node %s', a:key))
  elseif node.__owner is# v:null
    " To improve UX, root node should NOT be collapsed and reload instead.
    return self.reload_node(node.__key)
  elseif node.status isnot# self.STATUS_EXPANDED
    " To improve UX, collapse a owner node instead
    return self.collapse_node(node.__owner.__key)
  endif
  let Profile = fern#profile#start("fern#helper:helper.collapse_node")
  return s:Promise.resolve()
        \.then({ -> fern#internal#node#collapse(
        \   node,
        \   self.fern.nodes,
        \   self.fern.provider,
        \   self.fern.comparator,
        \   self.fern.source.token,
        \ )
        \})
        \.then({ ns -> self.update_nodes(ns) })
        \.finally({ -> Profile() })
endfunction

function! s:helper.reload_node(key) abort
  let node = fern#internal#node#find(a:key, self.fern.nodes)
  if empty(node)
    return s:Promise.reject(printf('failed to find a node %s', a:key))
  endif
  let Profile = fern#profile#start("fern#helper:helper.reload_node")
  return s:Promise.resolve()
        \.then({ -> fern#internal#node#reload(
        \   node,
        \   self.fern.nodes,
        \   self.fern.provider,
        \   self.fern.comparator,
        \   self.fern.source.token,
        \ )
        \})
        \.then({ ns -> self.update_nodes(ns) })
        \.finally({ -> Profile() })
endfunction

function! s:helper.reveal_node(key) abort
  let Profile = fern#profile#start("fern#helper:helper.reveal_node")
  return s:Promise.resolve()
        \.then({ -> fern#internal#node#reveal(
        \   a:key,
        \   self.fern.nodes,
        \   self.fern.provider,
        \   self.fern.comparator,
        \   self.fern.source.token,
        \ )
        \})
        \.then({ ns -> self.update_nodes(ns) })
        \.finally({ -> Profile() })
endfunction

function! s:helper.focus_node(key, ...) abort
  let options = extend({
        \ 'offset': 0,
        \ 'previous': v:null
        \}, a:0 ? a:1 : {})
  let index = fern#internal#node#index(a:key, self.fern.visible_nodes)
  if index is# -1
    if !empty(a:key)
      return self.focus_node(a:key[:-2], options)
    endif
    return s:Promise.reject(printf('failed to find a node %s', a:key))
  endif
  let Profile = fern#profile#start("fern#helper:helper.focus_node")
  let current = self.get_cursor_node()
  if options.previous is# v:null || options.previous == current
    call self.set_cursor([index + 1 + options.offset, 1])
  endif
  return s:Promise.resolve()
        \.finally({ -> Profile() })
endfunction

function! s:helper.set_mark(key, value) abort
  let index = index(self.fern.marks, a:key)
  if !xor(index isnot# -1, a:value)
    return s:Promise.resolve()
  endif
  if a:value
    call add(self.fern.marks, a:key)
  elseif index isnot# -1
    call remove(self.fern.marks, index)
  endif
  return self.update_marks(self.fern.marks)
endfunction

function! s:helper.set_hide(value) abort
  if !xor(self.fern.hide, a:value)
    return s:Promise.resolve()
  endif
  let self.fern.hide = a:value
  return self.update_nodes(self.fern.nodes)
endfunction

function! s:helper.set_include(pattern) abort
  if self.fern.include ==# a:pattern
    return s:Promise.resolve()
  endif
  let self.fern.include = a:pattern
  return self.update_nodes(self.fern.nodes)
endfunction

function! s:helper.set_exclude(pattern) abort
  if self.fern.exclude ==# a:pattern
    return s:Promise.resolve()
  endif
  let self.fern.exclude = a:pattern
  return self.update_nodes(self.fern.nodes)
endfunction

function! s:helper.enter_tree(node) abort
  if a:node.status is# self.STATUS_NONE
    return s:Promise.reject()
  endif
  return s:Promise.resolve(a:node)
        \.then({ n -> s:enter(self.fern, n) })
endfunction

function! s:helper.leave_tree() abort
  let root = self.get_root_node()
  return s:Promise.resolve()
        \.then({ -> fern#internal#node#parent(
        \   root,
        \   self.fern.provider,
        \   self.fern.source.token,
        \ )
        \})
        \.then({ n -> s:enter(self.fern, n) })
        \.then({ -> fern#helper#new(winbufnr(self.winid)) })
        \.then({ h -> h.focus_node([root.name]) })
endfunction


" Private
function! s:enter(fern, node) abort
  if !has_key(a:node, 'bufname')
    return s:Promise.reject('the node does not have bufname attribute')
  endif
  try
    let cur = fern#internal#bufname#parse(bufname('%'))
    let fri = fern#internal#bufname#parse(a:node.bufname)
    let fri.authority = cur.authority
    let fri.query = cur.query
    return fern#internal#viewer#open(fri, {})
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction
