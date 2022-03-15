function! fern#internal#drawer#hover_popup#init() abort
  if g:fern#disable_drawer_hover_popup
    return
  endif

  if !exists('*popup_create')
    call fern#logger#warn('hover popup is not supported, popup_create()
          \ does not exist. Disable this message
          \ with g:fern#disable_drawer_hover_popup.')
    return
  endif

  augroup fern_internal_drawer_hover_popup_init
    autocmd! * <buffer>
    autocmd CursorMoved <buffer> call s:cursor_moved_event()
  augroup END
endfunction

function! fern#internal#drawer#hover_popup#calculate_node_char_offset(node) abort
  " find line offset where label text begins
  let line = getline('.')
  let labelbegin = charidx(line, strridx(line, a:node.label))
  let labelbegin = labelbegin < 0 ? 0 : labelbegin

  let windowid = win_getid()

  " get cursor position in drawer window (char- and byte-indexed)
  let charpos = getcursorcharpos(windowid)
  let pos = getcurpos(windowid)

  " get cursor position relative to screen
  let cursorpos = screenpos(windowid, pos[1], pos[2])

  " calculate screen column where label text begins
  return cursorpos['col'] - charpos[2] + labelbegin
endfunction

function! fern#internal#drawer#hover_popup#should_display_popup() abort
  return len(getline('.')) >= winwidth(0)
endfunction

function! s:cursor_moved_event() abort
  let helper = fern#helper#new()

  if fern#internal#drawer#hover_popup#should_display_popup()
    call s:show_popup(helper)
  endif
endfunction

function! s:show_popup(helper) abort
  let node = a:helper.sync.get_cursor_node()
  if node is# v:null
    return
  endif

  let label_offset = fern#internal#drawer#hover_popup#calculate_node_char_offset(node)
  call popup_create(l:node.label, {
        \ 'line': 'cursor',
        \ 'col': label_offset + 1,
        \ 'moved': 'any',
        \})
endfunction

