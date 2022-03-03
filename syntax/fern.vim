if exists('b:current_syntax')
  finish
endif
let b:current_syntax = 'fern'

syntax clear

function! s:ColorScheme() abort
  let helper = fern#helper#new()
  call helper.fern.renderer.highlight()
  call fern#hook#emit('viewer:highlight', helper)
  doautocmd <nomodeline> User FernHighlight
endfunction

function! s:Syntax() abort
  let helper = fern#helper#new()
  call helper.fern.renderer.syntax()
  call fern#hook#emit('viewer:syntax', helper)
  doautocmd <nomodeline> User FernSyntax
endfunction

augroup fern_syntax_internal
  autocmd! * <buffer>
  autocmd ColorScheme <buffer> call s:ColorScheme()
augroup END

call s:ColorScheme()
call s:Syntax()
