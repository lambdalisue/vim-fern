let s:win = v:null
let s:timer = 0

function! fern#internal#drawer#hover_popup#init() abort
  if g:fern#disable_drawer_hover_popup
    return
  endif

  if !s:available()
    call fern#logger#warn('hover popup is not supported, popup_create() or nvim environment
          \ does not exist. Disable this message
          \ with g:fern#disable_drawer_hover_popup.')
    return
  endif

  augroup fern_internal_drawer_hover_popup_init
    autocmd! * <buffer>
    autocmd CursorMoved <buffer> call timer_stop(s:timer) | call s:hide() | let s:timer = timer_start(g:fern#drawer_hover_popup_delay, { -> s:show(fern#helper#new()) })
    autocmd BufLeave <buffer> call timer_stop(s:timer) | call s:hide()
  augroup END
endfunction

function! s:available() abort
  return has('nvim') || exists('*popup_create')
endfunction

function! s:show(helper) abort
  if strdisplaywidth(getline('.')) <= winwidth(0)
    return
  endif

  let node = a:helper.sync.get_cursor_node()
  if node is# v:null
    return
  endif

  let line = getline('.')
  if has('nvim')
    let s:win = nvim_open_win(nvim_create_buf(v:false, v:true), v:false, {
    \    'relative': 'win',
    \    'bufpos': [line('.') - 2, 0],
    \    'width': strdisplaywidth(substitute(line, '[^[:print:]]*$', '', 'g')),
    \    'height': 1,
    \    'noautocmd': v:true,
    \    'style': 'minimal',
    \  })
  else
    let ui_width = screenpos(0, line('.'), 1).col - win_screenpos(0)[1]
    let s:win = popup_create(line, {
    \    'line': 'cursor',
    \    'col': ui_width + 1,
    \    'maxwidth': strdisplaywidth(substitute(line, '[^[:print:]]*$', '', 'g')),
    \  })
  endif
  function! s:apply() abort closure
    call setbufline('%', 1, line)
    setlocal nowrap
    setlocal cursorline
    call a:helper.fern.renderer.syntax()
    call a:helper.fern.renderer.highlight()
    syntax clear FernRoot
    syntax clear FernRootText
    if has('nvim')
      setlocal winhighlight=NormalFloat:Normal
    endif
  endfunction
  call win_execute(s:win, 'call s:apply()', v:true)
endfunction

function! s:hide() abort
  if s:win is# v:null
    return
  endif
  if has('nvim')
    call nvim_win_hide(s:win)
  else
    call popup_close(s:win)
  endif
  let s:win = v:null
endfunction

