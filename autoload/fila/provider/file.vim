let s:Path = vital#fila#import('System.Filepath')
let s:Lambda = vital#fila#import('Lambda')
let s:Promise = vital#fila#import('Async.Promise')
let s:Process = vital#fila#import('Async.Promise.Process')

function! fila#provider#file#new() abort
  return {
        \ 'item': function('s:item'),
        \ 'parent': funcref('s:parent'),
        \ 'children': funcref('s:children'),
        \}
endfunction

function! s:item(resource_uri) abort
  let path = s:Path.realpath(a:resource_uri)
  let state = isdirectory(path)
  return fila#tree#item#new(a:resource_uri, state)
endfunction

function! s:parent(resource_uri) abort
  let path = s:Path.realpath(a:resource_uri)
  return fnamemodify(path, ':h')
endfunction

if executable('ls')
  function! s:children(resource_uri) abort
    let path = s:Path.realpath(a:resource_uri)
    return s:Process.start(['ls', '-A', path])
          \.then({ v -> v.stdout })
          \.then(s:Lambda.filter_f({ v -> !empty(v) }))
  endfunction
else
  let s:SEPARATOR = has('win32') ? '\' : '/'

  function! s:children(resource_uri) abort
    let path = s:Path.realpath(a:resource_uri)
    let s = s:SEPARATOR
    let c1 = s:Promise.resolve(glob(path . '*', 1, 1, 1))
    let c2 = s:Promise.resolve(glob(path . '.*', 1, 1, 1))
          \.then(s:Lambda.filter_f({ v -> v[-2:] !=# s . '.' && v[-3:] !=# s . '..' }))
    return s:Promise.all([c1, c2])
          \.then(s:Lambda.reduce_f({ a, v -> a + v }, []))
  endfunction
endif
