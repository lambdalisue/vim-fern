let s:Config = vital#fern#import('Config')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:Promise = vital#fern#import('Async.Promise')
let s:Process = vital#fern#import('Async.Promise.Process')
let s:CancellationToken = vital#fern#import('Async.CancellationToken')
let s:is_windows = has('win32')
let s:windows_drive_nodes = s:Promise.resolve([])
let s:windows_drive_root = {
      \ 'name': '',
      \ 'label': 'Drives',
      \ 'status': 1,
      \ 'hidden': 0,
      \ 'bufname': 'fern:///file:///',
      \ '_path': '',
      \}

function! fern#scheme#file#provider#new() abort
  return {
        \ 'get_root': funcref('s:provider_get_root'),
        \ 'get_parent' : funcref('s:provider_get_parent'),
        \ 'get_children' : funcref('s:provider_get_children'),
        \}
endfunction

function! s:provider_get_root(uri) abort
  call fern#logger#debug('file:get_root:uri', a:uri)
  let fri = fern#fri#parse(a:uri)
  call fern#logger#debug('file:get_root:fri', fri)
  let path = fern#fri#to#filepath(fri)
  if s:is_windows && path ==# ''
    return s:windows_drive_root
  endif
  let root = s:node(path)
  if g:fern#scheme#file#show_absolute_path_on_root_label
    let root.label = fnamemodify(root._path, ':~')
  endif
  return root
endfunction

function! s:provider_get_parent(node, ...) abort
  if fern#internal#filepath#is_root(a:node._path)
    return s:Promise.reject('no parent node exists for the root')
  elseif s:is_windows && fern#internal#filepath#is_drive_root(a:node._path)
    return s:Promise.resolve(s:windows_drive_root)
  endif
  try
    let path = fern#internal#filepath#to_slash(a:node._path)
    let parent = fern#internal#path#dirname(path)
    let parent = fern#internal#filepath#from_slash(parent)
    return s:Promise.resolve(s:node(parent))
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction

function! s:provider_get_children(node, ...) abort
  if s:is_windows && a:node._path ==# ''
    return s:windows_drive_nodes
  endif
  let token = a:0 ? a:1 : s:CancellationToken.none
  if a:node.status is# 0
    return s:Promise.reject('no children exists for %s', a:node._path)
  endif
  let l:Profile = fern#profile#start('fern#scheme#file#provider:provider_get_children')
  return s:children(s:resolve(a:node._path), token)
        \.then(s:AsyncLambda.map_f({ v -> s:safe(funcref('s:node', [v])) }))
        \.then(s:AsyncLambda.filter_f({ v -> !empty(v) }))
        \.finally({ -> Profile() })
endfunction

function! s:node(path) abort
  if empty(getftype(a:path))
    throw printf('no such file or directory exists: %s', a:path)
  endif
  let status = isdirectory(a:path)
  let name = fern#internal#path#basename(fern#internal#filepath#to_slash(a:path))
  let bufname = status
        \ ? fern#fri#format(fern#fri#new({
        \     'scheme': 'fern',
        \     'path': fern#fri#format(fern#fri#from#filepath(a:path)),
        \   }))
        \ : a:path
  return {
        \ 'name': name,
        \ 'status': status,
        \ 'hidden': name[:0] ==# '.',
        \ 'bufname': bufname,
        \ '_path': a:path,
        \}
endfunction

function! s:safe(fn) abort
  try
    return a:fn()
  catch
    return v:null
  endtry
endfunction

function! s:children(path, token) abort
  return call(
        \ printf('fern#scheme#file#util#list_entries_%s', g:fern#scheme#file#provider#impl),
        \ [a:path, a:token],
        \)
endfunction

if has('patch-8.2.1804')
  let s:resolve = function('resolve')
else
  function! s:resolve(path) abort
    if a:path ==# '/'
      return a:path
    endif
    return resolve(a:path)
  endfunction
endif

if s:is_windows
  let s:windows_drive_nodes = fern#scheme#file#util#list_drives(s:CancellationToken.none)
          \.then(s:AsyncLambda.map_f({ v -> s:safe(funcref('s:node', [v])) }))
          \.then(s:AsyncLambda.filter_f({ v -> !empty(v) }))
endif

" NOTE:
" It is required while exists() does not invoke autoload
runtime autoload/fern/scheme/file/util.vim

" NOTE:
" Performance 'find' > 'ls' >> 'reddir' > 'glob'
call s:Config.config(expand('<sfile>:p'), {
      \ 'impl': exists('*fern#scheme#file#util#list_entries_find')
      \   ? 'find'
      \   : exists('*fern#scheme#file#util#list_entries_ls')
      \     ? 'ls'
      \     : exists('*fern#scheme#file#util#list_entries_readdir')
      \     ? 'readdir'
      \     : 'glob',
      \})
