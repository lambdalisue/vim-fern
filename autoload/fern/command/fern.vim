let s:Config = vital#fern#import('Config')
let s:Path = vital#fern#import('System.Filepath')

let s:options = [
      \ '-drawer',
      \ '-width=',
      \ '-keep',
      \ '-reveal=',
      \ '-toggle',
      \ '-opener',
      \]

function! fern#command#fern#command(mods, qargs) abort
  try
    let [options, args] = fern#command#parse(a:qargs)

    if len(args) is# 0
      throw 'at least one argument is required'
    endif

    let opener = options.pop('opener', v:null)
    let toggle = options.pop('toggle', 0)
    let url = s:init(fern#lib#url#parse(expand(args[0])), options)

    call options.throw_if_dirty()

    if empty(url.query.drawer)
      call fern#internal#viewer#open(fern#lib#url#format(url), {
            \ 'mods': a:mods,
            \ 'opener': opener is# v:null
            \   ? g:fern#command#fern#viewer_opener
            \   : opener,
            \})
    else
      call fern#internal#drawer#open(fern#lib#url#format(url), {
            \ 'mods': a:mods,
            \ 'opener': opener is# v:null
            \   ? g:fern#command#fern#drawer_opener
            \   : opener,
            \ 'toggle': toggle,
            \})
    endif
  catch
    call fern#message#error(v:exception)
    call fern#message#debug(v:throwpoint)
  endtry
endfunction

function! fern#command#fern#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^-'
    return filter(copy(s:options), { -> v:val =~# '^' . a:arglead })
  endif
  return getcompletion('', 'dir')
endfunction

function! s:init(url, options) abort
  if empty(a:url.scheme)
    let a:url.scheme = 'file'
  endif

  " Create query from the options
  let a:url.query = extend(a:url.query, {
        \ 'reveal': a:options.pop('reveal', v:null),
        \ 'drawer': a:options.pop('drawer', v:null),
        \ 'width': a:options.pop('width', v:null),
        \ 'keep': a:options.pop('keep', v:null),
        \})

  " Scheme specific method
  call fern#scheme#call(a:url.scheme, 'command#init', a:url, a:options)

  " Check if the final scheme exists
  if !fern#scheme#exists(a:url.scheme)
    throw printf("no scheme %s is found under fern#scheme", a:url.scheme)
  endif

  " Normalize reveal
  if !empty(a:url.query.reveal) && a:url.query.reveal[:0] ==# '/'
    let a:url.query.reveal = fern#lib#url#relative(a:url.query.reveal, a:url.path)
  endif

  return a:url
endfunction

call s:Config.config(expand('<sfile>:p'), {
      \ 'viewer_opener': 'edit',
      \ 'drawer_opener': 'topleft vsplit',
      \})
