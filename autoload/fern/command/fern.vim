let s:Path = vital#fern#import('System.Filepath')

let s:drawer_opener = 'topleft vsplit'
let s:options = [
      \ '-drawer',
      \ '-width=',
      \ '-keep',
      \ '-reveal=',
      \ '-toggle',
      \ '-opener=',
      \]

function! fern#command#fern#command(mods, qargs) abort
  try
    let [options, args] = fern#internal#command#parse(a:qargs)

    if len(args) isnot# 1
      echohl ErrorMsg
      echo 'Usage: Fern {url} [-opener={opener}|-drawer][-toggle][-keep][-width={width}]'
      echohl None
      return
    endif

    let drawer = options.pop('drawer', v:false)
    if drawer
      let opener = s:drawer_opener
      let width = options.pop('width', v:null)
      let keep = options.pop('keep', v:null)
      let toggle = options.pop('toggle', v:null)
    else
      let opener = options.pop('opener', g:fern#opener)
      let width = v:null
      let keep = v:null
      let toggle = v:null
    endif

    " Force project drawer style when
    " - The current buffer is project drawer style fern
    " - The 'opener' is 'edit'
    if opener ==# 'edit' && fern#internal#drawer#is_drawer()
      let drawer = v:true
      let opener = s:drawer_opener
    endif

    let expr = expand(args[0])
    " Build FRI for fern buffer from argument
    let fri = fern#internal#bufname#parse(expr)
    let fri.authority = drawer
          \ ? printf('drawer:%d', tabpagenr())
          \ : ''
    let fri.query = extend(fri.query, {
          \ 'width': width,
          \ 'keep': keep,
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
            \ 'opener': opener,
            \})
    else
      call fern#internal#viewer#open(fri, {
            \ 'mods': a:mods,
            \ 'opener': opener,
            \})
    endif
  catch
    call fern#logger#error(v:exception)
    call fern#logger#debug(v:throwpoint)
  endtry
endfunction

function! fern#command#fern#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^-opener='
    return fern#complete#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^-'
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
