let s:Action = vital#fern#import('App.Action')

function! fern#action#_init() abort
  call s:Action.init()
endfunction

function! fern#action#call(...) abort
  call call(s:Action.call, a:000, s:Action)
endfunction

function! fern#action#list(...) abort
  return call(s:Action.list, a:000, s:Action)
endfunction
