# 🌿 vim-fern

![Support Vim 8.2.5136 or above](https://img.shields.io/badge/support-Vim%208.2.5136%20or%20above-yellowgreen.svg)
![Support Neovim 0.4.4 or above](https://img.shields.io/badge/support-Neovim%200.4.4%20or%20above-yellowgreen.svg)
[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)
[![Powered by vital-Whisky](https://img.shields.io/badge/powered%20by-vital--Whisky-80273f.svg)](https://github.com/lambdalisue/vital-Whisky)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Doc](https://img.shields.io/badge/doc-%3Ah%20fern-orange.svg)](doc/fern.txt)
[![Doc (dev)](https://img.shields.io/badge/doc-%3Ah%20fern--develop-orange.svg)](doc/fern-develop.txt)
[![reviewdog](https://github.com/lambdalisue/vim-fern/actions/workflows/reviewdog.yml/badge.svg)](https://github.com/lambdalisue/vim-fern/actions/workflows/reviewdog.yml)
[![Vim](https://github.com/lambdalisue/vim-fern/actions/workflows/vim.yml/badge.svg)](https://github.com/lambdalisue/vim-fern/actions/workflows/vim.yml)
[![Neovim](https://github.com/lambdalisue/vim-fern/actions/workflows/neovim.yml/badge.svg)](https://github.com/lambdalisue/vim-fern/actions/workflows/neovim.yml)

<p align="center">
<strong>Split windows (netrw style)</strong><br>
<sup>
<a href="https://github.com/lambdalisue/nerdfont.vim" target="_blank">nerdfont.vim</a>
/
<a href="https://github.com/lambdalisue/glyph-palette.vim" target="_blank">glyph-palette.vim</a>
/
<a href="https://github.com/lambdalisue/fern-renderer-nerdfont.vim" target="_blank">fern-renderer-nerdfont.vim</a>
/
<a href="https://github.com/lambdalisue/fern-git-status.vim" target="_blank">fern-git-status.vim</a>
</sup>
<img src="https://user-images.githubusercontent.com/546312/90719223-cdbc8780-e2ee-11ea-8a6e-ea837a194ffa.png">
</p>
<p align="center">
<strong>Project drawer (NERDTree style)</strong><br>
<sup>
<a href="https://github.com/lambdalisue/nerdfont.vim" target="_blank">nerdfont.vim</a>
/
<a href="https://github.com/lambdalisue/glyph-palette.vim" target="_blank">glyph-palette.vim</a>
/
<a href="https://github.com/lambdalisue/fern-renderer-nerdfont.vim" target="_blank">fern-renderer-nerdfont.vim</a>
/
<a href="https://github.com/lambdalisue/fern-git-status.vim" target="_blank">fern-git-status.vim</a>
</sup>
<img src="https://user-images.githubusercontent.com/546312/90719227-ceedb480-e2ee-11ea-98c5-0b7cbcb1bb6a.png">
</p>
<p align="right">
<sup>
See <a href="https://github.com/lambdalisue/vim-fern/wiki/Screenshots" target="_blank">Screenshots</a> for more screenshots.
</sup>
</p>

Fern ([furn](https://www.youtube.com/watch?v=SSYgr-_69mg)) is a general purpose
asynchronous tree viewer written in pure Vim script.

---

<p align="center">
  <strong>🔍 <a href="https://github.com/topics/fern-vim-plugin">Click here to find fern plugins</a> 🔍</strong>
</p>

---

## Concept

- Supports both Vim and Neovim without any external dependencies
- Support _split windows_ and _project drawer_ explained in
  [this article](http://vimcasts.org/blog/2013/01/oil-and-vinegar-split-windows-and-project-drawer/)
- Provide features as actions so that user don't have to remember mappings
- Make operation asynchronous as much as possible to keep latency
- User experience is more important than simplicity (maintainability)
- Customizability is less important than simplicity (maintainability)
- Easy to create 3rd party plugins to support any kind of trees

## Installation

vim-fern has no extra dependencies so use your favorite Vim plugin manager or
see
[How to install](https://github.com/lambdalisue/vim-fern/wiki#how-to-install)
page for detail.

- If you use Neovim < 0.8, you **SHOULD** add
  [antoinemadec/FixCursorHold.nvim](https://github.com/antoinemadec/FixCursorHold.nvim)
  (See [#120](https://github.com/lambdalisue/vim-fern/issues/120))

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

![](https://user-images.githubusercontent.com/546312/90720134-f3e32700-e2f0-11ea-82f7-c86512ad5854.png)

The following options are available for fern viewer.

| Option    | Default | Description                                                                         |
| --------- | ------- | ----------------------------------------------------------------------------------- |
| `-opener` | `edit`  | An opener to open the buffer. See `:help fern-opener` for detail.                   |
| `-reveal` |         | Recursively expand branches and focus the node. See `:help fern-reveal` for detail. |
| `-stay`   |         | Stay focus on the window where the command has called.                              |
| `-wait`   |         | Wait synchronously until the fern viewer become ready.                              |

```
:Fern {url} [-opener={opener}] [-reveal={reveal}] [-stay] [-wait]
```

### Command (Project drawer)

![Screencast of Project drawer](https://user-images.githubusercontent.com/546312/73184080-324fa380-415f-11ea-8280-e0b6c7a9989f.gif)

All usage above open fern as [_split windows style_][*split windows style*]. To
open fern as [_project drawer style_][*project drawer style*], use `-drawer`
option like:

```vim
:Fern . -drawer
```

A fern window with _project drawer_ style always appeared to the most left side
of Vim and behaviors of some mappings/actions are slightly modified (e.g. a
buffer in the next window will be used as an anchor buffer in a project drawer
style to open a new buffer.)

Note that additional to the all options available for _split windows_ style,
_project drawer_ style enables the following options:

| Option    | Default | Description                                                      |
| --------- | ------- | ---------------------------------------------------------------- |
| `-width`  | `30`    | The width of the project drawer window                           |
| `-keep`   |         | Disable to quit Vim when there is only one project drawer buffer |
| `-toggle` |         | Close existing project drawer rather than focus                  |

```
:Fern {url} -drawer [-opener={opener}] [-reveal={reveal}] [-stay] [-wait] [-width=30] [-keep] [-toggle]
```

[*split windows style*]: http://vimcasts.org/blog/2013/01/oil-and-vinegar-split-windows-and-project-drawer/
[*project drawer style*]: http://vimcasts.org/blog/2013/01/oil-and-vinegar-split-windows-and-project-drawer/

### Actions

To execute actions, hit `a` on a fern buffer and input an action to perform. To
see all actions available, hit `?` or execute `help` action then all available
actions will be listed.

![Actions](https://user-images.githubusercontent.com/546312/73184453-c91c6000-415f-11ea-8e6b-f1df4b9284de.gif)

### Window selector

The `open:select` action open a prompt to visually select window to open a node.
This feature is strongly inspired by [t9md/vim-choosewin][t9md/vim-choosewin].

![Window selector](https://user-images.githubusercontent.com/546312/73605707-090e9780-45e5-11ea-864a-457dd785f1c4.gif)

[t9md/vim-choosewin]: https://github.com/t9md/vim-choosewin

### Renamer action (A.k.a exrename)

The `rename` action open a new buffer with path of selected nodes. Users can
edit that buffer and `:w` applies the changes. This feature is strongly inspired
by [shougo/vimfiler.vim][shougo/vimfiler.vim].

![Renamer](https://user-images.githubusercontent.com/546312/73184814-5d86c280-4160-11ea-9ed1-d5a8d66d1774.gif)

[shougo/vimfiler.vim]: https://github.com/Shougo/vimfiler.vim

# Plugins

## Users

Most of functionalities are provided as plugins in fern. So visit
[Github topics of `fern-vim-plugin`](https://github.com/topics/fern-vim-plugin)
or [Plugins](https://github.com/lambdalisue/vim-fern/wiki/Plugins) page to find
fern plugins to satisfy your wants.

For example, following features are provided as official plugins

- Netrw hijack (Use fern as a default file explorer)
- [Nerd Fonts](https://www.nerdfonts.com/) integration
- Git integration (show status, touch index, ...)
- Bookmark feature

And lot more!

## Developers

Please add `fern-vim-plugin` topic to your fern plugin. The topic is used to
list up 3rd party fern plugins.
![](https://user-images.githubusercontent.com/546312/94343538-d160ce00-0053-11eb-9ec6-0dd2a4c3f4b0.png)

Then please add a following badge to indicate that your plugin is for fern.

```
[![fern plugin](https://img.shields.io/badge/🌿%20fern-plugin-yellowgreen)](https://github.com/lambdalisue/vim-fern)
```

## Customize

Use `FileType fern` autocmd to execute initialization scripts for fern buffer
like:

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

The `FileType` autocmd will be invoked AFTER a fern buffer has initialized but
BEFORE contents of a buffer become ready. So avoid accessing actual contents in
the above function.

See [Tips](https://github.com/lambdalisue/vim-fern/wiki/Tips) pages to find
tips, or write pages to share your tips ;-)

# Contribution

Any contribution including documentations are welcome.

Contributors who change codes should install
[thinca/vim-themis][thinca/vim-themis] to run tests before complete a PR. PRs
which does not pass tests won't be accepted.

[thinca/vim-themis]: https://github.com/thinca/vim-themis

# License

The code in vim-fern follows MIT license texted in [LICENSE](./LICENSE).
Contributors need to agree that any modifications sent in this repository follow
the license.
