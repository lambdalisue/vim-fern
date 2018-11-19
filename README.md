# fila.vim
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg?style=flat-square)](https://github.com/vim-jp/vital.vim)

Asynchronous file explorer written in Pure Vim script.

**WARNING: This project is in alpha stage. Anything will be drastically changed without anouncements**

## feature

- Generic tree explorer
    - [x] Local file system
    - [ ] Git commit
    - [ ] SSH
    - [ ] Zip
- Split window & Project drawer
    - `:Fila {url}` to open a fila window in the current window (Split window style)
    - `:FilaDrawer {url}` to open a fila window in the drawer window (Project drawer style)
    - [What is split window and project drawer?](http://vimcasts.org/blog/2013/01/oil-and-vinegar-split-windows-and-project-drawer/)
- Asynchronous local file operations
    - [x] Perform `cd`, `lcd`, and `tcd` to the directory
    - [x] Create new file/directory
    - [x] Open file/directory with system application
    - [x] Copy file/directory into the internal clipboard (not system clipboard)
    - [x] Paste file/directory from the internal clipboard (not system clipboard)
    - [x] Move file/directory
    - [x] Trash file/directory (send to the system trash-bin)
    - [x] Remove file/directory
    - [ ] Rename file/directory (exrename in [Shougo/vimfiler.vim](https://github.com/Shougo/vimfiler.vim))
    - [ ] Filter file/directory
- System Trash-bin supports
    - [x] Support via [andreafrancia/trash-cli](https://github.com/andreafrancia/trash-cli)
    - [x] Support via [b4b4r07/gomi](https://github.com/b4b4r07/gomi)
    - [x] Native support via `osascript` in macOS
    - [x] Native support via `powershell` in Windows
- Action based feature
    - [ ] Hit `?` to show helps
    - [x] Hit `a` to choose action to perform
    - [x] Hit `.` to repeat previous action
    - [x] Use `<Plug>(fila-action-xxxxx)` to define mappings

## Default mappings

| Key | Description |
| --- | --- |
| `a` | Choose an action to perform |
| `.` | Repeat previous action |
| `<Backspace>` | Leave the root node |
| `<C-h>` | Leave the root node |
| `<Enter>` | Enter in the current node |
| `<C-m>` | Enter in the current node |
| `<F5>` | Reload the current node and descendants |
| `l` | Expand or open the current node |
| `h` | Collapse the current node |
| `-` | Toggle mark the current node |
| `!` | Toggle hidden flag |
| `e` | Open the current node |
| `t` | Open the current node (tab) |
| `E` | Open the current node (side) |

## Screenshot

### Split window style
```
:Fila {url}
```

![Split window style](https://user-images.githubusercontent.com/546312/48725703-4e5cd880-ec70-11e8-9376-3d25c1a4fc0b.png)

### Project drawer style
```
:FilaDrawer {url}
```

![Project drawer style](https://user-images.githubusercontent.com/546312/48725677-40a75300-ec70-11e8-9577-23cd841ca137.png)

## Inspired by

- [Shougo/vimfiler.vim](https://github.com/Shougo/vimfiler.vim)
- [thinca/vim-qfreplace](https://github.com/thinca/vim-qfreplace)
- [lambdalisue/gina.vim](https://github.com/lambdalisue/gina.vim)

# License
The code in fila.vim follows MIT license texted in [LICENSE](./LICENSE).
Contributors need to agree that any modifications sent in this repository follow the license.
