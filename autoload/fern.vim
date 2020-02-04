let s:Config = vital#fern#import('Config')

" Define Public variables
call s:Config.config(expand('<sfile>:p'), {
      \ 'debug': 0,
      \ 'profile': 0,
      \ 'logfile': v:null,
      \ 'loglevel': g:fern#logger#INFO,
      \ 'opener': 'edit',
      \ 'disable_default_mappings': 0,
      \ 'default_hidden': 0,
      \ 'default_include': '',
      \ 'default_exclude': '',
      \ 'renderer': 'default',
      \ 'comparator': 'default',
      \ 'drawer_width': 30,
      \ 'drawer_keep': v:false,
      \})
