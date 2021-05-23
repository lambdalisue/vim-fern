let s:t_ve_saved = &t_ve
let s:guicursor_saved = &guicursor

function! fern#internal#cursor#hide() abort
  call s:hide()
endfunction

function! fern#internal#cursor#restore() abort
  call s:restore()
endfunction

if has('nvim-0.5.0')
  " https://github.com/neovim/neovim/issues/3688#issuecomment-574544618
  function! s:hide() abort
    set guicursor+=a:FernTransparentCursor/lCursor
  endfunction

  function! s:restore() abort
    set guicursor+=a:Cursor/lCursor
    let &guicursor = s:guicursor_saved
  endfunction

  function! s:highlight() abort
    highlight default FernTransparentCursor gui=strikethrough blend=100
  endfunction
  call s:highlight()

  augroup fern_internal_cursor
    autocmd!
    autocmd ColorScheme * call s:highlight()
  augroup END
elseif has('nvim') || has('gui_running')
  " No way thus use narrow cursor instead
  function! s:hide() abort
    set guicursor+=a:ver1
  endfunction

  function! s:restore() abort
    let &guicursor = s:guicursor_saved
  endfunction
else
  " Vim supports 't_ve'
  function! s:hide() abort
    set t_ve=
  endfunction

  function! s:restore() abort
    let &t_ve = s:t_ve_saved
  endfunction
endif
