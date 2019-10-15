let s:Promise = vital#fila#import('Async.Promise')

function! fila#lib#renamer#rename(paths) abort
  return s:Promise.new(funcref('s:executor', [a:paths]))
endfunction

function! s:executor(paths, resolve, reject) abort
  let bufname = printf('fila://renamer/%s', sha256(json_encode(a:paths)))
  call fila#lib#buffer#open(bufname, {
        \ 'opener': 'split',
        \})
        \.then({ -> s:init(a:paths, a:resolve) })
        \.catch({ e -> fila#lib#error#handle(e) })
endfunction

function! s:init(paths, resolve) abort
  let b:fila_renamer_paths = a:paths
  let b:fila_renamer_resolve = a:resolve
  augroup fila_renamer_internal_buffer
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
    autocmd BufWriteCmd <buffer> call s:BufWriteCmd()
  augroup END
  edit
endfunction

function! s:BufReadCmd() abort
  call setline(1, b:fila_renamer_paths)
  call setline(1, paths)
  setlocal bufhidden=wipe
  " TODO: Do NOT allow to add/remove lines
endfunction

function! s:BufWriteCmd() abort
  let paths = b:fila_renamer_paths
  let Resolve = b:fila_renamer_resolve
  for index in range(len(paths))
    let src = paths[index]
    let dst = getline(index + 1)
    if empty(dst) || dst ==# src
      continue
    endif
    call fila#lib#fs#move(src, dst)
  endfor
  call Resolve(paths)
  close
endfunction
