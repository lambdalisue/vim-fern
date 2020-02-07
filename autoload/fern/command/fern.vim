let s:Path = vital#fern#import('System.Filepath')

let s:drawer_opener = 'topleft vsplit'
let s:options = [
      \ '-drawer',
      \ '-width=',
      \ '-keep',
      \ '-stay',
      \ '-reveal=',
      \ '-toggle',
      \ '-opener=',
      \]

function! fern#command#fern#command(mods, fargs) abort
  try
    let stay = fern#internal#args#pop(a:fargs, 'stay', v:false)
    let reveal = fern#internal#args#pop(a:fargs, 'reveal', '')
    let drawer = fern#internal#args#pop(a:fargs, 'drawer', v:false)
    if drawer
      let opener = s:drawer_opener
      let width = fern#internal#args#pop(a:fargs, 'width', '')
      let keep = fern#internal#args#pop(a:fargs, 'keep', v:false)
      let toggle = fern#internal#args#pop(a:fargs, 'toggle', v:false)
    else
      let opener = fern#internal#args#pop(a:fargs, 'opener', g:fern#opener)
      let width = ''
      let keep = v:false
      let toggle = v:false
    endif

    if len(a:fargs) isnot# 1
          \ || type(stay) isnot# v:t_bool
          \ || type(reveal) isnot# v:t_string
          \ || type(drawer) isnot# v:t_bool
          \ || type(opener) isnot# v:t_string
          \ || type(width) isnot# v:t_string
          \ || type(keep) isnot# v:t_bool
          \ || type(toggle) isnot# v:t_bool
      if empty(drawer)
        throw 'Usage: Fern {url} [-opener={opener}] [-stay] [-reveal={reveal}]'
      else
        throw 'Usage: Fern {url} -drawer [-toggle] [-keep] [-width={width}] [-stay] [-reveal={reveal}]'
      endif
    endif

    " Does all options are handled?
    call fern#internal#args#throw_if_dirty(a:fargs)

    " Force project drawer style when
    " - The current buffer is project drawer style fern
    " - The 'opener' is 'edit'
    if opener ==# 'edit' && fern#internal#drawer#is_drawer()
      let drawer = v:true
      let opener = s:drawer_opener
    endif

    let expr = expand(a:fargs[0])
    " Build FRI for fern buffer from argument
    let fri = fern#internal#bufname#parse(expr)
    let fri.authority = drawer
          \ ? printf('drawer:%d', tabpagenr())
          \ : ''
    let fri.query = extend(fri.query, {
          \ 'width': width,
          \ 'keep': keep,
          \})
    let fri.fragment = expand(reveal)

    " Normalize fragment if expr does not start from {scheme}://
    if expr !~# '^[^:]\+://'
      call s:norm_fragment(fri)
    endif

    call fern#logger#debug('fri:', fri)

    let winid_saved = win_getid()
    if fri.authority =~# '\<drawer\>'
      call fern#internal#drawer#open(fri, {
            \ 'mods': a:mods,
            \ 'toggle': toggle,
            \ 'opener': opener,
            \ 'stay': stay ? win_getid() : 0,
            \})
    else
      call fern#internal#viewer#open(fri, {
            \ 'mods': a:mods,
            \ 'opener': opener,
            \ 'stay': stay ? win_getid() : 0,
            \})
    endif
    if stay
      call win_gotoid(winid_saved)
    endif
  catch
    echohl ErrorMsg
    echo v:exception
    echohl None
    call fern#logger#debug(v:exception)
    call fern#logger#debug(v:throwpoint)
  endtry
endfunction

function! fern#command#fern#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^-opener='
    return fern#internal#complete#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^-reveal='
    return fern#internal#complete#reveal(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^-'
    return fern#internal#complete#options(a:arglead, a:cmdline, a:cursorpos)
  endif
  return fern#internal#complete#url(a:arglead, a:cmdline, a:cursorpos)
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
