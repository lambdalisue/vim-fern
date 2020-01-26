let s:Promise = vital#fern#import('Async.Promise')

function! fern#internal#viewer#open(bufname, ...) abort
  let options = extend({
        \ 'base': 'fern:file:///',
        \}, a:0 ? a:1 : {},
        \)
  let url = fern#lib#url#parse(options.base)
  let url.path = a:bufname
  let url.query = filter(url.query, { -> index(['reveal'], v:key) is# -1 })
  return fern#lib#buffer#open(fern#lib#url#format(url), options)
endfunction

function! fern#internal#viewer#init() abort
  if exists('b:fern') && !get(g:, 'fern_debug')
    return s:Promise.resolve()
  endif

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
  let url = fern#lib#url#parse(bufname('%'))
  if empty(url.fragment)
    let url.fragment = sha256(localtime())[:7]
    execute printf("keepalt file %s", fnameescape(fern#lib#url#format(url)))
  endif

  let scheme = fern#lib#url#parse(url.path).scheme
  let provider = fern#scheme#provider(scheme)
  if provider is# v:null
    return s:Promise.reject(printf("no such scheme %s exists", scheme))
  endif

  try
    let b:fern = fern#internal#core#new(
          \ url.path,
          \ fern#scheme#provider(scheme),
          \)
    let helper = fern#helper#new()
    let root = helper.get_root_node()

    call fern#internal#mapping#init(scheme)
    call fern#internal#drawer#init()
    call fern#internal#spinner#start()
    call fern#internal#renderer#highlight()

    " now the buffer is ready so set filetype to emit FileType
    setlocal filetype=fern
    call fern#internal#renderer#syntax()
    call fern#internal#action#init()

    let reveal = split(get(url.query, 'reveal', ''), '/')
    return s:Promise.resolve()
          \.then({ -> helper.expand_node(root.__key) })
          \.then({ -> helper.reveal_node(reveal) })
          \.then({ -> helper.redraw() })
          \.then({ -> helper.focus_node(reveal) })
  catch
    return s:Promise.reject(v:exception)
  endtry
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

function! s:BufReadCmd() abort
  call fern#internal#renderer#syntax()
  let helper = fern#helper#new()
  let root = helper.get_root_node()
  let cursor = get(b:, 'fern_cursor', getcurpos())
  call s:Promise.resolve()
        \.then({ -> helper.redraw() })
        \.then({ -> helper.set_cursor(cursor[1:2]) })
        \.then({ -> helper.reload_node(root.__key) })
        \.then({ -> helper.redraw() })
        \.catch({ e -> fern#message#error(e) })
endfunction

function! s:ColorScheme() abort
  call fern#internal#renderer#highlight()
endfunction
