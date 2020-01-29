let s:Config = vital#fern#import('Config')
let s:Lambda = vital#fern#import('Lambda')
let s:AsyncLambda = vital#fern#import('Async.Lambda')
let s:Promise = vital#fern#import('Async.Promise')
let s:Process = vital#fern#import('Async.Promise.Process')
let s:Path = vital#fern#import('System.Filepath')
let s:CancellationToken = vital#fern#import('Async.CancellationToken')
let s:is_windows = has('win32')

function! fern#scheme#file#provider#new() abort
  return {
        \ 'get_root': funcref('s:provider_get_root'),
        \ 'get_parent' : funcref('s:provider_get_parent'),
        \ 'get_children' : funcref('s:provider_get_children'),
        \}
endfunction

function! s:provider_get_root(uri) abort
  let fri = fern#fri#parse(a:uri)
  let path = fern#scheme#file#fri#from_fri(fri)
  return s:node(path)
endfunction

function! s:provider_get_parent(node, ...) abort
  if s:Path.is_root_directory(a:node._path)
    return s:Promise.reject("no parent node exists for the root")
  endif
  try
    let parent = fnamemodify(a:node._path, ':h')
    return s:Promise.resolve(s:node(parent))
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction

function! s:provider_get_children(node, ...) abort
  let token = a:0 ? a:1 : s:CancellationToken.none
  if a:node.status is# 0
    return s:Promise.reject("no children exists for %s", a:node._path)
  endif
  return s:children(a:node._path, token)
        \.then(s:AsyncLambda.map_f({ v -> s:safe(funcref('s:node', [v])) }))
        \.then(s:AsyncLambda.filter_f({ v -> !empty(v) }))
endfunction

function! s:node(path) abort
  let path = s:Path.abspath(a:path)
  let path = s:Path.remove_last_separator(path)
  let path = simplify(path)
  if empty(getftype(path))
    throw printf("no such file or directory exists: %s", path)
  endif
  let name = fnamemodify(path, ':t')
  let status = isdirectory(path)
  let bufname = status ? fern#scheme#file#fri#to_fri(path) : path
  return {
        \ 'name': name,
        \ 'label': name ==# '' ? '/' : name,
        \ 'status': status,
        \ 'hidden': name[:0] ==# '.',
        \ 'bufname': bufname,
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

if executable('find') && !has("win32")
  function! s:children_find(path, token) abort
    return s:Process.start(['find', a:path, '-maxdepth', '1'], { 'token': a:token })
         \.then({ v -> v.stdout })
         \.then(s:AsyncLambda.filter_f({ v -> !empty(v) && v !=# a:path }))
  endfunction
endif

if executable('ls')
  function! s:children_ls(path, token) abort
    return s:Process.start(['ls', '-1A', a:path], { 'token': a:token })
         \.then({ v -> v.stdout })
         \.then(s:AsyncLambda.filter_f({ v -> !empty(v) }))
         \.then(s:AsyncLambda.map_f({ v -> a:path . '/' . v }))
  endfunction
endif

function! s:children_vim(path, ...) abort
  let s = s:Path.separator()
  let a = s:Promise.resolve(glob(a:path . s . '*', 1, 1, 1))
  let b = s:Promise.resolve(glob(a:path . s . '.*', 1, 1, 1))
        \.then(s:AsyncLambda.filter_f({ v -> v[-2:] !=# s . '.' && v[-3:] !=# s . '..' }))
  return s:Promise.all([a, b])
        \.then(s:AsyncLambda.reduce_f({ a, v -> a + v }, []))
endfunction

function! s:children(path, token) abort
  return call(printf('s:children_%s', g:fern#scheme#file#provider#impl), [a:path, a:token])
endfunction


call s:Config.config(expand('<sfile>:p'), {
      \ 'impl': exists('*s:children_find')
      \   ? 'find'
      \   : exists('*s:children_ls')
      \     ? 'ls'
      \     : 'vim',
      \})
