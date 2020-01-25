let s:Promise = vital#trea#import('Async.Promise')

function! trea#internal#viewer#open(bufname, ...) abort
  let base = a:0 ? a:1 : 'trea:file:///'
  let url = trea#lib#url#parse(base)
  let url.path = a:bufname
  let url.query = filter(url.query, { -> index(['reveal'], v:key) is# -1 })
  execute printf('edit %s', fnameescape(url.to_string()))
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
  let bufname = bufname('%')
  if bufname !~# '#[a-f0-9]\+$'
    let bufname = printf("%s#%s", bufname, sha256(localtime())[:7])
    execute printf("keepalt file %s", fnameescape(bufname))
  endif

  let bufnr = bufnr('%')
  let url = trea#lib#url#parse(bufname)
  let query = url.query is# v:null ? {} : url.query
  let scheme = trea#lib#url#parse(url.path).scheme
  let provider = trea#scheme#{scheme}#provider#new()
  let b:trea = trea#internal#core#new(url.path, provider)

  call trea#internal#action#init()
  call trea#internal#spinner#start()
  call trea#internal#renderer#highlight()
  call trea#internal#renderer#syntax()

  let helper = trea#helper#new()
  let root = helper.get_root_node()
  let reveal = split(get(query, 'reveal', ''), '/')
  return s:Promise.resolve()
        \.then({ -> helper.expand_node(root.__key) })
        \.then({ -> helper.reveal_node(reveal) })
        \.then({ -> helper.redraw() })
        \.then({ -> helper.focus_node(reveal) })
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
