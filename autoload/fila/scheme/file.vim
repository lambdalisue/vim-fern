let s:Lambda = vital#fila#import('Lambda')
let s:Promise = vital#fila#import('Async.Promise')
let s:Process = vital#fila#import('Async.Promise.Process')

function! fila#scheme#file#node(path) abort
  return s:node(simplify(a:path))
endfunction

function! s:node(path) abort
  let path = fnamemodify(a:path, ':p')
  let key = split(fnamemodify(path, ':gs?\\?/?'), '/')
  if isdirectory(path)
    let options = {
          \ '__path': path,
          \ 'bufname': 'fila://file://' . fnamemodify(path, ':gs?\\?/?'),
          \ 'hidden': s:is_hidden(path),
          \ 'children': funcref('s:children', [path]),
          \}
  else
    let options = {
          \ '__path': path,
          \ 'bufname': path,
          \ 'hidden': s:is_hidden(path),
          \}
  endif
  return fila#node#new(key, options)
endfunction

if executable('ls')
  function! s:children(path) abort
    return s:Process.start(['ls', '-A', a:path])
          \.catch({ v -> v.stderr })
          \.then({ v -> v.stdout })
          \.then(s:Lambda.filter_f({ v -> !empty(v) }))
          \.then(s:Lambda.map_f({ v -> s:node(a:path . v) }))
  endfunction
else
  let s:SEPARATOR = has('win32') ? '\' : '/'

  function! s:children(path) abort
    let s = s:SEPARATOR
    let a = s:Promise.resolve(glob(a:path . '*', 1, 1, 1))
          \.then(s:Lambda.map_f({ v -> s:node(v) }))
    let b = s:Promise.resolve(glob(a:path . '.*', 1, 1, 1))
          \.then(s:Lambda.filter_f({ v -> v[-2:] !=# s . '.' && v[-3:] !=# s . '..' }))
          \.then(s:Lambda.map_f({ v -> s:node(v) }))
    return s:Promise.all([a, b])
          \.then(s:Lambda.reduce_f({ a, v -> a + v }, []))
  endfunction
endif

" XXX
" Support Windows (attrib)
" https://tech.nikkeibp.co.jp/it/free/NT/WinKeyWord/20040805/1/attrib.shtml
function! s:is_hidden(path) abort
  if isdirectory(a:path)
    let basename = fnamemodify(a:path, ':h:t')
  else
    let basename = fnamemodify(a:path, ':t')
  endif
  return basename[:0] ==# '.'
endfunction

function! s:action_define() abort
  let action = fila#viewer#action#get()
  call fila#scheme#file#action#define(action)
endfunction

augroup fila_scheme_file_internal
  autocmd! *
  autocmd User FilaViewerInit call s:action_define()
augroup END
