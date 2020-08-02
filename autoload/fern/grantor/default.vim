function! fern#grantor#default#new() abort
  return {
        \ 'grant': { -> 0 },
        \ 'syntax': { -> 0 },
        \ 'highlight': { -> 0 },
        \}
endfunction
