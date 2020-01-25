let s:Opener = vital#trea#import('Vim.Buffer.Opener')
let s:Promise = vital#trea#import('Async.Promise')

function! trea#lib#buffer#replace(bufnr, content) abort
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

function! trea#lib#buffer#open(bufname, ...) abort
  let options = extend({
        \ 'opener': 'edit',
        \ 'mods': '',
        \ 'cmdarg': '',
        \ 'locator': 0,
        \}, a:0 ? a:1 : {},
        \)
  if options.opener ==# 'select'
    let options.opener = 'edit'
    if trea#lib#window#select()
      return s:Promise.reject('Cancelled')
    endif
  else
    if options.locator
      call trea#lib#window#locate()
    endif
  endif
  return s:Promise.new(funcref('s:executor', [a:bufname, options]))
endfunction

function! s:executor(bufname, options, resolve, reject) abort
  let context = s:Opener.open(a:bufname, {
        \ 'opener': a:options.opener,
        \ 'mods': a:options.mods,
        \ 'cmdarg': a:options.cmdarg,
        \})
  call a:resolve(context)
endfunction
