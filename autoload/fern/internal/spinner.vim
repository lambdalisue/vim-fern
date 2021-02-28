let s:Config = vital#fern#import('Config')
let s:Spinner = vital#fern#import('App.Spinner')

function! fern#internal#spinner#start(...) abort
  let bufnr = a:0 ? a:1 : bufnr('%')
  if getbufvar(bufnr, 'fern_spinner_timer' , v:null) isnot# v:null
    return
  endif
  let spinner = s:Spinner.new(map(
        \ copy(g:fern#internal#spinner#frames),
        \ { k -> printf('FernSignSpinner%d', k) },
        \))
  call setbufvar(bufnr, 'fern_spinner_timer', timer_start(
        \ 50,
        \ { t -> s:update(t, spinner, bufnr) },
        \ { 'repeat': -1 },
        \))
endfunction

function! s:update(timer, spinner, bufnr) abort
  let fern = getbufvar(a:bufnr, 'fern', v:null)
  let winid = bufnr('%') == a:bufnr ? win_getid() : bufwinid(a:bufnr)
  if fern is# v:null || winid is# -1
    call timer_stop(a:timer)
    return
  endif
  let frame = a:spinner.next()
  call execute(printf('sign unplace * group=fern-spinner buffer=%d', a:bufnr))
  let info = getwininfo(winid)[0]
  let rng = sort([info.topline, info.botline], 'n')
  for lnum in range(rng[0], rng[1])
    let node = get(fern.visible_nodes, lnum - 1, v:null)
    if node is# v:null
      return
    elseif node.__processing is# 0
      continue
    endif
    call execute(printf(
          \ 'sign place %d group=fern-spinner line=%d name=%s buffer=%d',
          \ lnum,
          \ lnum,
          \ frame,
          \ a:bufnr,
          \))
  endfor
endfunction

function! s:define_signs() abort
  let frames = g:fern#internal#spinner#frames
  for index in range(len(frames))
    call execute(printf(
          \ 'sign define FernSignSpinner%d text=%s texthl=FernSpinner',
          \ index,
          \ frames[index],
          \))
  endfor
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'frames': has('win32') ? s:Spinner.flip : s:Spinner.dots,
      \})
call s:define_signs()
