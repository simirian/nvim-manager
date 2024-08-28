# NeoVim Manager

Project and workspace manager for NeoVim<br>
by simirian

## Features

Nvim Manager is meant for power-users, and is designed to work best if you *read
documentation*. This plugin is also designed for customizability, and the entire
workspaces feature will not work out of the box.

### Workspaces

- [ ] automatically detect workspaces on entering NeoVim
    - [x] custom detection with detector functions
    - [x] enable workspaces by detectors on calling a lua function
    - [ ] autodetect workspaces on startup
- [x] dynamic wokspace action with callbacks
- [ ] enable features on workspace activation, disable on deactivation
    - [x] keymaps
    - [ ] commands
- [x] automatically setup language servers by workspace
- [ ] workspaces can imply other workspaces to automatically load each other

### Projects

- [x] memorize project directories and active workspaces
    - [x] seamlessly switch workspaces when switching projects
- [x] pick from memorized projects with telescope
- [ ] new project templates with lua and scripts
- [x] automatically recognize project direcotries and load workspaces
- [x] cd to first opened file on command line (`nvim ~/source/project/`)

### Misc todo

- [ ] vim helpfile
- [ ] configuration
    - [x] guide in README
- [x] vim command api

## Usage

All functions are well-documented and should work with autocompletion. There are
also vim commands for every function listed below. If in doubt, read the source
code, it's easy to find and every function and type is annotated.

### Workspaces

Access the workspaces API in lua with `require("nvim-manager.workspaces")`:

| memeber        | usage                                              |
| -------------- | -------------------------------------------------- |
| `activate()`   | Activates the given workspace.                     |
| `deactivate()` | Deactivates the given workspace.                   |
| `enable()`     | Enables multiple workspaces based on the argument. |
| `disable()`    | Disables all workspaces.                           |
| `list()`       | Lists configured workspaces.                       |

### Projects

Access the projects API through lua with `require("nvim-manger.projects")`:

| member      | usage                                              |
| ----------- | -------------------------------------------------- |
| `load()`    | Load a saved project.                              |
| `save()`    | Saves the current nvim instance as a project.      |
| `new()` WIP | Creates a new project based on a procedure.        |
| `remove()`  | Removes a project from the list of saved projects. |
| `list()`    | Lists the saved projects.                          |

## Configuration

The default configuration can be found in `nvim-manager.config`. This accepts a
table with all of the nvim-manager settings. The defaults are as follows:

```lua
local default_config = {
  project_path = vim.fn.stdpath("data")
      .. (vim.fn.has("macunix") and "/" or "\\") .. "projects.json",
  arg_cd = true,
  autodetect = "within",
  auto_enable = "none",
  workspaces = nil,
}
```

### Workspaces

Setting up nvim manager with an array-table of workspaces specs as the
`workspaces` key will load those workspace specs. Workspaces define complex and
specialized functionality that you might not want for everyday nvim usage. They
can be activated with commands or lua functions and can define keymaps,
commands, and even lua callback functions for activations and deactivation.

Spec stub:

```lua
local workspace = {
  detector = function() return false end,
  activate = function() end,
  deactivate = function() end,
  filetypes = { "cpp" },

  lsp = {
    ["name"] = {
      cmd = { "language-server-command" }, -- MANDATORY
      filetypes = { "attach to filetypes" }, -- MANDATORY
      on_attach = function() end
      -- see :h vim.lsp.ClientConfig for other keys
    },
  },
  maps = {
    {
      -- see :h vim.keymap.set()
      "f5", -- left hand side
      ":!make<cr>", -- right hand side
      mode = "n", -- optional, defaults to "n"
      -- any other keys that go to vim.keymap.set() opts
      -- desc = "",
      -- noremap = true,
    },
  },
}
```

### Telescope

This plugin provides an *nvim-telescope* extension. See the example below for
usage

```lua
local telescope = require("telescope")

-- load the extension with telescope
telescope.load_extension("projects")

-- then access the function with telescope.extensions.projects.projects
-- here we make <leader>fp (find project) open the picker
vim.keymap.set("n", "<leader>fp", telescope.extensions.projects.projects, {})
```
