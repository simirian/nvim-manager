-- simirian's NeoVim manager
-- workspace configuration

--- @class WSConfig
--- workspace modules or where to find them
--- @field workspaces string|{string: table}
--- what workspaces to auto-enable
--- @field auto_enable "all"|"detect"|"none"
--- default function to set up language servers
--- @field lsp_setup fun(lsp_name: string, lsp_opts: table)
local default_config = {
  workspaces = "workspaces",
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
  end
}

--- @type WSConfig
--- @diagnostic disable-next-line missing-fields
local config = {}
setmetatable(config, { __index = default_config })

local M = {}

--- Class for keymaps used by workspaces. See vim.keymap.set().
--- @class WSMap
--- @field mode string The mode for the keymap.
--- @field lhs string The left side of the keymap.
--- @field rhs string The right side of the keymap.
--- @field opts table The map options.

--- @class WSSpec
--- Callback for when a workspace is activated.
--- @field activate fun()
--- Callback for when a workspace is deactivated.
--- @field deactivate fun()
--- All the lsp server configs to pass to lsp_setup in the general config.
--- @field lsp { string: table }
--- Keymaps for the workspace.
--- @field maps WSMap[]
-- TODO: workspace spec class

--- @type WSSpec[]
M.ws_specs = {}

--- Sets up global workspace settings.
--- @param opts? WSConfig Config for the workspaces module.
function M.setup(opts)
  opts = opts or {}
  for k, v in pairs(opts) do
    if not default_config[k] then
      vim.notify("nvim_manager.workspaces.config:\n    Unknown option: " .. k,
        vim.log.levels.WARN)
    else
      config[k] = vim.deepcopy(v)
    end
  end
end

--- Gets copies of config values.
--- @return WSConfig value
function M.get()
  return setmetatable(vim.deepcopy(config), { __index = default_config })
end

--- Adds a workspace specification to the configured list.
--- @param ws_name string The name of the workspace being added.
--- @param ws_spec WSSpec The workspace's specification.
function M.add(ws_name, ws_spec)
  if M.ws_specs[ws_name] ~= nil then
    vim.notify("nvim_manager.workspaces.config:\n    Adding an existing spec: "
      .. ws_name, vim.log.levels.WARN)
    return
  end
  M.ws_specs[ws_name] = ws_spec
end

return M
