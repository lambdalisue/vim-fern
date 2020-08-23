let s:WindowLocator = vital#fern#import('App.WindowLocator')

function! fern#internal#locator#list(...) abort
  return call(s:WindowLocator.list, a:000, s:WindowLocator)
endfunction

function! fern#internal#locator#focus(...) abort
  return call(s:WindowLocator.focus, a:000, s:WindowLocator)
endfunction

function! fern#internal#locator#get_condition(...) abort
  return call(s:WindowLocator.get_condition, a:000, s:WindowLocator)
endfunction

function! fern#internal#locator#set_condition(...) abort
  return call(s:WindowLocator.set_condition, a:000, s:WindowLocator)
endfunction

function! fern#internal#locator#get_threshold(...) abort
  return call(s:WindowLocator.get_threshold, a:000, s:WindowLocator)
endfunction

function! fern#internal#locator#set_threshold(...) abort
  return call(s:WindowLocator.set_threshold, a:000, s:WindowLocator)
endfunction
