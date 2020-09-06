let s:Config = vital#fern#import('Config')

call s:Config.config(expand('<sfile>:p'), {
      \ 'show_absolute_path_on_root_label': 0,
      \})
