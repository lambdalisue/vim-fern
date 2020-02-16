let s:drawer_opener = 'topleft vsplit'
let s:options = [
      \ '-drawer',
      \ '-width=',
      \ '-keep',
      \ '-stay',
      \ '-wait',
      \ '-reveal=',
      \ '-toggle',
      \ '-opener=',
      \]

function! fern#internal#command#fern#command(mods, fargs) abort
  try
    let stay = fern#internal#args#pop(a:fargs, 'stay', v:false)
    let wait = fern#internal#args#pop(a:fargs, 'wait', v:false)
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
          \ || type(wait) isnot# v:t_bool
          \ || type(reveal) isnot# v:t_string
          \ || type(drawer) isnot# v:t_bool
          \ || type(opener) isnot# v:t_string
          \ || type(width) isnot# v:t_string
          \ || type(keep) isnot# v:t_bool
          \ || type(toggle) isnot# v:t_bool
      if empty(drawer)
        throw 'Usage: Fern {url} [-opener={opener}] [-stay] [-wait] [-reveal={reveal}]'
      else
        throw 'Usage: Fern {url} -drawer [-toggle] [-keep] [-width={width}] [-stay] [-wait] [-reveal={reveal}]'
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

    let wait_count = []
    if wait
      call fern#hook#add('read', { -> add(wait_count, 1) }, {
            \ 'once': v:true,
            \})
    endif

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

    if wait
      call s:wait({ -> len(wait_count) > 0 })
    endif

  catch
    echohl ErrorMsg
    echo v:exception
    echohl None
    call fern#logger#debug(v:exception)
    call fern#logger#debug(v:throwpoint)
  endtry
endfunction

function! fern#internal#command#fern#complete(arglead, cmdline, cursorpos) abort
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
  let root = fern#fri#parse(a:fri.path).path
  let reveal = fern#fri#parse(frag.path).path
  let a:fri.fragment = fern#internal#path#relative(reveal, root)
endfunction

function! s:wait(condition, ...) abort
  let options = extend({
        \ 'interval': 100,
        \ 'timeout': 5000,
        \}, a:0 ? a:1 : {},
        \)
  let start = reltime()
  let expr = printf('sleep %dm', options.interval)
  let dead = options.timeout isnot# v:null
        \ ? reltimefloat(start) + options.timeout / 1000
        \ : v:null
  while dead is# v:null || dead > reltimefloat(reltime(start))
    if a:condition()
      return 0
    endif
    execute expr
  endwhile
  return 1
endfunction
