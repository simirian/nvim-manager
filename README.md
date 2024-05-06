# NeoVim Manager

Project and workspace manager for NeoVim<br>

by simirian

## Features

### Workspaces

- [x] automatically detect workspaces on entering NeoVim
    - [x] custom detection with detector functions
    - [x] enable workspaces by detectors on calling a lua function on startup
- [x] dynamic wokspace action with callbacks
- [ ] automatically setup keymaps, commands, and more in specific workspaces
    - [ ] enable keymaps and settings on entering a workspace
    - [ ] disable these settings when leaving the workspace
    - [x] automatically configure language servers by workspace

### Projects

- [x] memorize project directories and active workspaces
- [x] pick from memorized projects with telescope
- [ ] new project templates with lua and scripts
- [ ] automatically recognize project direcotries and load workspaces

### Misc todo

- [ ] vim helpfile
- [ ] configuration
    - [ ] guide in README
    - [ ] lots of options
- [x] vim command api
    - [x] projects commands
    - [x] workspaces commands

## Usage

### Workspaces

Access the workspaces API in lua with `require("nvim-manager.workspaces")`:

| function | vim command | options | description |
| --- | --- | --- | --- |
| `setup` | none | `opts`*?* | Loads workspace modules and sets up user config. |
| `list_configured` | `WorkspaceListConf` | none | Returns a list of configured workspaces. |
| `list_active` | `WorkspaceListActive` | none | Returns a list of the active workspaces. |
| `activate` | `WorkspaceActivate` | `ws_name` | Name of the configured workspace to activate. |
| `enable` | `WorkspaceEnable` | `"all"`\|`"detect"`\|none | Enables all workspaces, or enables workspaces based on their detector functions. |

### Projects

Access the projects API through lua with `require("nvim-manger.projects")`:

| function  | vim command | options | description |
| --- | --- | --- | --- |
| `setup` | none | `opts`*?* | Loads project data and sets user configuration. |
| `save` | `ProjectSave` | none | Saves the current NeoVim instance as a project. |
| `load` | `ProjectLoad` | `name` | Loads the named project, if it exists. |
| `remove` | `ProjectRemove` | `name` | Removes a project from the list of saved projects. |
| `list` | `ProjectList` | none | Returns (the command prints) a list of saved projects. |

## Configuration

### Telescope

This plugin provides an *nvim-telescope* extension.
See the example below for usage

```lua
local telescope = require("telescope")

-- load the extension with telescope
telescope.load_extension("nvim-manager")

-- then access the function with telescope.extensions["nvim-mangager"].projects
-- here we make <leader>fp (find project) open the picker
vim.keymap.set("n", "<leader>fp",
    telescope.extensions["nvim-manager"].projects, {})
```

