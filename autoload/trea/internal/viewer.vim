let s:Promise = vital#trea#import('Async.Promise')

function! trea#internal#viewer#open(bufname, ...) abort
  let options = extend({
        \ 'base': 'trea:file:///',
        \}, a:0 ? a:1 : {},
        \)
  let url = trea#lib#url#parse(options.base)
  let url.path = a:bufname
  let url.query = filter(url.query, { -> index(['reveal'], v:key) is# -1 })
  return trea#lib#buffer#open(url.to_string(), options)
endfunction

function! trea#internal#viewer#init() abort
  if exists('b:trea') && !get(g:, 'trea_debug')
    return
  endif

  setlocal buftype=nofile bufhidden=unload
  setlocal noswapfile nobuflisted nomodifiable
  setlocal signcolumn=yes
  setlocal filetype=trea

  augroup trea_viewer_internal
    autocmd! * <buffer>
    autocmd BufEnter <buffer> setlocal nobuflisted
    autocmd BufReadCmd <buffer> nested call s:BufReadCmd()
    autocmd ColorScheme <buffer> call s:ColorScheme()
    autocmd CursorMoved,CursorMovedI <buffer> let b:trea_cursor = getcurpos()
  augroup END

  " Add unique fragment to make each buffer uniq
  let url = trea#lib#url#parse(bufname('%'))
  if empty(url.fragment)
    let url.fragment = sha256(localtime())[:7]
    execute printf("keepalt file %s", fnameescape(url.to_string()))
  endif
  let scheme = trea#lib#url#parse(url.path).scheme
  let provider = trea#scheme#{scheme}#provider#new()
  let b:trea = trea#internal#core#new(url.path, provider)

  call trea#mapping#init(scheme)
  call trea#internal#action#init()
  call trea#internal#spinner#start()
  call trea#internal#renderer#highlight()
  call trea#internal#renderer#syntax()
  call trea#internal#drawer#init()

  let helper = trea#helper#new()
  let root = helper.get_root_node()
  let reveal = split(get(url.query, 'reveal', ''), '/')
  return s:Promise.resolve()
        \.then({ -> helper.expand_node(root.__key) })
        \.then({ -> helper.reveal_node(reveal) })
        \.then({ -> helper.redraw() })
        \.then({ -> helper.focus_node(reveal) })
endfunction

function! trea#internal#viewer#focus_next(...) abort
  let options = extend({
        \ 'origin': winnr() + 1,
        \ 'predicator': { -> 1 },
        \}, a:0 ? a:1 : {},
        \)
  let P = { n -> bufname(winbufnr(n)) =~# '^trea:' && options.predicator(n) }
  let winnr = trea#lib#window#find(P, options.origin)
  if winnr
    execute printf('%dwincmd w', winnr)
    return 1
  endif
endfunction

function! trea#internal#viewer#do_next(command, ...) abort
  if trea#internal#viewer#focus_next(a:0 ? a:1 : {})
    execute a:command
  endif
endfunction

function! s:BufReadCmd() abort
  call trea#internal#renderer#syntax()
  let helper = trea#helper#new()
  let root = helper.get_root_node()
  let cursor = get(b:, 'trea_cursor', getcurpos())
  call s:Promise.resolve()
        \.then({ -> helper.redraw() })
        \.then({ -> helper.set_cursor(cursor[1:2]) })
        \.then({ -> helper.reload_node(root.__key) })
        \.then({ -> helper.redraw() })
        \.catch({ e -> trea#message#error(e) })
endfunction

function! s:ColorScheme() abort
  call trea#internal#renderer#highlight()
endfunction
