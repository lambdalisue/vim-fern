let s:Config = vital#fern#import('Config')

function! fern#internal#filepath#to_slash(path) abort
  return g:fern#internal#filepath#is_windows
        \ ? s:to_slash_windows(a:path)
        \ : s:to_slash_unix(a:path)
endfunction

function! fern#internal#filepath#from_slash(path) abort
  return g:fern#internal#filepath#is_windows
        \ ? s:from_slash_windows(a:path)
        \ : s:to_slash_unix(a:path)
endfunction

function! fern#internal#filepath#is_root(path) abort
  return g:fern#internal#filepath#is_windows
        \ ? a:path ==# ''
        \ : a:path ==# '/'
endfunction

function! fern#internal#filepath#is_drive_root(path) abort
  return g:fern#internal#filepath#is_windows
        \ ? a:path =~# '^\w:\\$'
        \ : a:path ==# '/'
endfunction

function! fern#internal#filepath#is_absolute(path) abort
  return g:fern#internal#filepath#is_windows
        \ ? s:is_absolute_windows(a:path)
        \ : s:is_absolute_unix(a:path)
endfunction

function! fern#internal#filepath#join(paths) abort
  let paths = map(
        \ copy(a:paths),
        \ 'fern#internal#filepath#to_slash(v:val)',
        \)
  return fern#internal#filepath#from_slash(join(paths, '/'))
endfunction

function! s:to_slash_windows(path) abort
  let prefix = s:is_absolute_windows(a:path) ? '/' : ''
  let terms = filter(split(a:path, '\\'), '!empty(v:val)')
  return prefix . join(terms, '/')
endfunction

function! s:to_slash_unix(path) abort
  if empty(a:path)
    return '/'
  endif
  let prefix = s:is_absolute_unix(a:path) ? '/' : ''
  let terms = filter(split(a:path, '/'), '!empty(v:val)')
  return prefix . join(terms, '/')
endfunction

function! s:from_slash_windows(path) abort
  let terms = filter(split(a:path, '/'), '!empty(v:val)')
  let path = join(terms, '\')
  return path[:2] =~# '^\w:$' ? path . '\' : path
endfunction

function! s:is_absolute_windows(path) abort
  return a:path ==# '' || a:path[:2] =~# '^\w:\\$'
endfunction

function! s:is_absolute_unix(path) abort
  return a:path ==# '' || a:path[:0] ==# '/'
endfunction


call s:Config.config(expand('<sfile>:p'), {
      \ 'is_windows': has('win32'),
      \})
