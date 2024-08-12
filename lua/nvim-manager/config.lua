-- wimirian's NeoVim manager
-- global configuration module

--- Class for keymaps used by workspaces. See vim.keymap.set().
--- @class WSMap
--- @field mode string The mode for the keymap.
--- @field lhs string The left side of the keymap.
--- @field rhs string The right side of the keymap.
--- @field opts table The map options.

--- @class WSSpec
--- Callback that determines when a workspace should be activated.
--- @field detector fun(): boolean
--- Callback for when a workspace is activated.
--- @field activate fun()
--- Callback for when a workspace is deactivated.
--- @field deactivate fun()
--- List of filetypes that this workspace will interact with.
--- @field filetypes string[]
--- All the lsp server configs to pass to lsp_setup in the general config.
--- @field lsp { [string]: table }
--- Should the global `lsp_setup()` be used to set up these language servers.
--- @field setup_lsp boolean
--- Keymaps for the workspace.
--- @field maps WSMap[]

--- @class ManagerConfig
--- Path that projects data is stored in.
--- @field project_path? string
--- Makes nvim cd to the first command-line file argument.
--- @field arg_cd? boolean
--- When to autodetect and load project workspaces after launch and arg_cd.
--- - "within": when launched anywhere inside a project directory
--- - "exact": when launched exactly on a project directory
--- - "never": never automatically load project workspaces
--- @field autodetect? "never"|"within"|"exact"
---
--- What workspaces to auto-enable.
--- @field auto_enable? "all"|"detect"|"none"
--- Default function to set up language servers.
--- @field lsp_setup? fun(lsp_name: string, lsp_opts: table)
--- @field workspaces? { string: WSSpec }
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

--- @class _: ManagerConfig
--- @field setup fun(opts: ManagerConfig)
local M = setmetatable({}, { __index = default_config })

--- Sets up the global configuration fo the plugin.
--- @param opts ManagerConfig The global config.
function M.setup(opts)
  opts = opts or {}

  for k, v in pairs(opts) do
    if not default_config[k] then
      vim.notify("nvim_manager.workspaces.config:\n    Unknown option: " .. k,
        vim.log.levels.WARN)
    else
      M[k] = v
    end
  end
end

return M
