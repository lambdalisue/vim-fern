let s:File = vital#trea#import('Async.File')
let s:Promise = vital#trea#import('Async.Promise')
let s:Prompt = vital#trea#import('Prompt')
let s:CancellationToken = vital#trea#import('Async.CancellationToken')

function! trea#scheme#file#shutil#open(path, ...) abort
  let token = a:0 ? a:1 : s:CancellationToken.none
  return s:File.open(a:path, {
        \ 'token': token,
        \})
endfunction

function! trea#scheme#file#shutil#mkfile(path, ...) abort
  if filereadable(a:path) || isdirectory(a:path)
    return s:Promise.reject(printf("'%s' already exist", a:path))
  endif
  return s:Promise.resolve()
        \.then({ -> mkdir(fnamemodify(a:path, ':p:h'), 'p') })
        \.then({ -> writefile([], a:path) })
endfunction

function! trea#scheme#file#shutil#mkdir(path, ...) abort
  if filereadable(a:path) || isdirectory(a:path)
    return s:Promise.reject(printf("'%s' already exist", a:path))
  endif
  return s:Promise.resolve()
        \.then({ -> mkdir(a:path, 'p') })
endfunction

function! trea#scheme#file#shutil#copy(src, dst, ...) abort
  let token = a:0 ? a:1 : s:CancellationToken.none
  if filereadable(a:dst) || isdirectory(a:dst)
    let r = s:select_overwrite_method(a:dst)
    if empty(r)
      return s:Promise.reject('Cancelled')
    elseif r ==# 'r'
      let new_dst = s:Prompt.ask(
            \ printf("New name: %s -> ", a:src),
            \ a:dst,
            \ filereadable(a:src) ? 'file' : 'dir',
            \)
      if empty(new_dst)
        return s:Promise.reject('Cancelled')
      endif
      return trea#scheme#file#shutil#copy(a:src, new_dst, token)
    endif
  endif
  return s:File.copy(a:src, a:dst, {
        \ 'token': token,
        \})
endfunction

function! trea#scheme#file#shutil#move(src, dst, ...) abort
  let token = a:0 ? a:1 : s:CancellationToken.none
  if filereadable(a:dst) || isdirectory(a:dst)
    let r = s:select_overwrite_method(a:dst)
    if empty(r)
      return s:Promise.reject('Cancelled')
    elseif r ==# 'r'
      let new_dst = s:Prompt.ask(
            \ printf("New name: %s -> ", a:src),
            \ a:dst,
            \ filereadable(a:src) ? 'file' : 'dir',
            \)
      if empty(new_dst)
        return s:Promise.reject('Cancelled')
      endif
      return trea#scheme#file#shutil#move(a:src, new_dst, token)
    endif
  endif
  return s:File.move(a:src, a:dst, {
        \ 'token': token,
        \})
endfunction

function! trea#scheme#file#shutil#trash(path, ...) abort
  let token = a:0 ? a:1 : s:CancellationToken.none
  return s:File.trash(a:path, {
        \ 'token': token,
        \})
endfunction

function! trea#scheme#file#shutil#remove(path, ...) abort
  return s:Promise.resolve()
        \.then({ -> delete(a:path, 'rf') })
endfunction

function! s:select_overwrite_method(path) abort
  let prompt = join([
        \ printf(
        \   'File/Directory "%s" already exists or not writable',
        \   a:path,
        \ ),
        \ 'Please select an overwrite method (esc to cancel)',
        \ 'f[orce]/r[ename]: ',
        \], "\n")
  return s:Prompt.select(prompt, 1, 1, '[fr]')
endfunction
