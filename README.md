# 🌿 fern.vim

![Version 0.9.0](https://img.shields.io/badge/version-0.9.0-yellow.svg)
![Support Vim 8.1 or above](https://img.shields.io/badge/support-Vim%208.1%20or%20above-yellowgreen.svg)
![Support Neovim 0.4 or above](https://img.shields.io/badge/support-Neovim%200.4%20or%20above-yellowgreen.svg)
[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)
[![Powered by vital-Whisky](https://img.shields.io/badge/powered%20by-vital--Whisky-80273f.svg)](https://github.com/lambdalisue/vital-Whisky)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Doc](https://img.shields.io/badge/doc-%3Ah%20fern-orange.svg)](doc/fern.txt)
[![Doc (dev)](https://img.shields.io/badge/doc-%3Ah%20fern--develop-orange.svg)](doc/fern-develop.txt)

[![Actions Status](https://github.com/lambdalisue/fern.vim/workflows/reviewdog/badge.svg)](https://github.com/lambdalisue/fern.vim/actions)
[![Actions Status](https://github.com/lambdalisue/fern.vim/workflows/linux_vim/badge.svg)](https://github.com/lambdalisue/fern.vim/actions)
[![Actions Status](https://github.com/lambdalisue/fern.vim/workflows/linux_neovim/badge.svg)](https://github.com/lambdalisue/fern.vim/actions)
[![Actions Status](https://github.com/lambdalisue/fern.vim/workflows/windows_vim/badge.svg)](https://github.com/lambdalisue/fern.vim/actions)
[![Actions Status](https://github.com/lambdalisue/fern.vim/workflows/windows_neovim/badge.svg)](https://github.com/lambdalisue/fern.vim/actions)
[![Actions Status](https://github.com/lambdalisue/fern.vim/workflows/mac_neovim/badge.svg)](https://github.com/lambdalisue/fern.vim/actions)

General purpose asynchronous tree viewer written in Pure Vim script.

**WARNING: This project is in beta stage. Any changes are applied without announcements.**

![Split windows](https://user-images.githubusercontent.com/546312/73183241-d89aa980-415d-11ea-876f-30bd4d80f0cd.png)
_Split windows_

![Project drawer](https://user-images.githubusercontent.com/546312/73183310-f10ac400-415d-11ea-80c8-af1609294889.png)
_Project drawer_

## Concept

- Supports both Vim and Neovim without any external dependencies
- Support _split windows_ and _project drawer_ explained in [this article](http://vimcasts.org/blog/2013/01/oil-and-vinegar-split-windows-and-project-drawer/)
- Provide features as actions so that user don't have to remember mappings
- Make operation asynchronous as much as possible to keep latency
- User experience is more important than simplicity (maintainability)
- Custamizability is less important than simplicity (maintainability)
- Easy to create 3rd party plugins to support any kind of trees

## Installation

fern.vim has no extra dependencies so use your favorite Vim plugin manager or see [How to install](https://github.com/lambdalisue/fern.vim/wiki/How-to-install) page for detail.

## Usage

### Command (Split windows)

![Screencast of Split windows](https://user-images.githubusercontent.com/546312/73183457-29120700-415e-11ea-8d04-cb959659e369.gif)

Open fern on a current working directory by:

```vim
:Fern .
```

Or open fern on a parent directory of a current buffer by:

```vim
:Fern %:h
```

Or open fern on a current working directory with a current buffer focused by:

```vim
:Fern . -reveal=%
```

![](https://user-images.githubusercontent.com/546312/73183700-9aea5080-415e-11ea-8bca-e1dea78d24ca.png)

The following options are available for fern viewer.

| Option    | Default | Description                                                                                                                                                    |
| --------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-opener` | `edit`  | An opener to open the buffer. Available value is one of `select`, `edit`, `split`, `vsplit`, `tabedit`, or those values with modifiers (e.g. `topleft vsplit`) |
| `-reveal` |         | Recursively expand branches and focus the node. It must be a relative path from the root node of the tree. Otherwise the value is ignored.                     |

```
:Fern {url} [-opener={opener}] [-reveal={reveal}]
```

### Command (Project drawer)

![Screencast of Project drawer](https://user-images.githubusercontent.com/546312/73184080-324fa380-415f-11ea-8280-e0b6c7a9989f.gif)

All usage above open fern as [*split windows style*][]. To open fern as [*project drawer style*][], use `-drawer` option like:

```vim
:Fern . -drawer
```

A fern window with _project drawer_ style always appeared to the most left side of Vim and behaviors of some mappings/actions are slightly modified (e.g. a buffer in the next window will be used as an anchor buffer in a project drawer style to open a new buffer.)

Note that addtional to the all options available for _split windows_ style, _project drawer_ style enables the follwoing options:

| Option    | Default | Description                                                      |
| --------- | ------- | ---------------------------------------------------------------- |
| `-width`  | `30`    | The width of the project drawer window                           |
| `-keep`   |         | Disable to quit Vim when there is only one project drawer buffer |
| `-toggle` |         | Close existing project drawer rather than focus                  |

```
:Fern {url} -drawer [-opener={opener}] [-reveal={reveal}] [-width=30] [-keep] [-toggle]
```

[*split windows style*]: http://vimcasts.org/blog/2013/01/oil-and-vinegar-split-windows-and-project-drawer/
[*project drawer style*]: http://vimcasts.org/blog/2013/01/oil-and-vinegar-split-windows-and-project-drawer/

### Actions

To execute actions, hit `a` on a fern buffer and input an action to perform.
To see all actions available, hit `?` or execute `help` action then all available actions will be listed.

![Actions](https://user-images.githubusercontent.com/546312/73184453-c91c6000-415f-11ea-8e6b-f1df4b9284de.gif)

### Mappings

The following mappings/actions are available among any fern buffer

| Mapping             | Action                 | Description                                                                           |
| ------------------- | ---------------------- | ------------------------------------------------------------------------------------- |
| `a`                 |                        | Open a prompt to input an action name to perform                                      |
| `.`                 |                        | Repeat previous action invoked from a prompt                                          |
| `?`                 | `help`                 | Output mappings/actions to a pseudo buffer as help                                    |
| `<C-c>`             | `cancel`               | Cancel any operation under processing                                                 |
| `<C-l>`             | `redraw`               | Redraw content of the buffer                                                          |
|                     | `debug`                | Show a debug information of a node under the cursor                                   |
| `<F5>`              | `reload`               | Reload node itself and descendent nodes of a node under the cursor                    |
|                     | `expand`               | Expand (open) a node under the cursor                                                 |
| `-`                 | `mark-toggle`          | (Un)select a node                                                                     |
| `h`                 | `collapse`             | Collapse (close) a node under the cursor                                              |
| `i`                 | `reveal`               | Reveal (recursively focus and expand) a node which input by user                      |
|                     | `enter`                | Enter a new tree which root node is a node under the cursor                           |
| `<BS>`, `<C-h>`     | `leave`                | Leave to a new tree which root is the parent node of a current root node              |
| `s`                 | `open:select`          | Select window to open a node under the cursor (like [t9md/vim-choosewin][])           |
| `e`                 | `open`                 | An alias of `open:edit` action                                                        |
| `E`                 | `open:side`            | Open a node under the cursor on right side of the fern buffer                         |
|                     | `open:edit`            | An alias of `open:edit-or-error` action                                               |
|                     | `open:split`           | Open a node under the cursor with `split`                                             |
|                     | `open:vsplit`          | Open a node under the cursor with `vsplit`                                            |
| `t`                 | `open:tabedit`         | Open a node under the cursor with `tabedit`                                           |
|                     | `open:above`           | Open a node under the cursor with `leftabove split`                                   |
|                     | `open:left`            | Open a node under the cursor with `leftabove vsplit`                                  |
|                     | `open:below`           | Open a node under the cursor with `rightbelow split`                                  |
|                     | `open:right`           | Open a node under the cursor with `rightbelow vsplit`                                 |
|                     | `open:top`             | Open a node under the cursor with `topleft split`                                     |
|                     | `open:leftest`         | Open a node under the cursor with `topleft vsplit`                                    |
|                     | `open:bottom`          | Open a node under the cursor with `botright split`                                    |
|                     | `open:rightest`        | Open a node under the cursor with `botright vsplit`                                   |
|                     | `open:edit-or-error`   | Open a node under the cursor with `edit` or throw error when the buffer is `modified` |
|                     | `open:edit-or-split`   | Open a node under the cursor with `edit` or `split` when the buffer is `modified`     |
|                     | `open:edit-or-vsplit`  | Open a node under the cursor with `edit` or `vsplit` when the buffer is `modified`    |
|                     | `open:edit-or-tabedit` | Open a node under the cursor with `edit` or `tabedit` when the buffer is `modified`   |
| `<Return>`, `<C-m>` |                        | Invoke `open` when a node under the cursor is leaf. Otherwise invoke `enter`          |
| `l`                 |                        | Invoke `open` when a node under the cursor is leaf. Otherwise invoke `expand`         |
| `z`                 | `zoom`                 | An alias of `zoom:half` action                                                        |
|                     | `zoom:half`            | Temporary increase the width of a project drawer. It does nothing on split windows    |
|                     | `zoom:full`            | Temporary increase the width of a project drawer. It does nothing on split windows    |

And the following mappings/actions are available in builtin `file` scheme

| Mapping | Action            | Description                                                                                                       |
| ------- | ----------------- | ----------------------------------------------------------------------------------------------------------------- |
|         | `cd`              | Chnage directory to the root node of the tree with `cd` command                                                   |
|         | `lcd`             | Chnage directory to the root node of the tree with `lcd` command                                                  |
|         | `tcd`             | Chnage directory to the root node of the tree with `tcd` command                                                  |
| `x`     | `open:system`     | Open a node under the cursor with a system program                                                                |
| `N`     | `new-file`        | Create a new file under a node under the cursor                                                                   |
| `K`     | `new-dir`         | Create a new directory under a node under the cursor                                                              |
| `c`     | `copy`            | Copy files/directories of selected nodes to new locations sequentially                                            |
| `m`     | `move`            | Move files/directories of selected nodes to new locations sequentially                                            |
| `C`     | `clipboard-copy`  | Save files/directories of selected nodes to the internal clipboard to copy                                        |
| `M`     | `clipboard-move`  | Save files/directories of selected nodes to the internal clipboard to move                                        |
| `P`     | `clipboard-pate`  | Paste files/directories to a node under the cursor from the internal clipboard                                    |
|         | `clipboard-clear` | Clear the internal clipboard                                                                                      |
| `D`     | `trash`           | Move files/directries of selected nodes to the system trash-bin                                                   |
|         | `remove`          | Remove files/directries of selected nodes                                                                         |
| `R`     | `rename`          | Start renamer to rename multiple files/directories by using Vim buffer (like exrename in [Shougo/vimfiler.vim][]) |

### Window selector

The `open:select` action open a prompt to visually select window to open a node.
This feature is strongly inspired by [t9md/vim-choosewin][].

![Window selector](https://user-images.githubusercontent.com/546312/73605707-090e9780-45e5-11ea-864a-457dd785f1c4.gif)

[t9md/vim-choosewin]: https://github.com/t9md/vim-choosewin

### Renamer action (A.k.a exrename)

The `rename` action open a new buffer with path of selected nodes.
Users can edit that buffer and `:w` applies the changes.
This feature is strongly inspired by [shougo/vimfiler.vim][].

![Renamer](https://user-images.githubusercontent.com/546312/73184814-5d86c280-4160-11ea-9ed1-d5a8d66d1774.gif)

[shougo/vimfiler.vim]: https://github.com/Shougo/vimfiler.vim

## Customize

Use `FileType fern` autocmd to execute initialization scripts for fern buffer like:

```vim
function! s:init_fern() abort
  " Use 'select' instead of 'edit' for default 'open' action
  nmap <buffer> <Plug>(fern-action-open) <Plug>(fern-action-open:select)
endfunction

augroup fern-custom
  autocmd! *
  autocmd FileType fern call s:init_fern()
augroup END
```

The `FileType` autocmd will be invoked AFTER a fern buffer has initialized but BEFORE contents of a buffer become ready.
So avoid accessing actual contents in the above function.

See [Wiki](https://github.com/lambdalisue/fern.vim/wiki) pages to find tips, or write pages to share your tips ;-)

# Plugins

The fern.vim supports 3rd party plugin system for scheme and mappings.
See [Wiki](https://github.com/lambdalisue/fern.vim/wiki) pages to find 3rd party plugins of fern.vim.

# Contribution

Any contribution including documentations are welcome.

Contributors who change codes should install [thinca/vim-themis][] to run tests before complete a PR.
PRs which does not pass tests won't be accepted.

[thinca/vim-themis]: https://github.com/thinca/vim-themis

# License

The code in fern.vim follows MIT license texted in [LICENSE](./LICENSE).
Contributors need to agree that any modifications sent in this repository follow the license.
