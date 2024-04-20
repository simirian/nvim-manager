# NeoVim Manager

Project and workspace manager for NeoVim<br>

by simirian

## Features

### Workspaces

- [ ] automatically detect workspaces on entering NeoVim
    - [x] custom detection with detector functions
    - [ ] does not attempt detection when run with certain args
- [x] dynamic wokspace action with callbacks
- [ ] automatically setup keymaps, commands, and more in specific workspaces
    - [ ] enable keymaps and settings on entering a workspace
    - [ ] disable these settings when leaving the workspace
    - [x] automatically configure language servers by workspace

### Projects

- [x] memorize project directories and active workspaces
- [ ] pick from memorized projects with telescope
- [ ] new project templates with lua and scripts
- [ ] automatically recognize project direcotries and load workspaces

### Misc todo

- [ ] vim helpfile
- [ ] configuration in README

## Usage

### Workspaces

Access the workspaces API in lua with `require("nvim-manager.workspaces")`:

| function | options | description |
| --- | --- | --- |
| `setup` | `opts`*?* | Loads workspace modules and sets up user config. |
| `load_workspaces` | none | Reloads workspace modules. |
| `list_workspaces` | none | Returns a list of configured workspaces. |
| `active_workspaces` | none | Returns a list of the active workspaces. |
| `activate` | `ws_name` | Name of the configured workspace to activate. |
| `enable` | `opts`*?* | Activate workspaces in bulk. Calling without args or with `"detect"` will use workspace detector functions to determine activation. `"all"` will activate all workspaces, and a table will activate all workspaces named in it. |

### Projects

Access the projects API through lua with `require("nvim-manger.projects")`:

| function | options | description |
| --- | --- | --- |
| `setup` | `opts`*?* | Loads project data and sets user configuration. |
| `load_data` | none | Reloads data from the configured file. |
| `load_project` | `name` | Loads the named project, if it exists. |
| `save_data` | none | Saves the currently loaded data to the configured file. |
| `add_project` | `name`, `opts` | Add a project configuration to the loaded data and save it. `opts` must have `path` set. |
| `save_project` | none | Saves the current NeoVim instance as a project. |

