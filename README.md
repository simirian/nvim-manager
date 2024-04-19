# NeoVim Manager

Project and workspace manager for NeoVim<br>

by simirian

## Features

### Workspaces

- [ ] automatically detect workspaces on entering NeoVim
    - [x] custom detection with detector functions
    - [ ] does not attempt detection when run with certain args
- [x] dynamically load lazy.nvim plugins with workspace events
- [ ] automatically setup keymaps, commands, and more in specific workspaces
    - [ ] enable keymaps and settings on entering a workspace
    - [ ] disable these settings when leaving the workspace

### Projects

- [x] memorize project directories and active workspaces
- [ ] pick from memorized projects with telescope
- [ ] new project templates with lua and scripts

## Usage

### Workspaces

### Projects

Access the projects API through lua with `require("nvim-manger.projects")`:

| lua | options | description |
| --- | --- | --- |
| `load_data` | none | Loads data from the configured file. |
| `load_project` | `name` | Loads the named project, if it exists. |
| `save_data` | none | Saves the currently loaded data to the configured file. |
| `add_project` | `name`, `opts` | Add a project configuration to the loaded data and save it. |
| `save_project` | none | Saves the current NeoVim instance as a project. |

