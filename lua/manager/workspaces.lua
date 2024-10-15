-- simirian's NeoVim manager
-- workspace manager

local api = vim.api
local vfs = vim.fs
local vfn = vim.fn
local lsp = require("manager.lsp")

local H = {}
local M = {}

--- List of active workspaces.
--- @type string[]
H.active = {}

--- Defines a workspace keymap.
--- @class Manager.Workspaces.Keymap: vim.keymap.set.Opts
--- The left hand side of the keymap.
--- @field [1] string
--- The right hand side of the kyemap.
--- @field [2] string
--- The mode in which the keymap should be active.
--- @field mode? ""|"n"|"i"|"c"|"v"|"x"|"s"|"o"|"t"|"l"

--- A Workspace specification.
--- @class Manager.Workspaces.Spec
--- Callback that determines when a workspace should be activated.
--- @field detector fun(): boolean
--- Callback for when a workspace is activated.
--- @field activate? fun()
--- Callback for when a workspace is deactivated.
--- @field deactivate? fun()
--- List of filetypes that this workspace will interact with.
--- @field filetypes? string[]
--- All the lsp server configs to pass to lsp_setup in the general config.
--- @field lsp? { [string]: Manager.LSP.Config }
--- Keymaps for the workspace.
--- @field maps? Manager.Workspaces.Keymap[]

--- General workspace config.
--- @class Manager.Workspaces.Config
--- The specs to load. If this value is a string, it is assumed to be the name
--- of a lua module.
--- @field specs? string|{ [string]: Manager.Workspaces.Spec }
--- How to enable workspaces on startup. This occurs after `arg_cd` in the
--- projects module.
--- @field auto_enable? "all"|"detect"|"none"
H.defaults = {
  specs = "workspaces",
  auto_enable = "none",
}

--- @type Manager.Workspaces.Config
H.config = {}

--- Appropriately decorates a warning message for this module.
--- @param msg string The warning message.
function H.warn(msg)
  vim.notify("nvim-manager.workspaces:\n    " .. msg:gsub("\n", "\n    "),
    vim.log.levels.WARN)
end

--- Appropriately decorates an error for this module.
--- @param msg string The error message.
function H.error(msg)
  vim.notify("nvim-manager.workspaces:\n    " .. msg:gsub("\n", "\n    "),
    vim.log.levels.ERROR)
end

H.commands = {}

--- Activates the given workspace.
--- @param name string The name of the workspace to activate.
function M.activate(name)
  if H.config.specs[name] == nil then
    H.error("Tried to load unconfigured workspace: " .. name)
    return
  end

  if vim.tbl_contains(H.active, name) then
    H.warn("Workspace already activated: " .. name)
  end

  table.insert(H.active, name)
  local spec = H.config.specs[name]
  if spec.activate then spec.activate() end

  if spec.lsp then
    for lsp_name, lsp_opts in pairs(spec.lsp) do
      lsp_opts.name = name .. "." .. lsp_name
      lsp.register(lsp_opts)
    end
  end

  if spec.maps then
    for _, map in ipairs(spec.maps) do
      local copy = vim.deepcopy(map)
      local lhs = table.remove(copy, 1)
      local rhs = table.remove(copy, 1)
      local mode = copy.mode or "n"
      copy.mode = nil
      vim.keymap.set(mode, lhs, rhs, copy)
    end
  end
end

H.commands.WorkspaceActivate = {
  function(opts) M.activate(opts.fargs[1]) end,
  desc = "Activates the given workspace.",
  nargs = 1,
  complete = function() return vim.tbl_keys(M.list("inactive")) end,
}

--- Deactivates the given workspace.
--- @param name string The name of the workspace to deactivate.
function M.deactivate(name)
  if not vim.tbl_contains(H.active, name) then
    H.error("Attempt to deactivate inactive workspace: " .. name)
    return
  end

  for i, v in ipairs(H.active) do
    if v == name then table.remove(H.active, i) end
  end
  local spec = H.config.specs[name]
  if spec.deactivate then spec.deactivate() end

  if spec.lsp then
    for _, lsp_opts in pairs(spec.lsp) do
      lsp.remove(lsp_opts.name)
    end
  end

  if spec.maps then
    for _, map in ipairs(spec.maps) do
      vim.keymap.del(map.mode, map[1], { buffer = map.buffer })
    end
  end
end

H.commands.WorkspaceDeactivate = {
  function(opts) M.deactivate(opts.fargs[1]) end,
  desc = "Deactivates the given workspace",
  nargs = 1,
  complete = function() return H.active end,
}

--- Enables all workspaces, or enables them based on their detector functions.
--- @param opts? "detect"|"all" How to enable workspaces.
function M.enable(opts)
  opts = opts or "detect"

  if opts == "detect" then
    --- @diagnostic disable-next-line param-type-mismatch It's a table here.
    for name, spec in pairs(H.config.specs) do
      if spec.detector and spec.detector() then
        M.activate(name)
      end
    end
  elseif opts == "all" then
    --- @diagnostic disable-next-line param-type-mismatch It's a table here.
    for name, _ in pairs(H.config.specs) do
      M.activate(name)
    end
  end
end

H.commands.WorkspaceEnable = {
  function(opts) M.enable(opts.fargs[1]) end,
  desc = "Enables multiple workspaces based on argument.",
  nargs = "?",
  complete = function() return { "all", "detect" } end,
}

--- Disables all workspaces.
function M.disable()
  for _, name in ipairs(H.active) do
    M.deactivate(name)
  end
end

H.commands.WorkspaceDisable = {
  function(_) M.disable() end,
  desc = "Disables all workspaces.",
}

--- Lists configured workspaces.
--- @param opts? "all"|"active"|"inactive" Which workspaces to include.
--- @return { [string]: Manager.Workspaces.Spec }
function M.list(opts)
  opts = opts or "all"
  --- @diagnostic disable-next-line param-type-mismatch It's a table here.
  if opts == "all" then return H.config.specs end
  if opts == "active" then
    local list = {}
    for _, name in ipairs(H.active) do
      list[name] = H.config.specs[name]
    end
    return list
  end
  if opts == "inactive" then
    local list = {}
    --- @diagnostic disable-next-line param-type-mismatch It's a table here.
    for name, spec in pairs(H.config.specs) do
      if not vim.tbl_contains(H.active, name) then
        list[name] = spec
      end
    end
    return list
  end --- @diagnostic disable-line missing-return
end

H.commands.WorkspaceList = {
  function(opts) vim.print(vim.tbl_keys(M.list(opts.fargs[1]))) end,
  desc = "Lists configured workspaces.",
  nargs = "?",
  complete = function() return { "all", "active", "inactive" } end,
}

--- Sets up workspace commands and gets workspaces from the user config.
--- @param opts Manager.Workspaces.Config
function M.setup(opts)
  H.config = setmetatable(opts or {}, { __index = H.defaults })

  if type(H.config.specs) == "string" then
    local modname = H.config.specs --[[ @as string ]]
    H.config.specs = {}
    local modules = api.nvim_get_runtime_file(
      vfs.joinpath("lua", modname:gsub("%.", "/"), "*.lua"), true)
    for _, module in ipairs(modules) do
      local name = vfn.fnamemodify(module, ":t:r")
      H.config.specs[name] =
          require(modname .. "." .. name)
    end
  end

  if H.config.auto_enable == "all" then
    M.enable("all")
  elseif H.config.auto_enable == "detect" then
    M.enable("detect")
  end

  for k, v in pairs(H.commands) do
    local fn = table.remove(v, 1)
    vim.api.nvim_create_user_command(k, fn, v)
  end
end

return M
