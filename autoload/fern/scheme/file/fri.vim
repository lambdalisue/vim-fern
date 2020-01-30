let s:Path = vital#fern#import('System.Filepath')
let s:is_windows = has('win32')

function! fern#scheme#file#fri#to_fri(path) abort
  let path = s:Path.abspath(a:path)
  let path = s:Path.remove_last_separator(path)
  let path = s:Path.to_slash(path)
  return printf('file:///%s', join(split(path, '/'), '/'))
endfunction

function! fern#scheme#file#fri#from_fri(fri) abort
  let path = s:is_windows ? a:fri.path : '/' . a:fri.path
  let path = s:Path.from_slash(path)
  let path = s:Path.abspath(path)
  let path = s:Path.remove_last_separator(path)
  let path = empty(path) ? '/' : path
  return path
endfunction
