let s:openers = [
      \ 'select',
      \ 'edit',
      \ 'edit/split',
      \ 'edit/vsplit',
      \ 'edit/tabedit',
      \ 'split',
      \ 'vsplit',
      \ 'tabedit',
      \ 'leftabove split',
      \ 'leftabove vsplit',
      \ 'rightbelow split',
      \ 'rightbelow vsplit',
      \ 'topleft split',
      \ 'topleft vsplit',
      \ 'botright split',
      \ 'botright vsplit',
      \]

function! fern#complete#opener(arglead, cmdline, cursorpos) abort
  if a:arglead !~# '^-opener='
    return []
  endif
  let pattern = '^' . a:arglead
  let candidates = map(copy(s:openers), { _, v -> printf('-opener=%s', v) })
  return filter(candidates, { _, v -> v =~# pattern })
endfunction
