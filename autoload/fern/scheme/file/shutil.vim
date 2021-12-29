let s:File = vital#fern#import('Async.File')
let s:Promise = vital#fern#import('Async.Promise')
let s:CancellationToken = vital#fern#import('Async.CancellationToken')

function! fern#scheme#file#shutil#open(path, ...) abort
  let token = a:0 ? a:1 : s:CancellationToken.none
  return s:File.open(a:path, {
        \ 'token': token,
        \})
endfunction

function! fern#scheme#file#shutil#mkfile(path, ...) abort
  if filereadable(a:path) || isdirectory(a:path)
    return s:Promise.reject(printf("'%s' already exist", a:path))
  endif
  return s:Promise.resolve()
        \.then({ -> mkdir(fnamemodify(a:path, ':p:h'), 'p') })
        \.then({ -> writefile([], a:path) })
endfunction

function! fern#scheme#file#shutil#mkdir(path, ...) abort
  if filereadable(a:path) || isdirectory(a:path)
    return s:Promise.reject(printf("'%s' already exist", a:path))
  endif
  return s:Promise.resolve()
        \.then({ -> mkdir(a:path, 'p') })
endfunction

function! fern#scheme#file#shutil#copy(src, dst, ...) abort
  let token = a:0 ? a:1 : s:CancellationToken.none
  if filereadable(a:dst) || isdirectory(a:dst)
    let r = s:select_overwrite_method(a:dst)
    if empty(r)
      return s:Promise.reject('Cancelled')
    elseif r ==# 'r'
      let new_dst = input(
            \ printf('New name: %s -> ', a:src),
            \ a:dst,
            \ filereadable(a:src) ? 'file' : 'dir',
            \)
      if empty(new_dst)
        return s:Promise.reject('Cancelled')
      endif
      return fern#scheme#file#shutil#copy(a:src, new_dst, token)
    endif
  endif
  call mkdir(fnamemodify(a:dst, ':p:h'), 'p')
  if isdirectory(a:src)
    return s:File.copy_dir(a:src, a:dst, {
          \ 'token': token,
          \})
  else
    return s:File.copy(a:src, a:dst, {
          \ 'token': token,
          \})
  endif
endfunction

function! fern#scheme#file#shutil#move(src, dst, ...) abort
  let token = a:0 ? a:1 : s:CancellationToken.none
  if filereadable(a:dst) || isdirectory(a:dst)
    let r = s:select_overwrite_method(a:dst)
    if empty(r)
      return s:Promise.reject('Cancelled')
    elseif r ==# 'r'
      let new_dst = input(
            \ printf('New name: %s -> ', a:src),
            \ a:dst,
            \ filereadable(a:src) ? 'file' : 'dir',
            \)
      if empty(new_dst)
        return s:Promise.reject('Cancelled')
      endif
      return fern#scheme#file#shutil#move(a:src, new_dst, token)
    endif
  endif
  call mkdir(fnamemodify(a:dst, ':p:h'), 'p')
  return s:File.move(a:src, a:dst, {
        \ 'token': token,
        \})
endfunction

function! fern#scheme#file#shutil#trash(path, ...) abort
  let token = a:0 ? a:1 : s:CancellationToken.none
  try
    return s:File.trash(a:path, {
          \ 'token': token,
          \})
  catch /vital: Async\.File:/
    return s:Promise.reject('Dependencies not found. See :help fern-action-trash for detail.')
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction

function! fern#scheme#file#shutil#remove(path, ...) abort
  return s:Promise.resolve()
        \.then({ -> delete(a:path, 'rf') })
endfunction

function! s:select_overwrite_method(path) abort
  let prompt = join([
        \ printf(
        \   '"%s" exists or not writable',
        \   a:path,
        \ ),
        \ 'Please select an overwrite method (esc to cancel)',
        \ 'f[orce]/r[ename]: ',
        \], "\n")
  return fern#internal#prompt#select(prompt, 1, 1, '[fr]')
endfunction
