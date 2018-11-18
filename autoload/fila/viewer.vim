function! fila#viewer#open(bufname, options) abort
  call fila#buffer#open(a:bufname, a:options)
        \.catch({ e -> fila#helper#handle_error(e) })
endfunction

function! fila#viewer#BufReadCmd(factory)
  let bufnr = str2nr(expand('<abuf>'))
  let helper = fila#helper#new(bufnr)

  if !exists('b:fila_ready') || v:cmdbang
    let b:fila_ready = 1
    setlocal buftype=nofile
    setlocal noswapfile nobuflisted nomodifiable readonly

    augroup fila_viewer_internal
      autocmd! * <buffer>
      autocmd BufEnter <buffer> setlocal nobuflisted
    augroup END

    call fila#action#_init()
    call fila#action#_define()

    let winid = win_getid()
    let root = a:factory()
    call helper.set_nodes([root])
    call helper.expand_node(root)
          \.then({ h -> h.redraw() })
          \.then({ h -> h.cursor_node(winid, root, 1) })
          \.then({ h -> s:notify(h.bufnr) })
          \.catch({ e -> fila#helper#handle_error(e) })
  else
    let winid = win_getid()
    let root = helper.get_root_node()
    call helper.set_marks([])
    call helper.reload_node(root)
          \.then({ h -> h.redraw() })
          \.then({ h -> h.cursor_node(winid, root, 1) })
          \.then({ h -> s:notify(h.bufnr) })
          \.catch({ e -> fila#helper#handle_error(e) })
  endif
  setlocal filetype=fila
endfunction

function! s:notify(bufnr) abort
  let notifier = getbufvar(a:bufnr, 'fila_notifier', v:null)
  if notifier isnot# v:null
    call notifier.notify()
    call setbufvar(a:bufnr, 'fila_notifier', v:null)
  endif
endfunction
