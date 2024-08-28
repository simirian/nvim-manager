-- wimirian's NeoVim manager
-- global configuration module

--- Class for keymaps used by workspaces. See vim.keymap.set().
--- @class Manager.WSMap
--- @field mode string The mode for the keymap.
--- @field lhs string The left side of the keymap.
--- @field rhs string The right side of the keymap.
--- @field opts table The map options.

--- Language server specification.
--- @class Manager.LSSpec: vim.lsp.ClientConfig
--- The filetypes the language server will be attached to.
--- @field filetypes string[]
--- The root directory of the language server. When a function, it will be
--- evaluated once every time an instance of the server is created.
--- @field root_dir? string|fun(): string

--- @class Manager.WSSpec
--- Callback that determines when a workspace should be activated.
--- @field detector fun(): boolean
--- Callback for when a workspace is activated.
--- @field activate fun()
--- Callback for when a workspace is deactivated.
--- @field deactivate fun()
--- List of filetypes that this workspace will interact with.
--- @field filetypes string[]
--- All the lsp server configs to pass to lsp_setup in the general config.
--- @field lsp { [string]: Manager.LSSpec }
--- Keymaps for the workspace.
--- @field maps Manager.WSMap[]

--- @class _: Manager.Config
--- @field setup fun(opts: Manager.Config)
local M = {}


--- @class Manager.Config
--- Path that projects data is stored in.
--- @field project_path? string
--- Makes nvim cd to the first command-line file argument.
--- @field arg_cd? boolean
--- When to autodetect and load project workspaces after launch and arg_cd.
--- - "within": when launched anywhere inside a project directory
--- - "exact": when launched exactly on a project directory
--- - "never": never automatically load project workspaces
--- @field autodetect? "never"|"within"|"exact"
--- What workspaces to auto-enable.
--- @field auto_enable? "all"|"detect"|"none"
--- All the configured workspaces.
--- @field workspaces? { [string]: Manager.WSSpec }
M.default = {
  project_path = vim.fs.joinpath(
    vim.fn.stdpath("data") --[[ @as string ]], "projects.json"),
  arg_cd = true,
  autodetect = "within",
  auto_enable = "none",
  workspaces = nil,
}

--- @type Manager.Config
M.user = {}

--- Sets up the global configuration fo the plugin.
--- @param opts Manager.Config The global config.
function M.setup(opts)
  opts = opts or {}
  M.user = setmetatable(opts, { __index = M.default })
end

return M
