let s:Lambda = vital#fern#import('Lambda')
let s:Promise = vital#fern#import('Async.Promise')

function! fern#internal#viewer#open(fri, options) abort
  let bufname = fern#fri#format(a:fri)
  return s:Promise.new(funcref('s:open', [bufname, a:options]))
endfunction

function! fern#internal#viewer#init() abort
  if exists('b:fern') && !get(g:, 'fern_debug')
    return s:Promise.resolve()
  endif
  let bufnr = bufnr('%')
  return s:init()
        \.then({ -> s:notify(bufnr, v:null) })
        \.catch({ e -> s:Lambda.pass(e, s:notify(bufnr, e)) })
endfunction

function! fern#internal#viewer#focus_next(...) abort
  let options = extend({
        \ 'origin': winnr() + 1,
        \ 'predicator': { -> 1 },
        \}, a:0 ? a:1 : {},
        \)
  let P = { n -> bufname(winbufnr(n)) =~# '^fern:' && options.predicator(n) }
  let winnr = fern#lib#window#find(P, options.origin)
  if winnr
    execute printf('%dwincmd w', winnr)
    return 1
  endif
endfunction

function! fern#internal#viewer#do_next(command, ...) abort
  if fern#internal#viewer#focus_next(a:0 ? a:1 : {})
    execute a:command
  endif
endfunction

function! s:open(bufname, options, resolve, reject) abort
  call fern#lib#buffer#open(a:bufname . '$', a:options)
  let b:fern_notifier = {
        \ 'resolve': a:resolve,
        \ 'reject': a:reject,
        \}
endfunction

function! s:init() abort
  setlocal buftype=nofile bufhidden=unload
  setlocal noswapfile nobuflisted nomodifiable
  setlocal signcolumn=yes

  augroup fern_viewer_internal
    autocmd! * <buffer>
    autocmd BufEnter <buffer> setlocal nobuflisted
    autocmd BufReadCmd <buffer> nested call s:BufReadCmd()
    autocmd ColorScheme <buffer> call s:ColorScheme()
    autocmd CursorMoved,CursorMovedI <buffer> let b:fern_cursor = getcurpos()
  augroup END

  " Add unique fragment to make each buffer uniq
  let bufname = bufname('%')
  let fri = fern#internal#bufname#parse(bufname)
  if empty(fri.authority)
    let fri.authority = sha256(localtime())[:7]
    let bufname = fern#fri#format(fri)
    execute printf("silent keepalt file %s$", fnameescape(bufname))
  endif

  let resource_uri = fri.path
  let scheme = fern#fri#parse(resource_uri).scheme
  let provider = fern#internal#scheme#provider(scheme)
  if provider is# v:null
    return s:Promise.reject(printf("no such scheme %s exists", scheme))
  endif

  try
    let b:fern = fern#internal#core#new(
          \ resource_uri,
          \ fern#internal#scheme#provider(scheme),
          \)
    let helper = fern#helper#new()
    let root = helper.get_root_node()

    call fern#internal#mapping#init(scheme)
    call fern#internal#drawer#init()
    call fern#internal#spinner#start()
    call helper.fern.renderer.highlight()

    " now the buffer is ready so set filetype to emit FileType
    setlocal filetype=fern
    call helper.fern.renderer.syntax()
    call fern#internal#action#init()

    let reveal = split(fri.fragment, '/')
    let Profile = fern#profile#start("fern#internal#viewer:init")
    return s:Promise.resolve()
          \.then({ -> helper.expand_node(root.__key) })
          \.finally({ -> Profile("expand") })
          \.then({ -> helper.reveal_node(reveal) })
          \.finally({ -> Profile("reveal") })
          \.then({ -> helper.redraw() })
          \.finally({ -> Profile("redraw") })
          \.then({ -> helper.focus_node(reveal) })
          \.finally({ -> Profile() })
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

function! s:BufReadCmd() abort
  let helper = fern#helper#new()
  call helper.fern.renderer.syntax()
  let root = helper.get_root_node()
  let cursor = get(b:, 'fern_cursor', getcurpos())
  call s:Promise.resolve()
        \.then({ -> helper.redraw() })
        \.then({ -> helper.set_cursor(cursor[1:2]) })
        \.then({ -> helper.reload_node(root.__key) })
        \.then({ -> helper.redraw() })
        \.catch({ e -> fern#logger#error(e) })
endfunction

function! s:ColorScheme() abort
  let helper = fern#helper#new()
  call helper.fern.renderer.highlight()
endfunction
