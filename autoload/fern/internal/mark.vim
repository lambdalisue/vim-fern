function! fern#internal#mark#replace(bufnr, lnums) abort
  call execute(printf('sign unplace * group=fern-mark buffer=%d', a:bufnr))
  call map(a:lnums, { _, v -> execute(printf(
        \ 'sign place %d group=fern-mark line=%d name=FernSignMarked buffer=%d',
        \ v,
        \ v,
        \ a:bufnr,
        \))})
endfunction

function! s:define_signs() abort
  execute printf(
        \ 'sign define FernSignMarked text=%s linehl=FernMarkedLine texthl=FernMarkedText',
        \ g:fern#mark_symbol,
        \)
endfunction

function! s:define_highlight() abort
  highlight default link FernMarkedLine Title
  highlight default link FernMarkedText Title
endfunction

augroup fern_mark_internal
  autocmd!
  autocmd ColorScheme * call s:define_highlight()
augroup END

call s:define_signs()
call s:define_highlight()
