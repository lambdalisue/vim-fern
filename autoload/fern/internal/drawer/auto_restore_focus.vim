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
        \ 'nwin': winnr('$'),
        \ 'tabpage': tabpagenr(),
        \ 'prev': win_getid(winnr('#')),
        \}
  call timer_start(0, { -> extend(s:, {'info': v:null}) })
endfunction

function! s:auto_restore_focus() abort
  if s:info is# v:null
    return
  endif
  if s:info.tabpage is# tabpagenr() && s:info.nwin > winnr('$')
    call win_gotoid(s:info.prev)
  endif
  let s:info = v:null
endfunction

augroup fern_internal_drawer_auto_restore_focus
  autocmd!
  autocmd WinEnter * nested call s:auto_restore_focus()
augroup END
