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
    - [x] automatically enable detected workspaces on startup
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

(tip: use `:vimgrep /function.*\.FUNCTION_NAME/ **` with the function name you
want to find)

(extra tip: if you're using lazy, your plugin sources are in `$NVIM_DATA/lazy/`,
which you can get with `vim.fn.stdpath("data")`)

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

This plugin is made of two main components, the workspaces manager and the
projects manager. Each can be set up individually with their own modules, or
together with the overall module.

```lua
require("nvim-contour").setup {
  --- @class Manager.Project.Config
  --- The path in which to save the projects.json file.
  --- @field project_path? string
  --- Whether or not to automatically change directory to the first command-line
  --- file argument.
  --- @field arg_cd? boolean
  --- How to autodetect loading projects in a certain directory, *after* arg_cd.
  --- eg. `nvim` will load the project in the current directory
  --- eg. `nvim ./path/to/project/` would load the project there with arg_cd on
  --- - "never": do not auto detect projects
  --- - "exact": load projects when their directory exactly is opened
  --- - "within": load projects when you enter any subdirectory
  --- @field autodetect? "never"|"exact"|"within"
  projects = {
    project_path = vim.fs.joinpath(vfn.stdpath("data"), "projects.json"),
    arg_cd = true,
    auto_detect = "within",
  },

  --- General workspace config.
  --- @class Manager.Workspaces.Config
  --- The specs to load. If this value is a string, it is assumed to be the name
  --- of a lua module.
  --- @field specs? string|{ [string]: Manager.Workspaces.Spec }
  --- How to enable workspaces on startup. This occurs after `arg_cd` in the
  --- projects module.
  --- @field auto_enable? "all"|"detect"|"none"
  workspaces = {
    specs = "workspaces",
    auto_enable = "none",
  }
}
```

### Workspaces

Workspaces can be defined in a workspaces module, or as a table of workspaces.
The module method is recommended. This works like lazy.nvim, you can name a lua
module (`workspaces` by default) and any submodules (files that match
`$RTP/lua/workspaces/*.lua`) will be loaded as workspaces.

Workspace modules are meant to return a table with a workspace spec. Workspace
modules will only be required once, so updates to them will not be reflected.
This is to avoid dangling settings after disabling workspaces.

```lua
--- $NVIM_CONFIG/lua/workspaces/c.lua
return -- spec here
```

#### Specs

A workspace definition, or specs as they are called, decides when the workspace
should be active (so long as you don't `:WorkspaceActivate` it) and what should
happen when they are active.

```lua
--- A Workspace specification.
--- @class Manager.Workspaces.Spec
--- Callback that determines when a workspace should be activated.
--- @field detector fun(): boolean
--- Callback for when a workspace is activated.
--- @field activate fun()
--- Callback for when a workspace is deactivated.
--- @field deactivate fun()
--- List of filetypes that this workspace will interact with.
--- @field filetypes string[]
--- All the lsp server configs to pass to lsp_setup in the general config.
--- @field lsp { [string]: Manager.LSP.Config }
--- Keymaps for the workspace.
--- @field maps Manager.Workspaces.Keymap[]
local workspace = {
  detector = function() return false end,
  activate = function() end,
  deactivate = function() end,
  filetypes = { "cpp" },
  lsp = {},
  maps = {},
}
```

#### Language Servers

The language server spec is a thin wrapper around the nvim lsp API. The language
servers are defined in a table with names as keys and a config table as the
value. The config MUST have a `cmd` to run the server and `filetypes` to attach
to. For more information see `:h vim.lsp.start()`

`root_dir` has been changed so that it can be a function or a string. If it is a
function, then whenever a file that the server should attach to is loaded the
function is called. The default value is a function that looks for a `.git/`
folder in the parents of the current directory, or failing that uses the current
directory.

```lua
--- Language server config.
--- @class Manager.LSP.Config: vim.lsp.ClientConfig
--- The filetypes to attach the language server to.
--- @field filetypes string[]
--- The root directory in which the server should be activated.
--- @field root_dir string|fun(): string
workspaces.lsp = {
  ["name"] = {
    cmd = { "language-server-command" },
    filetypes = { "attach to filetypes" },
  },
}
```

On windows, it can sometimes be painful to launch language servers for some
reason, so the cmd will automatically be updated to use `'shell'` and
`'shellcmdflag'`. This will make sure the `.exe` extension is handled.

#### Keymaps

Keymaps are defined with a fun table wrapper for `vim.keymap.set()`. The first
two values without keys are the `lhs` and `rhs`. The `mode` key is used to set
the mode. After that, all other keys/values are passed directly to
`vim.keymap.set()`. For more information see `:h vim.lsp.start()`

The left and right sides (`[1]` and `[2]`) are mandatory. The mode defaults to
`"n"`. Other values just use whatever `vim.keymap.set()` uses.

```lua
--- Defines a workspace keymap.
--- @class Manager.Workspaces.Keymap: vim.keymap.set.Opts
--- The left hand side of the keymap.
--- @field [1] string
--- The right hand side of the kyemap.
--- @field [2] string
--- The mode in which the keymap should be active.
--- @field mode? ""|"n"|"i"|"c"|"v"|"x"|"s"|"o"|"t"|"l"
workspaces.maps = {
  {
    "<f5>",
    ":make<cr>",
    mode = "n",
    desc = "build target 'all'",
    noremap = true,
  },
},
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
