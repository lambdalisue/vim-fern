let s:Opener = vital#fila#import('Vim.Buffer.Opener')
let s:WindowLocator = vital#fila#import('Vim.Window.Locator')
let s:WindowSelector = vital#fila#import('Vim.Window.Selector')
let s:Promise = vital#fila#import('Async.Promise')

function! fila#buffer#open(bufname, options) abort
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
      call s:WindowLocator.focus(winnr())
    endif
  endif
  return s:Promise.new(funcref('s:executor', [a:bufname, options]))
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
