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
  let path = fern#internal#filepath#from_slash('/' . fri.path)
  return s:node(path)
endfunction

function! s:provider_get_parent(node, ...) abort
  if s:Path.is_root_directory(a:node._path)
    return s:Promise.reject('no parent node exists for the root')
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

if !s:is_windows && executable('ls')
  " NOTE:
  " The -U option means different between Linux and FreeBSD.
  " Linux   - do not sort; list entries in directory order
  " FreeBSD - Use time when file was created for sorting or printing.
  " But it improve performance in Linux and just noise in FreeBSD so
  " the option is applied.
  function! s:children_ls(path, token) abort
    let Profile = fern#profile#start('fern#scheme#file#provider:children_ls')
    return s:Process.start(['ls', '-1AU', a:path], { 'token': a:token })
          \.then({ v -> v.stdout })
          \.then(s:AsyncLambda.filter_f({ v -> !empty(v) }))
          \.then(s:AsyncLambda.map_f({ v -> a:path . '/' . v }))
          \.finally({ -> Profile() })
  endfunction
endif

if !s:is_windows && executable('find')
  function! s:children_find(path, token) abort
    let Profile = fern#profile#start('fern#scheme#file#provider:children_find')
    return s:Process.start(['find', a:path, '-follow', '-maxdepth', '1'], { 'token': a:token })
          \.then({ v -> v.stdout })
          \.then(s:AsyncLambda.filter_f({ v -> !empty(v) && v !=# a:path }))
          \.finally({ -> Profile() })
  endfunction
endif

if exists('*readdir')
  function! s:children_vim_readdir(path, ...) abort
    let Profile = fern#profile#start('fern#scheme#file#provider:children_vim_readdir')
    let s = s:Path.separator()
    return s:Promise.resolve(readdir(a:path))
          \.then(s:AsyncLambda.map_f({ v -> a:path . s . v }))
          \.finally({ -> Profile() })
  endfunction
endif

function! s:children_vim_glob(path, ...) abort
  let Profile = fern#profile#start('fern#scheme#file#provider:children_vim_glob')
  let s = s:Path.separator()
  let a = s:Promise.resolve(glob(a:path . s . '*', 1, 1, 1))
  let b = s:Promise.resolve(glob(a:path . s . '.*', 1, 1, 1))
        \.then(s:AsyncLambda.filter_f({ v -> v[-2:] !=# s . '.' && v[-3:] !=# s . '..' }))
  return s:Promise.all([a, b])
        \.then(s:AsyncLambda.reduce_f({ a, v -> a + v }, []))
        \.finally({ -> Profile() })
endfunction

function! s:children(path, token) abort
  return call(printf('s:children_%s', g:fern#scheme#file#provider#impl), [a:path, a:token])
endfunction


" NOTE:
" Performance 'find' > 'ls' >> 'vim_reddir' > 'vim_glob'
call s:Config.config(expand('<sfile>:p'), {
      \ 'impl': exists('*s:children_find')
      \   ? 'find'
      \   : exists('*s:children_ls')
      \     ? 'ls'
      \     : exists('*s:children_vim_readdir')
      \     ? 'vim_readdir'
      \     : 'vim_glob',
      \})


function! fern#scheme#file#provider#_benchmark() abort
  let Path = vital#fern#import('System.Filepath')
  redraw
  echo 'Creating benchmark environment ...'
  let t = tempname()
  try
    call mkdir(t, 'p')
    call map(
          \ range(100000),
          \ { _, v -> writefile([], Path.join(t, v)) },
          \)

    let token = s:CancellationToken.none

    if exists('*s:children_ls')
      echo "Benchmarking 'ls' ..."
      let s = reltime()
      call s:children_ls(t, token)
      echo reltimestr(reltime(s))
    endif

    if exists('*s:children_find')
      echo "Benchmarking 'find' ..."
      let s = reltime()
      call s:children_find(t, token)
      echo reltimestr(reltime(s))
    endif

    if exists('*s:children_vim_readdir')
      echo "Benchmarking 'vim_readdir' ..."
      let s = reltime()
      call s:children_vim_readdir(t, token)
      echo reltimestr(reltime(s))
    endif

    if exists('*s:children_vim_glob')
      echo "Benchmarking 'vim_glob' ..."
      let s = reltime()
      call s:children_vim_glob(t, token)
      echo reltimestr(reltime(s))
    endif
  finally
    call delete(t, 'rf')
  endtry
endfunction
