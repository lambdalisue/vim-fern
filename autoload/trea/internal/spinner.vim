let s:Spinner = vital#trea#import('App.Spinner')
let s:frames = s:Spinner.dots

function! trea#internal#spinner#start(...) abort
  let bufnr = a:0 ? a:1 : bufnr('%')
  if getbufvar(bufnr, 'trea_spinner_timer' , v:null) isnot# v:null
    return
  endif
  let spinner = s:Spinner.new(map(
        \ copy(s:frames),
        \ { k -> printf('TreaSignSpinner%d', k) },
        \))
  call setbufvar(bufnr, 'trea_spinner_timer', timer_start(
        \ 50,
        \ { t -> s:update(t, spinner, bufnr) },
        \ { 'repeat': -1 },
        \))
endfunction

function! s:update(timer, spinner, bufnr) abort
  let trea = getbufvar(a:bufnr, 'trea', v:null)
  let winid = bufwinid(a:bufnr)
  if trea is# v:null || winid is# -1
    call timer_stop(a:timer)
    return
  endif
  let frame = a:spinner.next()
  call execute(printf('sign unplace * group=trea buffer=%d', a:bufnr))
  let info = getwininfo(winid)[0]
  for lnum in range(info.topline, info.botline)
    let node = get(trea.nodes, lnum - 1, v:null)
    if node is# v:null
      return
    elseif node.processing is# 0
      continue
    endif
    call execute(printf(
          \ 'sign place %d group=trea line=%d name=%s buffer=%d',
          \ lnum,
          \ lnum,
          \ frame,
          \ a:bufnr,
          \))
  endfor
endfunction

function! s:define_signs() abort
  for index in range(len(s:frames))
    call execute(printf(
          \ 'sign define TreaSignSpinner%d text=%s',
          \ index,
          \ s:frames[index],
          \))
  endfor
endfunction

call s:define_signs()
