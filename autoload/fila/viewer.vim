let s:Promise = vital#fila#import('Async.Promise')
let s:Lambda = vital#fila#import('Lambda')
let s:Config = vital#fila#import('Config')

function! fila#viewer#open(bufname, options) abort
  let options = extend({
        \ 'opener': g:fila#viewer#opener,
        \}, a:options)
  let options.notifier = 1
  return fila#lib#buffer#open(a:bufname, options)
        \.catch({ e -> fila#error#handle(e) })
endfunction

function! fila#viewer#BufReadCmd(factory) abort
  doautocmd <nomodeline> BufReadPre

  if !exists('b:fila_ready') || v:cmdbang
    let b:fila_ready = 1
    call s:init(a:factory)
  else
    call s:reload()
  endif

  setlocal filetype=fila
  doautocmd <nomodeline> BufReadPost
endfunction

function! s:init(factory) abort
  setlocal buftype=nofile bufhidden=unload
  setlocal noswapfile nobuflisted nomodifiable readonly

  augroup fila_viewer_internal
    autocmd! * <buffer>
    autocmd BufEnter <buffer> setlocal nobuflisted
  augroup END

  call fila#viewer#action#_init()
  call fila#viewer#action#_define()

  if !g:fila#viewer#skip_default_mappings
    nmap <buffer><nowait> <Backspace> <Plug>(fila-action-leave)
    nmap <buffer><nowait> <C-h>       <Plug>(fila-action-leave)
    nmap <buffer><nowait> <Return>    <Plug>(fila-action-enter-or-edit)
    nmap <buffer><nowait> <C-m>       <Plug>(fila-action-enter-or-edit)
    nmap <buffer><nowait> <F5>        <Plug>(fila-action-reload)
    nmap <buffer><nowait> l           <Plug>(fila-action-expand-or-edit)
    nmap <buffer><nowait> h           <Plug>(fila-action-collapse)
    nmap <buffer><nowait> -           <Plug>(fila-action-mark-toggle)
    vmap <buffer><nowait> -           <Plug>(fila-action-mark-toggle)
    nmap <buffer><nowait> !           <Plug>(fila-action-hidden-toggle)
    nmap <buffer><nowait> e           <Plug>(fila-action-edit)
    nmap <buffer><nowait> t           <Plug>(fila-action-edit-tabedit)
    nmap <buffer><nowait> E           <Plug>(fila-action-edit-side)
  endif

  let bufnr = bufnr('%')
  let winid = win_getid()
  let helper = fila#node#helper#new(bufnr)
  let factory = a:factory()
  let factory = s:Promise.is_promise(factory) ? factory : s:Promise.resolve(factory)
  call factory
        \.then({ root -> helper.init(root) })
        \.then({ h -> h.expand_node(h.get_root_node()) })
        \.then({ h -> h.redraw() })
        \.then({ h -> h.cursor_node(winid, h.get_root_node(), 1) })
        \.then({ h -> fila#lib#buffer#call(bufnr, funcref('s:FilaViewerRead'), []) })
        \.catch({ e -> fila#error#handle(e) })
  doautocmd <nomodeline> User FilaViewerInit
endfunction

function! s:reload() abort
  let bufnr = bufnr('%')
  let winid = win_getid()
  let helper = fila#node#helper#new(bufnr)
  let root = helper.get_root_node()
  call helper.set_marks([])
  call helper.reload_node(root)
        \.then({ h -> h.redraw() })
        \.then({ h -> h.cursor_node(winid, root, 1) })
        \.then({ h -> fila#lib#buffer#call(bufnr, funcref('s:FilaViewerRead'), []) })
        \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:FilaViewerRead() abort
  let notifier = get(b:, 'fila_notifier', v:null)
  if notifier isnot# v:null
    let b:fila_notifier = v:null
    call notifier.notify()
  endif
  doautocmd <nomodeline> User FilaViewerRead
endfunction

augroup fila_viewer_internal
  autocmd! *
  autocmd User FilaViewerInit :
  autocmd User FilaViewerRead :
  autocmd BufReadPre  fila://* :
  autocmd BufReadPost fila://* :
augroup END

call s:Config.config(expand('<sfile>:p'), {
      \ 'opener': 'edit',
      \ 'skip_default_mappings': 0,
      \})
