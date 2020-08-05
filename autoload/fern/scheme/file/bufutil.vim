function! fern#scheme#file#bufutil#removes(paths) abort
  for path in a:paths
    let bufnr = bufnr(path)
    if bufnr is# -1 || getbufvar(bufnr, '&modified')
      continue
    endif
    execute printf('silent! noautocmd %dbwipeout', bufnr)
  endfor
endfunction

function! fern#scheme#file#bufutil#moves(pairs) abort
  let bufnr_saved = bufnr('%')
  let hidden_saved = &hidden
  set hidden
  try
    for [src, dst] in a:pairs
      let bufnr = bufnr(src)
      if bufnr is# -1
        return
      endif
      execute printf('silent! noautocmd keepjumps keepalt %dbuffer', bufnr)
      execute printf('silent! noautocmd keepalt file %s', fnameescape(dst))
    endfor
  finally
    execute printf('keepjumps keepalt %dbuffer', bufnr_saved)
    let &hidden = hidden_saved
  endtry
endfunction
