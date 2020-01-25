let s:pattern = '^$~.*[]\'

function! fern#lib#string#escape_pattern(str) abort
  return escape(a:str, s:pattern)
endfunction

