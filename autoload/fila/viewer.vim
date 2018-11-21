let s:Config = vital#fila#import('Config')

function! fila#viewer#open(bufname, options) abort
  call fila#buffer#open(a:bufname, a:options)
        \.catch({ e -> fila#error#handle(e) })
endfunction

function! fila#viewer#BufReadCmd(factory) abort
  doautocmd <nomodeline> BufReadPre

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

    if !g:fila#viewer#skip_default_mappings
      nmap <buffer><nowait> <Backspace> <Plug>(fila-action-leave)
      nmap <buffer><nowait> <C-h>       <Plug>(fila-action-leave)
      nmap <buffer><nowait> <Return>    <Plug>(fila-action-enter-or-open)
      nmap <buffer><nowait> <C-m>       <Plug>(fila-action-enter-or-open)
      nmap <buffer><nowait> <F5>        <Plug>(fila-action-reload)
      nmap <buffer><nowait> l           <Plug>(fila-action-expand-or-open)
      nmap <buffer><nowait> h           <Plug>(fila-action-collapse)
      nmap <buffer><nowait> -           <Plug>(fila-action-mark-toggle)
      vmap <buffer><nowait> -           <Plug>(fila-action-mark-toggle)
      nmap <buffer><nowait> !           <Plug>(fila-action-hidden-toggle)
      nmap <buffer><nowait> e           <Plug>(fila-action-open)
      nmap <buffer><nowait> t           <Plug>(fila-action-open-tabedit)
      nmap <buffer><nowait> E           <Plug>(fila-action-open-side)
    endif

    let winid = win_getid()
    let root = a:factory()
    call helper.init(root)
    call helper.expand_node(root)
          \.then({ h -> h.redraw() })
          \.then({ h -> h.cursor_node(winid, root, 1) })
          \.then({ h -> s:notify(h.bufnr) })
          \.catch({ e -> fila#error#handle(e) })

    doautocmd <nomodeline> User FilaViewerInit
  else
    let winid = win_getid()
    let root = helper.get_root_node()
    call helper.set_marks([])
    call helper.reload_node(root)
          \.then({ h -> h.redraw() })
          \.then({ h -> h.cursor_node(winid, root, 1) })
          \.then({ h -> s:notify(h.bufnr) })
          \.catch({ e -> fila#error#handle(e) })
  endif
  setlocal filetype=fila

  doautocmd <nomodeline> BufReadPost
endfunction

function! s:notify(bufnr) abort
  let notifier = getbufvar(a:bufnr, 'fila_notifier', v:null)
  if notifier isnot# v:null
    call notifier.notify()
    call setbufvar(a:bufnr, 'fila_notifier', v:null)
  endif
  doautocmd <nomodeline> User FilaViewerRead
endfunction

augroup fila_viewer_internal
  autocmd! *
  autocmd User FilaViewerInit :
  autocmd User FilaViewerRead :
  autocmd BufReadPre  fila://*   :
  autocmd BufReadPost fila://* :
augroup END

call s:Config.config(expand('<sfile>:p'), {
      \ 'skip_default_mappings': 0,
      \})
