let s:Dict = vital#fila#import('Data.Dict')
let s:Promise = vital#fila#import('Async.Promise')
let s:Lambda = vital#fila#import('Lambda')
let s:Scenario = vital#fila#import('App.Scenario')
let s:Revelator = vital#fila#import('App.Revelator')

let s:STATUS_NONE      = g:fila#tree#item#STATUS_NONE
let s:STATUS_COLLAPSED = g:fila#tree#item#STATUS_COLLAPSED
let s:STATUS_EXPANDED  = g:fila#tree#item#STATUS_EXPANDED

function! fila#ui#action#call(...) abort
  let scenario = s:Scenario.get()
  let result = call(scenario.call, a:000, scenario)
  retur s:Promise.is_promise(result) ? result : s:Promise.resolve(result)
endfunction

function! fila#ui#action#define(...) abort
  return call(s:Scenario.define, a:000, s:Scenario)
endfunction

function! fila#ui#action#actions() abort
  if exists('s:actions') && 0
    return s:actions
  endif
  let s:actions = [
        \ fila#ui#action#define('echo', funcref('s:echo'), {
        \   'visibility': 0,
        \   'mapping_mode': 'nv',
        \ }),
        \ fila#ui#action#define('reload', funcref('s:reload'), {
        \   'visibility': 0,
        \ }),
        \ fila#ui#action#define('expand', funcref('s:expand'), {
        \   'visibility': 0,
        \ }),
        \ fila#ui#action#define('collapse', funcref('s:collapse'), {
        \   'visibility': 0,
        \ }),
        \ fila#ui#action#define('mark:set', funcref('s:mark_set'), {
        \   'mapping_mode': 'nv',
        \ }),
        \ fila#ui#action#define('mark:unset', funcref('s:mark_unset'), {
        \   'mapping_mode': 'nv',
        \ }),
        \ fila#ui#action#define('mark:toggle', funcref('s:mark_toggle'), {
        \   'mapping_mode': 'nv',
        \ }),
        \ fila#ui#action#define('mark:clear', funcref('s:mark_clear')),
        \ fila#ui#action#define('mark', 'mark:toggle', {
        \   'mapping_mode': 'nv',
        \ }),
        \ fila#ui#action#define('hidden:set', funcref('s:hidden_set')),
        \ fila#ui#action#define('hidden:unset', funcref('s:hidden_unset')),
        \ fila#ui#action#define('hidden:toggle', funcref('s:hidden_toggle')),
        \ fila#ui#action#define('hidden', 'hidden:toggle'),
        \ fila#ui#action#define('edit', funcref('s:edit')),
        \ fila#ui#action#define('edit:select', 'edit select'),
        \ fila#ui#action#define('edit:split', 'edit split'),
        \ fila#ui#action#define('edit:vsplit', 'edit vsplit'),
        \ fila#ui#action#define('edit:tabedit', 'edit tabedit'),
        \ fila#ui#action#define('edit:pedit', 'edit pedit'),
        \ fila#ui#action#define('edit:above', 'edit leftabove split'),
        \ fila#ui#action#define('edit:left', 'edit leftabove vsplit'),
        \ fila#ui#action#define('edit:below', 'edit rightbelow split'),
        \ fila#ui#action#define('edit:right', 'edit rightbelow vsplit'),
        \ fila#ui#action#define('edit:top', 'edit topleft split'),
        \ fila#ui#action#define('edit:leftest', 'edit topleft vsplit'),
        \ fila#ui#action#define('edit:bottom', 'edit botright split'),
        \ fila#ui#action#define('edit:rightest', 'edit botright vsplit'),
        \]
  return s:actions
endfunction

function! s:echo(range, params) abort
  let helper = fila#ui#helper#get()
  let items = helper.get_marked_items()
  if empty(items)
    let items = helper.get_selection_items(a:range)
  endif
  for item in items
    echo printf('resource_uri : %s', item.resource_uri)
    echo printf('label        : %s', item.label)
    echo printf('status       : %s', item.status)
    echo printf('hidden       : %s', item.hidden)
    echo printf('remains      : %s', s:Dict.omit(copy(item), [
          \ 'resource_uri', 'label', 'status', 'hidden',
          \]))
  endfor
endfunction

function! s:edit(range, params) abort
  let helper = fila#ui#helper#get()
  let item = helper.get_cursor_item(a:range)
  let bufname = get(item, 'bufname', v:null)
  if bufname is# v:null
    throw s:Revelator.info('the item does not have bufname')
  endif
  return fila#buffer#open(bufname, {
        \ 'opener': empty(a:params) ? 'edit' : a:params,
        \})
        \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:reload(range, params) abort
  let helper = fila#ui#helper#get()
  let item = helper.get_cursor_item(a:range)
  return helper.reload(item.resource_uri)
       \.then({ h -> h.redraw() })
       \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:expand(range, params) abort
  let helper = fila#ui#helper#get()
  let item = helper.get_cursor_item(a:range)
  if item.status isnot# s:STATUS_COLLAPSED
    return fila#ui#action#call('reload')
  endif
  return helper.expand(item.resource_uri)
       \.then({ h -> h.redraw() })
       \.then({ h -> h.cursor(item.resource_uri, 1, 1) })
       \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:collapse(range, params) abort
  let helper = fila#ui#helper#get()
  let item = helper.get_cursor_item(a:range)
  if item.status isnot# s:STATUS_EXPANDED
    let item = helper.guess_parent(item.resource_uri, 1)
    if item is# v:null
      return
    endif
  endif
  return helper.collapse(item.resource_uri)
       \.then({ h -> h.redraw() })
       \.then({ h -> h.cursor(item.resource_uri, 0, 1) })
       \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:mark_set(range, params) abort
  let helper = fila#ui#helper#get()
  let items = helper.get_selection_items(a:range)
  let marks = helper.get_marks()
  for item in items
    call add(marks, item.resource_uri)
  endfor
  call helper.set_marks(uniq(marks))
  return helper.redraw()
       \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:mark_unset(range, params) abort
  let helper = fila#ui#helper#get()
  let items = helper.get_selection_items(a:range)
  let marks = helper.get_marks()
  for item in items
    let index = index(marks, item.resource_uri)
    if index isnot# -1
      call remove(marks, index)
    endif
  endfor
  call helper.set_marks(uniq(marks))
  return helper.redraw()
       \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:mark_toggle(range, params) abort
  let helper = fila#ui#helper#get()
  let items = helper.get_selection_items(a:range)
  let marks = helper.get_marks()
  for item in items
    let index = index(marks, item.resource_uri)
    if index isnot# -1
      call remove(marks, index)
    else
      call add(marks, item.resource_uri)
    endif
  endfor
  call helper.set_marks(uniq(marks))
  return helper.redraw()
       \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:mark_clear(range, params) abort
  let helper = fila#ui#helper#get()
  call helper.set_marks([])
  return helper.redraw()
       \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:hidden_set(range, params) abort
  let helper = fila#ui#helper#get()
  let item = helper.get_cursor_item(a:range)
  call helper.set_hidden(1)
  return helper.redraw()
       \.then({ h -> h.cursor(item.resource_uri, 0, 1) })
       \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:hidden_unset(range, params) abort
  let helper = fila#ui#helper#get()
  let item = helper.get_cursor_item(a:range)
  call cursor(1, 1)
  call helper.set_hidden(0)
  return helper.redraw()
       \.then({ h -> h.cursor(item.resource_uri, 0, 1) })
       \.catch({ e -> fila#error#handle(e) })
endfunction

function! s:hidden_toggle(range, params) abort
  let helper = fila#ui#helper#get()
  let item = helper.get_cursor_item(a:range)
  if helper.get_hidden()
    call cursor(1, 1)
  endif
  call helper.set_hidden(!helper.get_hidden())
  return helper.redraw()
       \.then({ h -> h.cursor(item.resource_uri, 0, 1) })
       \.catch({ e -> fila#error#handle(e) })
endfunction
