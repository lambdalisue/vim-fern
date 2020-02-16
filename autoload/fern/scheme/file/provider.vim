let s:Config = vital#fern#import('Config')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:Promise = vital#fern#import('Async.Promise')
let s:Process = vital#fern#import('Async.Promise.Process')
let s:Path = vital#fern#import('System.Filepath')
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
  let fri = fern#fri#parse(a:uri)
  let path = fern#internal#filepath#from_slash('/' . fri.path)
  if s:is_windows && path ==# ''
    return s:windows_drive_root
  endif
  return s:node(path)
endfunction

function! s:provider_get_parent(node, ...) abort
  if s:Path.is_root_directory(a:node._path)
    return s:Promise.reject('no parent node exists for the root')
  elseif s:is_windows && fern#internal#filepath#is_drive_root(a:node._path)
    return s:Promise.resolve(s:windows_drive_root)
  endif
  try
    let parent = fnamemodify(a:node._path, ':h')
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
  let Profile = fern#profile#start('fern#scheme#file#provider:provider_get_children')
  return s:children(a:node._path, token)
        \.then(s:AsyncLambda.map_f({ v -> s:safe(funcref('s:node', [v])) }))
        \.then(s:AsyncLambda.filter_f({ v -> !empty(v) }))
        \.finally({ -> Profile() })
endfunction

function! s:node(path) abort
  let path = s:Path.abspath(a:path)
  let path = s:Path.remove_last_separator(path)
  let path = simplify(path)
  if s:is_windows && path =~# '^\w:$'
    let path .= '\'
  endif
  let path = empty(path) ? '/' : path
  if empty(getftype(path))
    throw printf('no such file or directory exists: %s', path)
  endif
  let name = fnamemodify(path, ':t')
  let status = isdirectory(path)
  return {
        \ 'name': name,
        \ 'label': name ==# '' ? '/' : name,
        \ 'status': status,
        \ 'hidden': name[:0] ==# '.',
        \ 'bufname': path,
        \ '_path': path,
        \}
endfunction

function! s:to_file_uri(abspath) abort
  let path = s:Path.to_slash(a:abspath)
  let path = join(split(path, '/'), '/')
  return printf('file:///%s', path)
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

if s:is_windows
  let s:windows_drive_nodes = fern#scheme#file#util#list_drives(s:CancellationToken.none)
          \.then(s:AsyncLambda.map_f({ v -> s:safe(funcref('s:node', [v . '\'])) }))
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
