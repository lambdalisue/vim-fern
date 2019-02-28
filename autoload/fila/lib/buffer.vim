let s:Opener = vital#fila#import('Vim.Buffer.Opener')
let s:WindowLocator = vital#fila#import('Vim.Window.Locator')
let s:WindowSelector = vital#fila#import('Vim.Window.Selector')
let s:Promise = vital#fila#import('Async.Promise')

function! fila#lib#buffer#open(bufname, options) abort
  let options = extend({
        \ 'opener': 'edit',
        \ 'mods': '',
        \ 'cmdarg': '',
        \ 'locator': 0,
        \ 'notifier': 0,
        \}, a:options)
  if options.opener ==# 'select'
    let options.opener = 'edit'
    if s:window_select()
      return s:Promise.reject('Cancelled')
    endif
  else
    if options.locator
      call s:WindowLocator.focus(winnr('#'))
    endif
  endif
  return s:Promise.new(funcref('s:executor', [a:bufname, options]))
endfunction

function! fila#lib#buffer#call(bufnr, fn, args, ...) abort
  if a:0
    return s:call(a:bufnr, function(a:fn, a:args, a:1))
  else
    return s:call(a:bufnr, function(a:fn, a:args))
  endif
endfunction

function! s:executor(bufname, options, resolve, reject) abort
  let context = s:Opener.open(a:bufname, {
        \ 'opener': a:options.opener,
        \ 'mods': a:options.mods,
        \ 'cmdarg': a:options.cmdarg,
        \ 'force': a:options.notifier,
        \})
  if a:options.notifier
    let b:fila_notifier = {
          \ 'notify': { -> a:resolve(context) },
          \}
    call context.end()
  else
    call a:resolve(context)
  endif
endfunction

function! s:window_select() abort
  let ws = filter(
        \ range(1, winnr('$')),
        \ { -> s:WindowLocator.is_suitable(v:val) },
        \)
  if empty(ws)
    let ws = range(1, winnr('$'))
  endif
  return s:WindowSelector.select(ws, {
        \ 'auto_select': 1,
        \})
endfunction

function! s:call(bufnr, fn) abort
  if bufnr('%') is# a:bufnr
    call a:fn()
  elseif bufwinid(a:bufnr) isnot# -1
    call s:call_on_window(a:bufnr)
  else
    call s:call_on_hidden(a:bufnr)
  endif
endfunction

function! s:call_on_window(bufnr, fn, args, instance) abort
  let winid = win_getid()
  try
    call win_gotoid(bufwinid(a:bufnr))
    call a:fn()
  finally
    call win_gotoid(winid)
  endtry
endfunction

function! s:call_on_hidden(bufnr, fn, args, instance) abort
  let bufnr = bufnr('%')
  let bufhidden = &bufhidden
  try
    setlocal bufhidden=hide
    silent execute printf('keepjumps keepalt %dbuffer', a:bufnr)
    call a:fn()
  finally
    silent execute printf('keepjumps keepalt %dbuffer', bufnr)
    let &bufhidden = bufhidden
  endtry
endfunction
