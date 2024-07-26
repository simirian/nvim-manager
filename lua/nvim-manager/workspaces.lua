-- simirian's NeoVim manager
-- workspace manager

local config = require("nvim-manager.workspaces.config")
local rocfg = config.get()

--- List of active workspaces.
--- @type string[]
local ws_active = {}

local H = {}

--- Checks if a workspace is active or not.
--- @param ws_name string The name of the workspace to check.
--- @return boolean
function H.is_active(ws_name)
  return vim.tbl_contains(ws_active, ws_name)
end

--- Checks if a workspace exists
--- @param ws_name string The name of the workspace to check.
--- @return boolean
function H.exists(ws_name)
  return config.ws_specs[ws_name] ~= nil
end

--- Lists all configured workspaces
--- @return string[]
function H.list_configured()
  return vim.tbl_keys(config.ws_specs)
end

--- Lists all active workspaces
--- @return string[]
function H.list_active()
  return vim.deepcopy(ws_active)
end

--- Lists all inactive workspaces.
--- @return string[]
function H.list_inactive()
  local list = {}
  for k, _ in pairs(config.ws_specs) do
    if not vim.tbl_contains(ws_active, k) then
      table.insert(list, k)
    end
  end
  return list
end

local M = {}
local commands = {}

--- Activates the given workspace.
--- @param ws_name string The workspace name.
function M.activate(ws_name)
  if not H.exists(ws_name) then
    vim.notify("nvim-manager.workspaces:\n    " ..
      "Tried to load unconfigured workspace: " .. ws_name, vim.log.levels.ERROR)
    return
  end

  if H.is_active(ws_name) then
    vim.notify("nvim-manager.workspaces:\n    Workspace already activated: "
      .. ws_name, vim.log.levels.WARN)
    return
  end

  table.insert(ws_active, ws_name)
  local ws_spec = config.ws_specs[ws_name]
  if ws_spec.activate then ws_spec.activate() end

  if ws_spec.lsp and ws_spec.setup_lsp ~= false then
    for lsp_name, lsp_opts in pairs(ws_spec.lsp) do
      rocfg.lsp_setup(lsp_name, lsp_opts)
    end
  end

  -- set mappings
  if ws_spec.maps then
    for _, map in ipairs(ws_spec.maps) do
      vim.keymap.set(map.mode or "n", map.lhs, map.rhs, map.opts or {})
    end
  end
end

--- Activate a workspace.
commands.WorkspaceActivate = {
  function(opts)
    M.activate(opts.fargs[1])
  end,
  nargs = 1,
  complete = function()
    return H.list_inactive()
  end,
}

--- Deactivates the named workspace and removes keymaps and commands.
--- @param ws_name string The name of the workspace to deactivate.
function M.deactivate(ws_name)
  if not H.is_active(ws_name) then
    vim.notify("nvim-manager.workspaces:\n    "
      .. "Attempt to deactivate inactive workspace: " .. ws_name,
      vim.log.levels.ERROR)
    return
  end

  for i, v in ipairs(ws_active) do
    if v == ws_name then table.remove(ws_active, i) end
  end
  local ws_spec = config.ws_specs[ws_name]
  if ws_spec.deactivate then ws_spec.deactivate() end

  if ws_spec.maps then
    for _, map in ipairs (ws_spec.maps) do
      vim.keymap.del(map.mode, map.lhs, map.opts)
    end
  end
end

--- Deactivate a workspace.
commands.WorkspaceDeactivate = {
  function(opts)
    M.deactivate(opts.fargs[1])
  end,
  nargs = 1,
  complete = function()
    return H.list_active()
  end,
}

--- Enables all workspaces, or enables them based on their detector functions.
--- @param opts? "detect"|"all" How to enable workspaces.
function M.enable(opts)
  opts = opts or "detect"

  if opts == "detect" then
    for ws_name, ws_spec in pairs(config.ws_specs) do
      if ws_spec.detector and ws_spec.detector() then
        M.activate(ws_name)
      end
    end
  elseif opts == "all" then
    for ws_name, _ in pairs(config.ws_specs) do
      M.activate(ws_name)
    end
  end
end

--- Disables workspaces based on the given option
--- @param opts? "all" How to disable workspaces.
function M.disable(opts)
  opts = opts or "all"
  for _, ws_name in ipairs(ws_active) do
    M.deactivate(ws_name)
  end
end

--- Enable workspaces in bulk.
commands.WorkspaceEnable = {
  function(opts)
    M.enable(opts.fargs[1])
  end,
  nargs = 1,
  complete = function()
    return { "all", "detect" }
  end,
}

--- A list of all filetypes needed for treesitter parsers.
--- TODO: this should not exist, remove and place elsewhere!
--- @return table
function M.ts_fts()
  local fts = {}
  for _, ws in pairs(config.ws_specs) do
    for _, ft in ipairs(ws.filetypes) do
      if not vim.tbl_contains(fts, ft) then
        table.insert(fts, ft)
      end
    end
  end
  return fts
end

--- A list of language servers needed for all workspaces to function.
--- @return string[] workspaces
function M.lsps()
  local servers = {}
  for _, ws in pairs(config.ws_specs) do
    for server, _ in pairs(ws.lsp) do
      if not vim.tbl_contains(servers, server) then
        table.insert(servers, server)
      end
    end
  end
  return servers
end

commands.WSCONF = {
  function()
    P(H.list_configured())
  end,
}

for k, v in pairs(commands) do
  local fn = table.remove(v, 1)
  vim.api.nvim_create_user_command(k, fn, v)
end

return M
