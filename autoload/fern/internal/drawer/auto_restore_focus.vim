let s:info = v:null

function! fern#internal#drawer#auto_restore_focus#init() abort
  if g:fern#disable_drawer_auto_restore_focus
    return
  endif

  augroup fern_internal_drawer_auto_restore_focus_init
    autocmd! * <buffer>
    autocmd WinLeave <buffer> call s:auto_restore_focus_pre()
  augroup END
endfunction

function! s:auto_restore_focus_pre() abort
  let s:info = {
        \ 'nwin': s:nwin(),
        \ 'tabpage': tabpagenr(),
        \ 'prev': win_getid(winnr('#')),
        \}
  call timer_start(0, { -> extend(s:, {'info': v:null}) })
endfunction

function! s:auto_restore_focus() abort
  if s:info is# v:null
    return
  endif
  if s:info.tabpage is# tabpagenr() && s:info.nwin > s:nwin()
    call win_gotoid(s:info.prev)
  endif
  let s:info = v:null
endfunction

if exists('*nvim_win_get_config')
  " NOTE:
  " Remove Neovim flating window from the total count
  function! s:nwin() abort
    return len(filter(
          \ range(1, winnr('$')),
          \ { _, v -> nvim_win_get_config(win_getid(v)).relative ==# '' },
          \))
  endfunction
else
  function! s:nwin() abort
    return winnr('$')
  endfunction
endif

augroup fern_internal_drawer_auto_restore_focus
  autocmd!
  autocmd WinEnter * nested call s:auto_restore_focus()
augroup END
