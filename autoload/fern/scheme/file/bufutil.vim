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
      call s:patch155()
    endfor
  finally
    execute printf('keepjumps keepalt %dbuffer', bufnr_saved)
    let &hidden = hidden_saved
  endtry
endfunction

" NOTE:
" Avoid E13 on :write once to fix #155.
" Let me know if you know better way to fix that.
function! s:patch155() abort
  let b:fern_scheme_file_bufutil_patch155 = {
        \ 'buftype': &buftype,
        \ 'bufname': bufname('%'),
        \}
  setlocal buftype=acwrite
  augroup fern_schem_file_bufutil_patch155
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> ++once ++nested call s:patch155_BufWriteCmd()
  augroup END
endfunction

function! s:patch155_BufWriteCmd() abort
  let patch = get(b:, 'fern_scheme_file_bufutil_patch155', {})
  silent! unlet! b:fern_scheme_file_bufutil_patch155
  let &buftype = get(patch, 'buftype', '')
  try
    execute printf('write%s %s', v:cmdbang ? '!' : '', v:cmdarg)
  catch /^Vim\%((\a\+)\)\=:E13:/
    if bufname('%') !=# get(patch, 'bufname', '')
      " filename had changed by user thus do NOT avoid E13
      echohl ErrorMsg
      echomsg substitute(v:exception, '^Vim(.\{-}):', '', '')
      echohl None
      return
    endif
    execute printf('write! %s', v:cmdarg)
  endtry
  " Mimic native write output
  let info = split(execute("normal! g\<C-g>"), ';')
  echomsg printf(
        \ '"%s" %dL, %dC written',
        \ expand('%:p:~'),
        \ split(get(info, 1, '0'))[-1],
        \ split(get(info, 3, '0'))[-1],
        \)
endfunction
