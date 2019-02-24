" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not mofidify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_fila#Async#Promise#Deferred#import() abort', printf("return map({'_vital_depends': '', 'new': '', '_vital_loaded': ''}, \"vital#_fila#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
function! s:_vital_loaded(V) abort
  let s:Promise = a:V.import('Async.Promise')
endfunction

function! s:_vital_depends() abort
  return ['Async.Promise']
endfunction

function! s:new() abort
  let ns = {'resolve': v:null, 'reject': v:null}
  let promise = s:Promise.new(
        \ { rv, rt -> extend(ns, {'resolve': rv, 'reject': rt}) }
        \)
  while ns.resolve is# v:null
    sleep 1m
  endwhile
  let promise.resolve = ns.resolve
  let promise.reject = ns.reject
  return promise
endfunction