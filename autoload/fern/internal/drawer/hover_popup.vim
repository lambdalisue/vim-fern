let s:win = v:null
let s:show_timer = 0

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
    autocmd CursorMoved <buffer> call s:debounced_show()
    autocmd BufLeave <buffer> call s:hide()
  augroup END
endfunction

function! s:available() abort
  let has_win = has('nvim') || exists('*popup_create')
  return has_win && exists('*win_execute')
endfunction

function! s:debounced_show() abort
  call s:hide()
  let s:show_timer = timer_start(g:fern#drawer_hover_popup_delay, { -> s:show()  })
endfunction

function! s:show() abort
  if &filetype !=# 'fern'
    return
  endif
  call s:hide()

  if strdisplaywidth(getline('.')) <= winwidth(0)
    return
  endif

  let helper = fern#helper#new()
  let node = helper.sync.get_cursor_node()
  if node is# v:null
    return
  endif

  let line = getline('.')
  let width = strdisplaywidth(substitute(line, '[^[:print:]]*$', '', 'g'))
  if has('nvim')
    let s:win = nvim_open_win(nvim_create_buf(v:false, v:true), v:false, {
    \    'relative': 'win',
    \    'bufpos': [line('.') - 2, 0],
    \    'width': width,
    \    'height': 1,
    \    'noautocmd': v:true,
    \    'style': 'minimal',
    \  })
  else
    let ui_width = screenpos(0, line('.'), 1).col - win_screenpos(0)[1]
    let s:win = popup_create(line, {
    \    'line': 'cursor',
    \    'col': ui_width + 1,
    \    'maxwidth': width,
    \  })
  endif

  function! s:apply() abort closure
    call setbufline('%', 1, line)
    call helper.fern.renderer.syntax()
    call helper.fern.renderer.highlight()
    syntax clear FernRoot
    syntax clear FernRootText

    setlocal nowrap cursorline noswapfile nobuflisted buftype=nofile bufhidden=hide
    if has('nvim')
      setlocal winhighlight=NormalFloat:Normal
    endif
  endfunction
  call win_execute(s:win, 'call s:apply()', v:true)
endfunction

function! s:hide() abort
  call timer_stop(s:show_timer)

  if s:win is# v:null
    return
  endif
  if has('nvim')
    if nvim_win_is_valid(s:win)
      call nvim_win_close(s:win, v:true)
    endif
  else
    call popup_close(s:win)
  endif
  let s:win = v:null
endfunction

