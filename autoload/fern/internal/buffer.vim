let s:edit_or_opener_pattern = '\<edit/\zs\%(split\|vsplit\|tabedit\)\>'

function! fern#internal#buffer#replace(bufnr, content) abort
  let modified_saved = getbufvar(a:bufnr, '&modified')
  let modifiable_saved = getbufvar(a:bufnr, '&modifiable')
  try
    call setbufvar(a:bufnr, '&modifiable', 1)

    if g:fern#enable_textprop_support
      call s:replace_buffer_content(a:bufnr, a:content)
    else
      call setbufline(a:bufnr, 1, a:content)
      call deletebufline(a:bufnr, len(a:content) + 1, '$')
    endif
  finally
    call setbufvar(a:bufnr, '&modifiable', modifiable_saved)
    call setbufvar(a:bufnr, '&modified', modified_saved)
  endtry
endfunction

" Replace buffer content with lines of text with (optional) text properties.
function! s:replace_buffer_content(bufnr, content) abort
  for lnum in range(len(a:content))
    let line = a:content[lnum]
    let [text, props] = type(line) is# v:t_dict
      \ ? [line.text, get(line, 'props', [])]
      \ : [line, []]

    call setbufline(a:bufnr, lnum + 1, text)

    if exists('*prop_add')
      for prop in props
        let prop.bufnr = a:bufnr
        call prop_add(lnum + 1, prop.col, prop)
      endfor
    endif
  endfor

  call deletebufline(a:bufnr, len(a:content) + 1, '$')
endfunction

function! fern#internal#buffer#open(bufname, ...) abort
  let options = extend({
        \ 'opener': 'edit',
        \ 'mods': '',
        \ 'cmdarg': '',
        \ 'locator': 0,
        \ 'keepalt': 0,
        \ 'keepjumps': 0,
        \}, a:0 ? a:1 : {},
        \)
  if options.opener ==# 'select'
    let options.opener = 'edit'
    if fern#internal#window#select()
      return 1
    endif
  else
    if options.locator
      call fern#internal#locator#focus(winnr('#'))
    endif
  endif
  if options.opener =~# s:edit_or_opener_pattern
    let opener2 = matchstr(options.opener, s:edit_or_opener_pattern)
    let options.opener = &modified ? opener2 : 'edit'
  endif
  if options.keepalt && options.opener ==# 'edit'
    let options.mods .= ' keepalt'
  endif
  if options.keepjumps && options.opener ==# 'edit'
    let options.mods .= ' keepjumps'
  endif
  " Use user frindly path on a real path to fix #284
  let bufname = filereadable(a:bufname)
        \ ? fnamemodify(a:bufname, ':~:.')
        \ : a:bufname
  let args = [
        \ options.mods,
        \ options.cmdarg,
        \ options.opener,
        \ fnameescape(bufname),
        \]
  let cmdline = join(filter(args, { -> !empty(v:val) }), ' ')
  call fern#logger#debug('fern#internal#buffer#open', 'cmdline', cmdline)
  execute cmdline
endfunction

function! fern#internal#buffer#removes(paths) abort
  for path in a:paths
    let bufnr = bufnr(path)
    if bufnr is# -1 || getbufvar(bufnr, '&modified')
      continue
    endif
    execute printf('silent! noautocmd %dbwipeout', bufnr)
  endfor
endfunction

function! fern#internal#buffer#renames(pairs) abort
  let bufnr_saved = bufnr('%')
  let hidden_saved = &bufhidden
  set bufhidden=hide
  try
    for [src, dst] in a:pairs
      let bufnr = bufnr(src)
      if bufnr is# -1
        return
      endif
      execute printf('silent! noautocmd keepjumps keepalt %dbuffer', bufnr)
      execute printf('silent! noautocmd keepalt file %s', fnameescape(dst))
      call s:patch_to_avoid_e13()
    endfor
  finally
    execute printf('keepjumps keepalt %dbuffer!', bufnr_saved)
    let &bufhidden = hidden_saved
  endtry
endfunction

" NOTE: Perform pseudo 'write!' to avoid E13
function! s:patch_to_avoid_e13() abort
  augroup fern_internal_buffer_patch_to_avoid_e13
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> ++once :
  augroup END
  let buftype = &buftype
  let modified = &modified
  try
    setlocal buftype=acwrite
    silent! write!
  finally
    let &buftype = buftype
    let &modified = modified
  endtry
endfunction
