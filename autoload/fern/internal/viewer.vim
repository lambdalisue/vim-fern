let s:Lambda = vital#fern#import('Lambda')
let s:Promise = vital#fern#import('Async.Promise')

function! fern#internal#viewer#open(fri, options) abort
  call fern#logger#debug('open:', a:fri)
  let bufname = fern#fri#format(a:fri)
  return s:Promise.new(funcref('s:open', [bufname, a:options]))
endfunction

function! fern#internal#viewer#init() abort
  let bufnr = bufnr('%')
  return s:init()
        \.then({ -> s:notify(bufnr, v:null) })
        \.catch({ e -> s:Lambda.pass(e, s:notify(bufnr, e)) })
endfunction

function! fern#internal#viewer#reveal(helper, path) abort
  let path = fern#internal#filepath#to_slash(a:path)
  let reveal = split(path, '/')
  let previous = a:helper.sync.get_cursor_node()
  return s:Promise.resolve()
        \.then({ -> a:helper.async.reveal_node(reveal) })
        \.then({ -> a:helper.async.redraw() })
        \.then({ -> a:helper.sync.focus_node(reveal) })
endfunction

function! s:open(bufname, options, resolve, reject) abort
  if fern#internal#buffer#open(a:bufname, a:options)
    call a:reject('Cancelled')
    return
  endif
  let b:fern_notifier = {
        \ 'resolve': a:resolve,
        \ 'reject': a:reject,
        \}
endfunction

function! s:init() abort
  execute printf(
        \ 'command! -buffer -bar -nargs=* -complete=customlist,%s FernReveal call s:reveal([<f-args>])',
        \ get(funcref('s:reveal_complete'), 'name'),
        \)

  setlocal buftype=nofile bufhidden=unload
  setlocal noswapfile nobuflisted nomodifiable
  setlocal signcolumn=yes

  augroup fern_viewer_internal
    autocmd! * <buffer>
    autocmd BufEnter <buffer> setlocal nobuflisted
    autocmd BufReadCmd <buffer> ++nested call s:BufReadCmd()
    autocmd ColorScheme <buffer> call s:ColorScheme()
    autocmd CursorMoved,CursorMovedI,BufLeave <buffer> let b:fern_cursor = getcurpos()[1:2]

    if !g:fern#disable_viewer_auto_duplication
      autocmd WinEnter <buffer> ++nested call s:WinEnter()
    endif

    if !g:fern#disable_viewer_hide_cursor
      autocmd BufEnter,WinEnter,CmdwinLeave,CmdlineLeave <buffer> setlocal cursorline
      autocmd BufEnter,WinEnter,CmdwinLeave,CmdlineLeave <buffer> call fern#internal#cursor#hide()
      autocmd BufLeave,WinLeave,CmdwinEnter,CmdlineEnter,VimLeave <buffer> call fern#internal#cursor#restore()
    endif
  augroup END

  " Add unique fragment to make each buffer uniq
  let bufname = bufname('%')
  let fri = fern#fri#parse(bufname)
  if empty(fri.authority)
    let fri.authority = sha256(localtime())[:7]
    let previous = bufname
    let bufname = fern#fri#format(fri)
    execute printf('silent! keepalt file %s', fnameescape(bufname))
    execute printf('silent! bwipeout %s', previous)
  endif

  let resource_uri = fri.path
  let scheme = fern#fri#parse(resource_uri).scheme
  let provider = fern#internal#scheme#provider_new(scheme)
  if provider is# v:null
    return s:Promise.reject(printf('no such scheme %s exists', scheme))
  endif

  try
    let b:fern = fern#internal#core#new(
          \ resource_uri,
          \ provider,
          \)
    let helper = fern#helper#new()
    let root = helper.sync.get_root_node()

    call fern#mapping#init(scheme)
    call fern#internal#drawer#init()
    call fern#internal#spinner#start()
    call helper.fern.renderer.highlight()
    call fern#hook#emit('viewer:highlight', helper)
    doautocmd <nomodeline> User FernHighlight

    " now the buffer is ready so set filetype to emit FileType
    setlocal filetype=fern
    call helper.fern.renderer.syntax()
    call fern#hook#emit('viewer:syntax', helper)
    doautocmd <nomodeline> User FernSyntax
    call fern#action#_init()

    let Profile = fern#profile#start('fern#internal#viewer:init')
    return s:Promise.resolve()
          \.then({ -> helper.async.expand_node(root.__key) })
          \.finally({ -> Profile('expand') })
          \.then({ -> helper.async.redraw() })
          \.finally({ -> Profile('redraw') })
          \.finally({ -> Profile() })
          \.then({ -> fern#hook#emit('viewer:ready', helper) })
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction

function! s:notify(bufnr, error) abort
  let notifier = getbufvar(a:bufnr, 'fern_notifier', v:null)
  if notifier isnot# v:null
    call setbufvar(a:bufnr, 'fern_notifier', v:null)
    if a:error is# v:null
      call notifier.resolve(a:bufnr)
    else
      call notifier.reject([a:bufnr, a:error])
    endif
  endif
endfunction

function! s:cache_content(helper) abort
  let bufnr = a:helper.bufnr
  let content = getbufline(bufnr, 1, '$')
  call setbufvar(bufnr, 'fern_viewer_cache_content', content)
endfunction

function! s:reveal(fargs) abort
  try
    let wait = fern#internal#args#pop(a:fargs, 'wait', v:false)
    if len(a:fargs) isnot# 1
          \ || type(wait) isnot# v:t_bool
      throw 'Usage: FernReveal {reveal} [-wait]'
    endif

    " Does all options are handled?
    call fern#internal#args#throw_if_dirty(a:fargs)

    let expr = expand(a:fargs[0])
    let helper = fern#helper#new()
    let promise = fern#internal#viewer#reveal(helper, expr)

    if wait
      let [_, err] = s:Promise.wait(
            \ promise,
            \ {
            \   'interval': 100,
            \   'timeout': 5000,
            \ },
            \)
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

function! s:reveal_complete(arglead, cmdline, cursorpos) abort
  let helper = fern#helper#new()
  let fri = fern#fri#parse(bufname('%'))
  let scheme = helper.fern.scheme
  let cmdline = fri.path
  let arglead = printf('-reveal=%s', a:arglead)
  let rs = fern#internal#complete#reveal(arglead, cmdline, a:cursorpos)
  return map(rs, { -> matchstr(v:val, '-reveal=\zs.*') })
endfunction

function! s:WinEnter() abort
  if len(win_findbuf(bufnr('%'))) < 2
    return
  endif
  " Only one window is allowed to display one fern buffer.
  " So create a new fern buffer with same options
  let fri = fern#fri#parse(bufname('%'))
  let fri.authority = ''
  let bufname = fern#fri#format(fri)
  execute printf('silent! keepalt edit %s', fnameescape(bufname))
endfunction

function! s:BufReadCmd() abort
  let helper = fern#helper#new()
  setlocal filetype=fern
  call helper.fern.renderer.syntax()
  call fern#hook#emit('viewer:syntax', helper)
  doautocmd <nomodeline> User FernSyntax
  setlocal modifiable
  call setline(1, get(b:, 'fern_viewer_cache_content', []))
  setlocal nomodifiable
  call helper.sync.set_cursor(get(b:, 'fern_cursor', getcurpos()[1:2]))
  let root = helper.sync.get_root_node()
  call s:Promise.resolve()
        \.then({ -> helper.async.reload_node(root.__key) })
        \.then({ -> helper.async.redraw() })
        \.then({ -> fern#hook#emit('viewer:ready', helper) })
        \.catch({ e -> fern#logger#error(e) })
endfunction

function! s:ColorScheme() abort
  let helper = fern#helper#new()
  call helper.fern.renderer.highlight()
  call fern#hook#emit('viewer:highlight', helper)
  doautocmd <nomodeline> User FernHighlight
endfunction

augroup fern-internal-viewer-internal
  autocmd!
  autocmd User FernSyntax :
  autocmd User FernHighlight :
augroup END

" Cache content to accelerate rendering
call fern#hook#add('viewer:redraw', { h -> s:cache_content(h) })

" Deprecated:
call fern#hook#add('viewer:highlight', { h -> fern#hook#emit('renderer:highlight', h) })
call fern#hook#add('viewer:syntax', { h -> fern#hook#emit('renderer:syntax', h) })
