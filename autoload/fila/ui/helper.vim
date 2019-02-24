let s:Promise = vital#fila#import('Async.Promise')
let s:Lambda = vital#fila#import('Lambda')
let s:BufferWriter = vital#fila#import('Vim.Buffer.Writer')
let s:WindowCursor = vital#fila#import('Vim.Window.Cursor')
let s:Config = vital#fila#import('Config')

let s:STATUS_NONE      = g:fila#tree#item#STATUS_NONE
let s:STATUS_COLLAPSED = g:fila#tree#item#STATUS_COLLAPSED
let s:STATUS_EXPANDED  = g:fila#tree#item#STATUS_EXPANDED

function! fila#ui#helper#get(...) abort
  let bufnr = a:0 ? a:1 : bufnr('%')
  let provider = getbufvar(bufnr, 'fila_provider', v:null)
  if provider is# v:null
    throw fila#error#new('buffer does not have provider', {'bufnr': bufnr})
  endif
  return s:new(bufnr, provider)
endfunction

function! s:new(bufnr, provider) abort
  let helper = {
        \ 'bufnr': a:bufnr,
        \ 'provider': a:provider,
        \ 'renderer': fila#renderer#default#new(),
        \ 'comparator': fila#comparator#default#new(),
        \ 'resource_uri': '',
        \ 'hidden_patterns': [
        \   '^\.',
        \   '^__pycache__$',
        \ ],
        \}
  return extend(helper, s:helper)
endfunction

function! s:ensure_bufexists(bufnr) abort
  if !bufexists(a:bufnr)
    throw fila#error#new('buffer does not exist', {
          \ 'bufnr': a:bufnr,
          \})
  endif
endfunction

function! s:helper_is_hidden(resource_uri) abort dict
  if empty(a:resource_uri)
    return 1
  endif
  let last = split(a:resource_uri, '/')[-1]
  for pattern in self.hidden_patterns
    if last =~# pattern
      return 1
    endif
  endfor
  return 0
endfunction

function! s:helper_get_item(resource_uri, ...) abort dict
  let items = a:0 ? a:1 : self.get_items()
  let index = fila#tree#util#_index(a:resource_uri, items)
  if index is# -1
    throw fila#error#new('item does not exist', {
          \ 'resource_uri': a:resource_uri,
          \})
  endif
  return items[index]
endfunction

function! s:helper_get_items() abort dict
  call s:ensure_bufexists(self.bufnr)
  let items = getbufvar(self.bufnr, 'fila_items', v:null)
  if items is# v:null
    throw fila#error#new('buffer does not have items', {
          \ 'bufnr': self.bufnr,
          \})
  endif
  return items
endfunction

function! s:helper_set_items(value) abort dict
  call s:ensure_bufexists(self.bufnr)
  call setbufvar(self.bufnr, 'fila_items', a:value)
endfunction

function! s:helper_get_marks() abort dict
  call s:ensure_bufexists(self.bufnr)
  return getbufvar(self.bufnr, 'fila_marks', [])
endfunction

function! s:helper_set_marks(value) abort dict
  call s:ensure_bufexists(self.bufnr)
  call setbufvar(self.bufnr, 'fila_marks', a:value)
endfunction

function! s:helper_get_hidden() abort dict
  call s:ensure_bufexists(self.bufnr)
  return get(b:, 'fila_hidden', 0)
endfunction

function! s:helper_set_hidden(value) abort dict
  let b:fila_hidden = a:value
endfunction

function! s:helper_get_cursor_item(range) abort dict
  let items = self.get_visible_items()
  let index = self.renderer.translate(a:range[1])
  let n = len(items)
  if n is# 0 || index >= n
    throw fila#_error#new('index out of range', {
          \ 'n': n,
          \ 'index': index,
          \ 'range': a:range,
          \})
  endif
  return items[index]
endfunction

function! s:helper_get_marked_items() abort dict
  let items = self.get_visible_items()
  let marks = self.get_marks()
  return filter(copy(items), { -> index(marks, v:val.resource_uri) isnot# -1 })
endfunction

function! s:helper_get_visible_items() abort dict
  let items = copy(self.get_items())
  let hidden = self.get_hidden()
  if hidden
    return items
  endif
  return filter(items, { _, v ->
        \ !self.is_hidden(v.resource_uri) || v.status is# s:STATUS_EXPANDED
        \})
endfunction

function! s:helper_get_selection_items(range) abort dict
  let items = self.get_visible_items()
  let si = self.renderer.translate(a:range[0])
  let ei = self.renderer.translate(a:range[1])
  let n = len(items)
  if n is# 0 || min([si, ei]) >= n
    throw fila#error#new('index out of range', {
          \ 'n': n,
          \ 'si': si,
          \ 'ei': ei,
          \ 'range': a:range,
          \})
  endif
  return items[si : ei]
endfunction

function! s:helper_init(...) abort dict
  let options = extend({
        \ 'renderer': v:null,
        \ 'comparator': v:null,
        \ 'resource_uri': v:null,
        \ 'hidden_patterns': v:null,
        \}, a:0 ? a:1 : {},
        \)
  if options.renderer isnot# v:null
    let self.renderer = options.renderer
  endif
  if options.comparator isnot# v:null
    let self.comparator = options.comparator
  endif
  if options.resource_uri isnot# v:null
    let self.resource_uri = options.resource_uri
  endif
  if options.hidden_patterns isnot# v:null
    let self.hidden_patterns = options.hidden_patterns
  endif
  return fila#tree#util#_children(self.resource_uri, self.provider)
        \.then({ v -> fila#tree#util#_sort(v, self.comparator) })
        \.then({ v -> self.set_items(v) })
        \.then({ -> self })
endfunction

function! s:helper_redraw(...) abort dict
  let fail_silently = a:0 ? a:1 : 0
  let context = {
        \ 'bufnr': self.bufnr,
        \}
  if !bufloaded(self.bufnr)
    return fail_silently
          \ ? s:Promise.resolve(self)
          \ : s:Promise.reject(fila#error#new('buffer does not exist', context))
  endif
  let winid = bufwinid(self.bufnr)
  let cursor = s:WindowCursor.get_cursor(winid)
  let content = self.renderer.render(
        \ self.get_visible_items(),
        \ self.get_marks(),
        \)
  call s:BufferWriter.replace(self.bufnr, 0, -1, content)
  try
    " NOTE: the following may fail
    call s:WindowCursor.set_cursor(winid, cursor)
  catch
  endtry
  return s:Promise.resolve(self)
endfunction

function! s:helper_cursor(resource_uri, ...) abort dict
  let offset = a:0 > 0 ? a:1 : 0
  let fail_silently = a:0 > 1 ? a:2 : 0
  let winid = bufwinid(self.bufnr)
  if empty(getwininfo(winid))
    return fail_silently
          \ ? s:Promise.resolve(self)
          \ : s:Promise.reject(printf('no window %d exist', winid))
  endif
  let items = self.get_visible_items()
  let index = fila#tree#util#_index(a:resource_uri, items)
  call fila#logger#debug(a:resource_uri, index)
  let n = len(items)
  if n is# 0 || index >= n
    return fail_silently
          \ ? s:Promise.resolve(self)
          \ : s:Promise.reject(printf('item %s does not exist', a:resource_uri))
  endif
  let cursor = s:WindowCursor.get_cursor(winid)
  call s:WindowCursor.set_cursor(winid, [index + 1 + offset, cursor[1]])
  return s:Promise.resolve(self)
endfunction

function! s:helper_reload(resource_uri, ...) abort dict
  let fail_silently = a:0 ? a:1 : 0
  try
    let items = self.get_items()
    return fila#tree#util#_reload(a:resource_uri, items, self.provider)
          \.then({ v -> fila#tree#util#_sort(v, self.comparator) })
          \.then({ v -> self.set_items(v) })
          \.then({ -> self })
  catch
    return fail_silently
          \ ? s:Promise.resolve(self)
          \ : s:Promise.reject(fila#error#cause())
  endtry
endfunction

function! s:helper_expand(resource_uri, ...) abort dict
  let fail_silently = a:0 ? a:1 : 0
  try
    let items = self.get_items()
    return fila#tree#util#_expand(a:resource_uri, items, self.provider)
          \.then({ v -> fila#tree#util#_sort(v, self.comparator) })
          \.then({ v -> self.set_items(v) })
          \.then({ -> self })
  catch
    return fail_silently
          \ ? s:Promise.resolve(self)
          \ : s:Promise.reject(fila#error#cause())
  endtry
endfunction

function! s:helper_collapse(resource_uri, ...) abort dict
  let fail_silently = a:0 ? a:1 : 0
  try
    let items = self.get_items()
    return fila#tree#util#_collapse(a:resource_uri, items, self.provider)
          \.then({ v -> fila#tree#util#_sort(v, self.comparator) })
          \.then({ v -> self.set_items(v) })
          \.then({ -> self })
  catch
    return fail_silently
          \ ? s:Promise.resolve(self)
          \ : s:Promise.reject(fila#error#cause())
  endtry
endfunction

function! s:helper_guess_parent(resource_uri, ...) abort dict
  let fail_silently = a:0 ? a:1 : 0
  try
    let items = self.get_items()
    return fila#tree#util#_guess_parent(a:resource_uri, items)
  catch
    if fail_silently
      return v:null
    endif
    throw fila#error#new()
  endtry
endfunction

let s:helper = {
      \ 'is_hidden': funcref('s:helper_is_hidden'),
      \ 'get_item': funcref('s:helper_get_item'),
      \ 'get_items': funcref('s:helper_get_items'),
      \ 'set_items': funcref('s:helper_set_items'),
      \ 'get_marks': funcref('s:helper_get_marks'),
      \ 'set_marks': funcref('s:helper_set_marks'),
      \ 'get_hidden': funcref('s:helper_get_hidden'),
      \ 'set_hidden': funcref('s:helper_set_hidden'),
      \ 'get_cursor_item': funcref('s:helper_get_cursor_item'),
      \ 'get_marked_items': funcref('s:helper_get_marked_items'),
      \ 'get_visible_items': funcref('s:helper_get_visible_items'),
      \ 'get_selection_items': funcref('s:helper_get_selection_items'),
      \ 'init': funcref('s:helper_init'),
      \ 'redraw': funcref('s:helper_redraw'),
      \ 'cursor': funcref('s:helper_cursor'),
      \ 'reload': funcref('s:helper_reload'),
      \ 'expand': funcref('s:helper_expand'),
      \ 'collapse': funcref('s:helper_collapse'),
      \ 'guess_parent': funcref('s:helper_guess_parent'),
      \}


" call s:Config.config(expand('<sfile>:p'), {
"      \ 'default_renderer': fila#renderer#default#new(),
"      \ 'default_comparator': fila#comparator#default#new(),
"      \})
