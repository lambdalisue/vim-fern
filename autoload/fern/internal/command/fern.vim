let s:Promise = vital#fern#import('Async.Promise')
let s:drawer_left_opener = 'topleft vsplit'
let s:drawer_right_opener = 'botright vsplit'

function! fern#internal#command#fern#command(mods, fargs) abort
  try
    let stay = fern#internal#args#pop(a:fargs, 'stay', v:false)
    let wait = fern#internal#args#pop(a:fargs, 'wait', v:false)
    let reveal = fern#internal#args#pop(a:fargs, 'reveal', '')
    let drawer = fern#internal#args#pop(a:fargs, 'drawer', v:false)
    if drawer
      let width = fern#internal#args#pop(a:fargs, 'width', '')
      let keep = fern#internal#args#pop(a:fargs, 'keep', v:false)
      let toggle = fern#internal#args#pop(a:fargs, 'toggle', v:false)
      let right = fern#internal#args#pop(a:fargs, 'right', v:false)
      let opener = right ? s:drawer_right_opener : s:drawer_left_opener
    else
      let opener = fern#internal#args#pop(a:fargs, 'opener', g:fern#opener)
      let width = ''
      let keep = v:false
      let toggle = v:false
      let right = v:false
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
          \ || type(right) isnot# v:t_bool
      if empty(drawer)
        throw 'Usage: Fern {url} [-opener={opener}] [-stay] [-wait] [-reveal={reveal}]'
      else
        throw 'Usage: Fern {url} -drawer [-right] [-toggle] [-keep] [-width={width}] [-stay] [-wait] [-reveal={reveal}]'
      endif
    endif

    " Does all options are handled?
    call fern#internal#args#throw_if_dirty(a:fargs)

    " Force project drawer style when
    " - The current buffer is project drawer style fern
    " - The 'opener' is 'edit'
    if opener ==# 'edit'
      if fern#internal#drawer#is_left_drawer()
        let drawer = v:true
        let opener = s:drawer_left_opener
      elseif right && fern#internal#drawer#is_right_drawer()
        let drawer = v:true
        let opener = s:drawer_right_opener
      endif
    endif

    let expr = fern#util#expand(a:fargs[0])
    let path = fern#fri#format(
          \ expr =~# '^[^:]\+://'
          \   ? fern#fri#parse(expr)
          \   : fern#fri#from#filepath(fnamemodify(expr, ':p'))
          \)
    " Build FRI for fern buffer from argument
    let fri = fern#fri#new({
          \ 'scheme': 'fern',
          \ 'path': path,
          \})
    let fri.authority = drawer
          \ ? right
          \   ? printf('drawer-right:%d', tabpagenr())
          \   : printf('drawer:%d', tabpagenr())
          \ : ''
    if drawer && g:fern#disable_drawer_tabpage_isolation
      let fri.authority = right ? 'drawer-right:0' : 'drawer:0'
    endif
    let fri.query = extend(fri.query, {
          \ 'width': width,
          \ 'keep': keep,
          \})
    call fern#logger#debug('expr:', expr)
    call fern#logger#debug('fri:', fri)

    " A promise which will be resolved once the viewer become ready
    let waiter = fern#hook#promise('viewer:ready')

    " Register callback to reveal node
    let reveal = fern#internal#command#reveal#normalize(fri, reveal)
    if reveal !=# ''
      let waiter = waiter.then({ h -> fern#internal#viewer#reveal(h, reveal) })
    endif

    let winid_saved = win_getid()
    if fri.authority =~# '^drawer\(-right\)\?:'
      call fern#internal#drawer#open(fri, {
            \ 'mods': a:mods,
            \ 'toggle': toggle,
            \ 'opener': opener,
            \ 'stay': stay ? win_getid() : 0,
            \ 'right': right,
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
      let [_, err] = s:Promise.wait(waiter, {
            \ 'interval': 100,
            \ 'timeout': 5000,
            \})
      if err isnot# v:null
        throw printf('[fern] Failed to wait: %s', err)
      endif
    endif
  catch
    echohl ErrorMsg
    echomsg v:exception
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
