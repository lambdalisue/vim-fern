if exists('b:current_syntax')
  finish
endif

function! s:define_syntax() abort
  let helper = fila#helper#new()
  call helper.renderer.syntax()
endfunction

function! s:define_highlight() abort
  let helper = fila#helper#new()
  call helper.renderer.highlight()
endfunction

augroup fila_syntax_changes_internal
  autocmd! *
  autocmd ColorScheme * call s:define_highlight()
augroup END

call s:define_syntax()
call s:define_highlight()

let b:current_syntax = 'fila'
