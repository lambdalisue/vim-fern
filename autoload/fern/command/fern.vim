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
    let [options, args] = fern#internal#command#parse(a:qargs)

    if len(args) is# 0
      throw 'at least one argument is required'
    endif

    let toggle = options.pop('toggle', 0)
    let opener = options.pop('opener', v:null)
    let viewer_opener = opener is# v:null
          \ ? g:fern#command#fern#viewer_opener
          \ : opener
    let drawer_opener = opener is# v:null
          \ ? g:fern#command#fern#drawer_opener
          \ : opener

    " Force project drawer style when
    " - The current buffer is project drawer style fern
    " - The 'opener' is 'edit'
    if viewer_opener ==# 'edit' && fern#internal#drawer#is_drawer()
      call options.set('drawer', v:true)
    endif

    " Build FRI for fern buffer from argument
    let expr = expand(args[0])
    let fri = fern#internal#bufname#parse(expr)
    let fri.authority = options.pop('drawer', v:false)
          \ ? printf('drawer:%d', tabpagenr())
          \ : ''
    let fri.query = extend(fri.query, {
          \ 'width': options.pop('width', v:null),
          \ 'keep': options.pop('keep', v:null),
          \})
    let fri.fragment = expand(options.pop('reveal', ''))

    " Does all options are handled?
    call options.throw_if_dirty()

    " Normalize fragment
    call s:norm_fragment(fri)

    if fri.authority =~# '\<drawer\>'
      call fern#internal#drawer#open(fri, {
            \ 'mods': a:mods,
            \ 'toggle': toggle,
            \ 'opener': drawer_opener,
            \})
    else
      call fern#internal#viewer#open(fri, {
            \ 'mods': a:mods,
            \ 'opener': viewer_opener,
            \})
    endif
  catch
    call fern#logger#error(v:exception)
    call fern#logger#debug(v:throwpoint)
  endtry
endfunction

function! fern#command#fern#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^-'
    return filter(copy(s:options), { -> v:val =~# '^' . a:arglead })
  endif
  return getcompletion('', 'dir')
endfunction

function! s:norm_fragment(fri) abort
  if empty(a:fri.fragment)
    return
  endif
  let frag = fern#internal#bufname#parse(a:fri.fragment)
  let root = split(fern#fri#parse(a:fri.path).path, '/')
  let root = fern#internal#path#simplify(root)
  let reveal = split(fern#fri#parse(frag.path).path, '/')
  let reveal = fern#internal#path#simplify(reveal)
  let reveal = fern#internal#path#relative(reveal, root)
  let a:fri.fragment = join(reveal, '/')
endfunction


call s:Config.config(expand('<sfile>:p'), {
      \ 'viewer_opener': 'edit',
      \ 'drawer_opener': 'topleft vsplit',
      \})
