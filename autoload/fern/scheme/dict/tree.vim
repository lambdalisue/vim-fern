let s:Promise = vital#fern#import('Async.Promise')

function! fern#scheme#dict#tree#read(tree, path, ...) abort
  let terms = split(a:path, '/')
  let optional = s:dig(a:tree, terms, 0)
  if empty(optional) && a:0 is# 0
    throw printf("no node '%s' exists", a:path)
  endif
  return get(optional, 0, a:0 ? a:1 : v:null)
endfunction

function! fern#scheme#dict#tree#write(tree, path, value, ...) abort
  let options = extend({
        \ 'parents': 0,
        \ 'overwrite': 0,
        \}, a:0 ? a:1 : {},
        \)
  let terms = split(a:path, '/')
  let name = terms[-1]
  let terms = terms[:-2]
  let optional = s:dig(a:tree, terms, options.parents)
  let parent = get(optional, 0, v:null)
  if empty(optional)
    throw printf("one of parents of a node '%s' does not exist", a:path)
  elseif type(parent) isnot# v:t_dict
    throw printf("one of parents of a node '%s' is not branch", a:path)
  elseif has_key(parent, name) && !options.overwrite
    throw printf("a node '%s' has already exist", a:path)
  endif
  let parent[name] = a:value
  return parent[name]
endfunction

function! fern#scheme#dict#tree#exists(tree, path) abort
  return !empty(s:dig(a:tree, split(a:path, '/'), 0))
endfunction

function! fern#scheme#dict#tree#remove(tree, path, ...) abort
  let default = a:0 ? a:1 : v:null
  let terms = split(a:path, '/')
  let name = terms[-1]
  let terms = terms[:-2]
  let optional = s:dig(a:tree, terms, 0)
  let parent = get(optional, 0, v:null)
  if empty(optional) || type(parent) isnot# v:t_dict || !has_key(parent, name)
    return default
  endif
  return remove(parent, name)
endfunction

function! fern#scheme#dict#tree#create(tree, path, value) abort
  if fern#scheme#dict#tree#exists(a:tree, a:path)
    let r = s:select_overwrite_method(a:path)
    if empty(r)
      return s:Promise.reject('Cancelled')
    elseif r ==# 'r'
      let new_path = input(
            \ printf('New name: %s -> ', a:path),
            \ a:path,
            \)
      if empty(new_path)
        return s:Promise.reject('Cancelled')
      endif
      return fern#scheme#dict#tree#create(a:tree, new_path, a:value)
    endif
  endif
  call fern#scheme#dict#tree#write(a:tree, a:path, a:value, {
        \ 'parents': 1,
        \ 'overwrite': 1,
        \})
endfunction

function! fern#scheme#dict#tree#copy(tree, src, dst) abort
  let original = fern#scheme#dict#tree#read(a:tree, a:src)
  if fern#scheme#dict#tree#exists(a:tree, a:dst)
    let r = s:select_overwrite_method(a:dst)
    if empty(r)
      return s:Promise.reject('Cancelled')
    elseif r ==# 'r'
      let new_dst = input(
            \ printf('New name: %s -> ', a:src),
            \ a:dst,
            \)
      if empty(new_dst)
        return s:Promise.reject('Cancelled')
      endif
      return fern#scheme#dict#tree#copy(a:tree, a:src, new_dst)
    endif
  endif
  call fern#scheme#dict#tree#write(a:tree, a:dst, deepcopy(original), {
        \ 'parents': 1,
        \ 'overwrite': 1,
        \})
endfunction

function! fern#scheme#dict#tree#move(tree, src, dst) abort
  call fern#scheme#dict#tree#copy(a:tree, a:src, a:dst)
  call fern#scheme#dict#tree#remove(a:tree, a:src)
endfunction

function! fern#scheme#dict#tree#tempname(tree) abort
  let value = 0
  while 1
    let value += 1
    let path = '@temp:' . sha256(value)
    if !fern#scheme#dict#tree#exists(a:tree, path)
      return path
    endif
  endwhile
endfunction

function! s:select_overwrite_method(path) abort
  let prompt = join([
        \ printf(
        \   'Entry "%s" already exists or not writable',
        \   a:path,
        \ ),
        \ 'Please select an overwrite method (esc to cancel)',
        \ 'f[orce]/r[ename]: ',
        \], "\n")
  return fern#internal#prompt#select(prompt, 1, 1, '[fr]')
endfunction

function! s:dig(tree, terms, create) abort
  let cursor = a:tree
  for term in a:terms
    if !has_key(cursor, term)
      if !a:create
        return []
      endif
      let cursor[term] = {}
    endif
    let cursor = cursor[term]
  endfor
  return [cursor]
endfunction
