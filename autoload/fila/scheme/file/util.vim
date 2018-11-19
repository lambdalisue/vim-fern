let s:File = vital#fila#import('Async.File')
let s:Prompt = vital#fila#import('Prompt')
let s:Promise = vital#fila#import('Async.Promise')
let s:Revelator = vital#fila#import('App.Revelator')

function! fila#scheme#file#util#open(path) abort
  return s:File.open(a:path)
endfunction

function! fila#scheme#file#util#new_file(path) abort
  if filereadable(a:path) || isdirectory(a:path)
    throw s:Revelator.error(printf(
          \ '"%s" already exist',
          \ a:path,
          \))
  endif
  call s:create_parent_path_if_requested(a:path)
  return s:Promise.resolve(writefile([], a:path) ? 1 : 0)
endfunction

function! fila#scheme#file#util#new_directory(path) abort
  if filereadable(a:path) || isdirectory(a:path)
    throw s:Revelator.error(printf(
          \ '"%s" already exist',
          \ a:path,
          \))
  endif
  call s:create_parent_path_if_requested(a:path)
  return s:Promise.resolve(mkdir(a:path) ? 1 : 0)
endfunction

function! fila#scheme#file#util#copy(src, dst) abort
  if filereadable(a:dst) || isdirectory(a:dst)
    let r = s:select_overwrite_method(a:dst)
    if empty(r)
      throw s:Revelator.info('Cancelled')
    elseif r ==# 'r'
      let new_dst = input(
            \ printf('New name: %s -> ', a:src),
            \ a:dst,
            \ filereadable(a:src) ? 'file' : 'dir',
            \)
      if empty(new_dst)
        throw s:Revelator.info('Cancelled')
      endif
      return fila#scheme#file#util#copy(a:src, new_dst)
    endif
  endif
  call s:create_parent_path_if_requested(a:dst)
  if filereadable(a:src)
    return s:File.copy(a:src, a:dst)
  else
    return s:File.copy_dir(a:src, a:dst)
  endif
endfunction

function! fila#scheme#file#util#move(src, dst) abort
  if filereadable(a:src) && !filewritable(a:src)
    throw s:Revelator.error(printf(
          \ '"%s" is not writable',
          \ a:src,
          \))
  elseif filereadable(a:dst) || isdirectory(a:dst)
    let r = s:select_overwrite_method(a:dst)
    if empty(r)
      throw s:Revelator.info('Cancelled')
    elseif r ==# 'r'
      let new_dst = input(
            \ printf('New name: %s -> ', a:src),
            \ a:dst,
            \ filereadable(a:src) ? 'file' : 'dir',
            \)
      if empty(new_dst)
        throw s:Revelator.info('Cancelled')
      endif
      return fila#scheme#file#util#move(a:src, new_dst)
    endif
  endif
  call s:create_parent_path_if_requested(a:dst)
  if filereadable(a:src)
    return s:File.move(a:src, a:dst)
  else
    return s:File.move_dir(a:src, a:dst)
  endif
endfunction

function! fila#scheme#file#util#trash(path) abort
  if filereadable(a:path) && !filewritable(a:path)
    throw s:Revelator.error(printf(
          \ '"%s" is not writable',
          \ a:path,
          \))
  endif
  return s:File.trash(a:path)
endfunction

function! fila#scheme#file#util#remove(path) abort
  if filereadable(a:path) && !filewritable(a:path)
    throw s:Revelator.error(printf(
          \ '"%s" is not writable',
          \ a:path,
          \))
  endif
  if filereadable(a:path)
    call delete(a:path)
  else
    call delete(a:path, 'rf')
  endif
  return s:Promise.resolve()
endfunction

function! s:create_parent_path_if_requested(path) abort
  let parent_path = fnamemodify(a:path, ':p:h')
  if !isdirectory(parent_path)
    let m = printf(
          \ 'A parent directory %s does not exist. Create it? (Y[es]/no): ',
          \ parent_path,
          \)
    if !s:Prompt.confirm(m, v:true)
      throw s:Revelator.info('Cancelled')
    endif
    call mkdir(parent_path, 'p')
  endif
endfunction

function! s:select_overwrite_method(path) abort
  let prompt = join([
        \ printf(
        \   'File/Directory "%s" already exists',
        \   a:path,
        \ ),
        \ 'Please select an overwrite method (esc to cancel)',
        \ 'f[orce]/r[ename]: ',
        \], "\n")
  return s:Prompt.select(prompt, 1, 1, '[fr]')
endfunction
