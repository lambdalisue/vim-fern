if exists('g:loaded_fern')
  finish
endif
let g:loaded_fern = 1

function! s:warn(message) abort
  if get(g:, 'fern_disable_startup_warnings')
    return
  endif
  echohl ErrorMsg
  echo printf('[fern] %s', a:message)
  echo '[fern] Disable this warning message by adding "let g:fern_disable_startup_warnings = 1" on your vimrc.'
  echohl None
endfunction

if !has('nvim') && !has('patch-8.1.0994')
  " NOTE:
  " At least https://github.com/vim/vim/releases/tag/v8.1.0994 is required
  " thus minimum working version is 8.1.0994. Remember that minimum support
  " version is not equal to this.
  call s:warn('Vim prior to 8.1.0994 does not have required feature thus fern is disabled.')
  finish
elseif exists('+shellslash') && &shellslash
  call s:warn('"shellslash" option is not supported thus fern is disabled.')
  finish
elseif !has('nvim') && !has('patch-8.1.2269')
  call s:warn('Vim prior to 8.1.2269 is not supported and fern might not work properly.')
elseif has('nvim') && !has('nvim-0.4.4')
  call s:warn('Neovim prior to 0.4.4 is not supported and fern might not work properly.')
endif


command! -bar -nargs=*
      \ -complete=customlist,fern#internal#command#fern#complete
      \ Fern
      \ call fern#internal#command#fern#command(<q-mods>, [<f-args>])

command! -bar -nargs=*
      \ -complete=customlist,fern#internal#command#do#complete
      \ FernDo
      \ call fern#internal#command#do#command(<q-mods>, [<f-args>])

function! s:BufReadCmd() abort
  if exists('b:fern')
    return
  endif
  call fern#internal#viewer#init()
        \.catch({ e -> fern#logger#error(e) })
endfunction

function! s:SessionLoadPost() abort
  let bufnr = bufnr()
  call s:BufReadCmd()
  " Re-apply required window options
  for winid in win_findbuf(bufnr)
    let [tabnr, winnr] = win_id2tabwin(winid)
    call settabwinvar(tabnr, winnr, '&concealcursor', 'nvic')
    call settabwinvar(tabnr, winnr, '&conceallevel', 2)
  endfor
endfunction

augroup fern_internal
  autocmd! *
  autocmd BufReadCmd fern://* nested call s:BufReadCmd()
  autocmd SessionLoadPost fern://* nested call s:SessionLoadPost()
augroup END
