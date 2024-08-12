# NeoVim Manager

Project and workspace manager for NeoVim<br>
by simirian

## Features

### Workspaces

- [ ] automatically detect workspaces on entering NeoVim
    - [x] custom detection with detector functions
    - [ ] enable workspaces by detectors on calling a lua function
    - [ ] autodetect workspaces on startup
- [x] dynamic wokspace action with callbacks
- [ ] enable features on workspace activation, disable on deactivation
    - [x] keymaps
    - [ ] commands
- [x] automatically configure language servers by workspace
- [ ] workspaces can imply other workspaces to automatically load each other

### Projects

- [x] memorize project directories and active workspaces
    - [x] seamlessly switch workspaces when switching projects
- [x] pick from memorized projects with telescope
- [ ] new project templates with lua and scripts
- [ ] automatically recognize project direcotries and load workspaces
- [ ] cd to a project dir when remotely opening a directory
  (`nvim ~/sournce/project/`)

### Misc todo

- [ ] vim helpfile
- [ ] configuration
    - [ ] guide in README
- [x] vim command api
    - [x] projects commands
    - [x] workspaces commands

## Usage

### Workspaces

Access the workspaces API in lua with `require("nvim-manager.workspaces")`:

| memeber        | usage                                              |
| -------------- | -------------------------------------------------- |
| `activate()`   | Activates the given workspace.                     |
| `deactivate()` | Deactivates the given workspace.                   |
| `enable()`     | Enables multiple workspaces based on the argument. |
| `disable()`    | Disables all workspaces.                           |
| `list()`       | Lists configured workspaces.                       |

All of the commands are well-documented.

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
  lsp_setup = function(lsp_name, lsp_opts)
    lsp_opts = lsp_opts or {}

    -- try to load lspconfig
    local lspok, lspcfg = pcall(require, "lspconfig")
    if not lspok then
      vim.notify("nvim-manager.workspaces:\n    "
        .. "Language server setup failed, could not find lspconfig.",
        vim.log.levels.ERROR)
      return
    end

    -- try to add nvim-cmp capabilities
    local cmpok, cmplsp = pcall(require, "cmp_nvim_lsp")
    if cmpok then
      lsp_opts.capabilities = cmplsp.default_capabilities()
    end

    -- set up the language server
    lspcfg[lsp_name].setup(lsp_opts)
  end,

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
  filetypes = { "cpp" },
  activate = function() end,
  deactivate = function() end,

  lsp = {
    ["lspconfig_name"] = {
      lspconfig_settings = "...",
      settings = {
        lsp_settings = "...",
      },
    },
  },

  setup_lsp = true,

  maps = {
    { mode = "n", lhs = "f5", rhs = "!make<cr>", opts = {} },
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
