function! fern#internal#drawer#is_drawer(...) abort
  let bufname = a:0 ? a:1 : bufname('%')
  let fri = fern#fri#parse(bufname)
  return fri.scheme ==# 'fern' && fri.authority =~# '^drawer\(-right\)\?:'
endfunction

function! fern#internal#drawer#is_left_drawer(...) abort
  let bufname = a:0 ? a:1 : bufname('%')
  let fri = fern#fri#parse(bufname)
  return fri.scheme ==# 'fern' && fri.authority =~# '^drawer:'
endfunction

function! fern#internal#drawer#is_right_drawer(...) abort
  let bufname = a:0 ? a:1 : bufname('%')
  let fri = fern#fri#parse(bufname)
  return fri.scheme ==# 'fern' && fri.authority =~# '^drawer-right:'
endfunction

function! fern#internal#drawer#resize() abort
  let fri = fern#fri#parse(bufname('%'))
  let width = str2nr(get(fri.query, 'width', string(g:fern#drawer_width)))
  execute 'vertical resize' width
endfunction

function! fern#internal#drawer#open(fri, ...) abort
  let options = extend({
        \ 'toggle': 0,
        \ 'right': 0,
        \}, a:0 ? a:1 : {},
        \)
  if s:focus_next(options.right)
    if winnr('$') > 1
      if options.toggle
        close
        return
      endif
      let options.opener = 'edit'
    endif
  endif
  " Force 'keepalt' to fix #249
  let options.mods = join(['keepalt', get(options, 'mods', '')])
  return fern#internal#viewer#open(a:fri, options)
endfunction

function! fern#internal#drawer#init() abort
  if !fern#internal#drawer#is_drawer()
    return
  endif

  call fern#internal#drawer#auto_resize#init()
  call fern#internal#drawer#auto_winfixwidth#init()
  call fern#internal#drawer#auto_restore_focus#init()
  call fern#internal#drawer#smart_quit#init()
  call fern#internal#drawer#hover_popup#init()
  call fern#internal#drawer#resize()

  setlocal winfixwidth
endfunction

function! s:focus_next(right) abort
  let l:Predicator = a:right
    \ ? function('fern#internal#drawer#is_right_drawer')
    \ : function('fern#internal#drawer#is_left_drawer')
  let winnr = fern#internal#window#find(
        \ { w -> l:Predicator(bufname(winbufnr(w))) },
        \)
  if winnr is# 0
    return
  endif
  call win_gotoid(win_getid(winnr))
  return 1
endfunction
