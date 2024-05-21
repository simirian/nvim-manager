# NeoVim Manager

Project and workspace manager for NeoVim<br>
by simirian

## Features

### Workspaces

- [x] automatically detect workspaces on entering NeoVim
    - [x] custom detection with detector functions
    - [x] enable workspaces by detectors on calling a lua function on startup
- [x] dynamic wokspace action with callbacks
- [ ] enable features on workspace activation
    - [x] keymaps
    - [ ] commands
- [ ] disable these settings when leaving the workspace
    - [x] keymaps
    - [ ] commands
- [x] automatically configure language servers by workspace
- [x] workspaces can imply other workspaces to automatically load each other

### Projects

- [x] memorize project directories and active workspaces
    - [x] seamlessly switch workspaces when switching projects
- [x] pick from memorized projects with telescope
- [ ] new project templates with lua and scripts
- [x] automatically recognize project direcotries and load workspaces
- [x] cd to a project dir when remotely opening a directory
  (`nvim ~/sournce/project/`)

### Misc todo

- [ ] vim helpfile
- [ ] configuration
    - [x] guide in README
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
| `activate` | `WorkspaceActivate` | `ws_name` | Activate a workspace by name. |
| `deactivate` | `WorkspaceDeactivate` | `ws_name` | Deactivate a workspace by name. |
| `enable` | `WorkspaceEnable` | `"all"`\|`"detect"`\|none | Enables all workspaces, or enables workspaces based on their detector functions. |
| `list_configured` | `WorkspaceListConf` | none | Returns (the command prints) a list of configured workspace names. |
| `list_active` | `WorkspaceListActive` | none | Returns (the command prints) a list of the active workspace names. |
| `ts_files` | none | none | Returns a list of every file type that all modules use, mainly for use with treesitter's `ensure_installed` option. |
| `lsps` | none | none | Returns a list of language servers that need to be installed with the `mason_lspconfig` (assuming that is your installation method). |

### Projects

Access the projects API through lua with `require("nvim-manger.projects")`:

| function  | vim command | options | description |
| --- | --- | --- | --- |
| `setup` | none | `opts`*?* | Loads project data and sets user configuration. |
| `save` | `ProjectSave` | none | Saves the current NeoVim instance as a project. |
| `load` | `ProjectLoad` | `name` | Loads the named project, if it exists. |
| `remove` | `ProjectRemove` | `name` | Removes a project from the list of saved projects. |
| `list` | `ProjectList` | none | Returns (the command prints) a list of saved project names. |

## Configuration

### Workspaces

#### Setup

To enable workspaces you must run `require("nvim-manager.workspaces").setup()`.
This function takes a table of options to set up global workspace settings.

By default, `opts.lsp_setup()` uses nvim-cmp and nvim-lspconfig to set up
language servers and code completion. This function can be overwritten, and
will be passed each language server config that you set up in your workspace
specs.

```lua
{
  --- Either a table of workspace specs or a module name that contains workspace
  ---   modules. If a string NAME, workspaces will look for `NAME/*.lua`.
  --- @type string|{ string: table }
  workspaces = "workspaces",

  --- How workspaces should be auto-enabled.
  ---   `false` will prevent auto enabling of workspaces.
  ---   `"all"` will enable all workspaces immediately.
  ---   `"detect"` will enable workspaces based on their activation functions.
  --- @type false|"all"|"detect"
  auto_enable = false,

  --- Function to install / enable language servers.
  --- @type fun(lsp_name: string, lsp_opts: table)
  lsp_setup = function(lsp_name, lsp_opts)
    lsp_opts = lsp_opts or {}

    -- try to load lspconfig
    local lspok, lspcfg = pcall(require, "lspconfig")
    if not lspok then
      vim.notify("workspace: lsp setup failed, lspconfig not loaded",
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
  end
}
```

#### Workspace Spec

The workspace plugin is useless without any configured workspaces. If running
setup with a table of workspaces, you should include each workspace spec should
be included in a list like table. If running setup with `workspaces =
"MODULE_NAME"` then there should be a folder in your neovim configuration
`nvim/lua/MODULE_NAME/`, which contains workspace modules that each return a
workspace spec to be loaded. An example workspace specification with all
options filled out with stubs looks like the following:

```lua
local workspace = {
  --- Detector function that decides if the workspace should be enabled.
  --- @type fun(): boolean
  detector = function() return false end,

  --- Filetypes for treesitter to install.
  --- Run TSInstall <Tab> to see completion options for filetypes.
  --- @type string[]
  filetypes = { "cpp" },

  --- Keymaps to bind.
  --- @type table[]
  maps = {
    -- see :h vim.keymap.set : options are passed directly
    {
      mode = "n",
      lhs = "f5",
      rhs = "!make<cr>",
      opts = {},
    },
  },

  --- Run when a workspace is enabled.
  --- @type fun()
  activate = function() end,

  --- Run when a workspace is deactivated.
  --- Intended to revert any changes made by the activate function above.
  --- @type fun()
  deactivate = function() end,

  --- List of other workspaaces that this one will activate.
  --- @type string[]
  implies = { "workspace name" },

  --- Should the listed language servers automatically be set up by `lsp_setup`?
  --- Defaults to true, set to false to disable this feature
  --- @type boolean
  setup_lsp = true,

  --- List of lsp servers to configure and install.
  --- @type { string: table }
  lsp = {
    ["lspconfig_name"] = {
      lspconfig_settings = "...",
      settings = {
        lsp_settings = "...",
      },
    },
  },
}
```

### Projects

#### Setup

To enable projects you must run `require("nvim-manager.projects).setup()`. This
function takes a table of options with the following default values:

```lua
{
  --- The path to the file that projects will be saved in.
  --- @type string
  path = vim.fn.stdpath("data") .. (vim.fn.has("macunix") and "/" or "\\")
      .. "projects.json",

  --- Command to use to move to a project directory.
  --- @type string|fun(path: string)
  cd_command = "cd",

  --- Should vim cd to the first file argument?
  --- @type boolean
  arg_cd = true,

  --- How to autodetect projects when entering neovim. Occurs after atg_cd.
  ---   `false` to not autodetect.
  ---   `"within"` to detect any directory within a saved project.
  ---   `"exact"` to detect exactly a saved project directory.
  --- @type false|"within"|"exact"
  autodetect = "within",
}
```

#### Telescope

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
