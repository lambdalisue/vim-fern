let s:edit_or_opener_pattern = '\<edit/\zs\%(split\|vsplit\|tabedit\)\>'

function! fern#internal#buffer#replace(bufnr, content) abort
  let modified_saved = getbufvar(a:bufnr, '&modified')
  let modifiable_saved = getbufvar(a:bufnr, '&modifiable')
  try
    call setbufvar(a:bufnr, '&modifiable', 1)
    call setbufline(a:bufnr, 1, a:content)
    call deletebufline(a:bufnr, len(a:content) + 1, '$')
  finally
    call setbufvar(a:bufnr, '&modifiable', modifiable_saved)
    call setbufvar(a:bufnr, '&modified', modified_saved)
  endtry
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
    let options.opener = &modified ? opener2 : options.opener
  endif
  if options.keepalt && options.opener ==# 'edit'
    let options.mods .= ' keepalt'
  endif
  if options.keepjumps && options.opener ==# 'edit'
    let options.mods .= ' keepjumps'
  endif
  let args = [
        \ options.mods,
        \ options.cmdarg,
        \ options.opener,
        \ fnameescape(a:bufname),
        \]
  let cmdline = join(filter(args, { -> !empty(v:val) }), ' ')
  call fern#logger#debug('fern#internal#buffer#open', 'cmdline', cmdline)
  execute cmdline
endfunction
