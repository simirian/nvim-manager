-- simirian's NeoVim manager
-- workspace manager

--- List of configured workspaces
--- @type { [string]: Manager.WSSpec }
local ws_specs = {}

--- List of active workspaces.
--- @type string[]
local ws_active = {}

local H = {}

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

local M = {}
local commands = {}

--- Activates the given workspace.
--- @param name string The name of the workspace to activate.
function M.activate(name)
  if ws_specs[name] == nil then
    H.error("Tried to load unconfigured workspace: " .. name)
    return
  end

  if vim.tbl_contains(ws_active, name) then
    H.warn("Workspace already activated: " .. name)
  end

  table.insert(ws_active, name)
  local spec = ws_specs[name]
  if spec.activate then spec.activate() end

  if spec.lsp then
    local gid = vim.api.nvim_create_augroup("ManagerLSP-" .. name, {})
    for lsp_name, lsp_opts in pairs(spec.lsp) do
      local ok = true
      if not lsp_opts.filetypes then
        H.error(("No file types declared for workspace %s language server %s."
            .. "No buffers would be attached to this server.")
          :format(name, lsp_name))
        ok = false
      end
      if not lsp_opts.cmd then
        H.error(("No command specified for workspace %s language server %s."
          .. "Cannot start server without command."):format(name, lsp_name))
        ok = false
      end
      if ok then
        if not lsp_opts.root_dir then
          lsp_opts.root_dir = vim.fs.root(0, ".git")
              or vim.fs.normalize(vim.fn.getcwd())
        end
        if type(lsp_opts.root_dir) == "function" then
          lsp_opts.root_dir = lsp_opts.root_dir()
        end
        ---  field injected for easy shutdownn in deactivate()
        --- @diagnostic disable-next-line: inject-field
        lsp_opts.id = vim.lsp.start(lsp_opts)
        vim.api.nvim_create_autocmd("FileType", {
          group = gid,
          pattern = lsp_opts.filetypes,
          callback = function(event)
            vim.lsp.buf_attach_client(event.buf, lsp_opts.id)
          end,
        })
      end
    end
  end

  if spec.maps then
    for _, map in ipairs(spec.maps) do
      vim.keymap.set(map.mode or "n", map.lhs, map.rhs, map.opts or {})
    end
  end
end

commands.WorkspaceActivate = {
  function(opts) M.activate(opts.fargs[1]) end,
  desc = "Activates the given workspace.",
  nargs = 1,
  complete = function() return M.list("inactive") end,
}

--- Deactivates the given workspace.
--- @param name string The name of the workspace to deactivate.
function M.deactivate(name)
  if not vim.tbl_contains(ws_active, name) then
    H.error("Attempt to deactivate inactive workspace: " .. name)
    return
  end

  for i, v in ipairs(ws_active) do
    if v == name then table.remove(ws_active, i) end
  end
  local spec = ws_specs[name]
  if spec.deactivate then spec.deactivate() end

  for _, lsp_opts in pairs(spec.lsp) do
    --- field injected during activate()
    --- @diagnostic disable-next-line: undefined-field
    vim.lsp.stop_client(lsp_opts.id)
  end
  vim.api.nvim_del_augroup_by_name("ManagerLSP-" .. name)

  if spec.maps then
    for _, map in ipairs(spec.maps) do
      vim.keymap.del(map.mode, map.lhs, map.opts)
    end
  end
end

commands.WorkspaceDeactivate = {
  function(opts) M.deactivate(opts.fargs[1]) end,
  desc = "Deactivates the given workspace",
  nargs = 1,
  complete = function() return ws_active end,
}

--- Enables all workspaces, or enables them based on their detector functions.
--- @param opts? "detect"|"all" How to enable workspaces.
function M.enable(opts)
  opts = opts or "detect"

  if opts == "detect" then
    for name, spec in pairs(ws_specs) do
      if spec.detector and spec.detector() then
        M.activate(name)
      end
    end
  elseif opts == "all" then
    for name, _ in pairs(ws_specs) do
      M.activate(name)
    end
  end
end

commands.WorkspaceEnable = {
  function(opts) M.enable(opts.fargs[1]) end,
  desc = "Enables multiple workspaces based on argument.",
  nargs = "?",
  complete = function() return { "all", "detect" } end,
}

--- Disables all workspaces.
function M.disable()
  for _, name in ipairs(ws_active) do
    M.deactivate(name)
  end
end

commands.WorkspaceDisable = {
  function(_) M.disable() end,
  desc = "Disables all workspaces.",
}

--- Lists configured workspaces.
--- @param opts? "all"|"active"|"inactive" Which workspaces to include.
--- @return Manager.WSSpec[]
function M.list(opts)
  opts = opts or "all"
  if opts == "all" then return ws_specs end
  if opts == "active" then
    local list = {}
    for _, name in ipairs(ws_active) do
      list[name] = ws_specs[name]
    end
    return list
  end
  if opts == "inactive" then
    local list = {}
    for name, spec in pairs(ws_specs) do
      if not vim.tbl_contains(ws_active, name) then
        list[name] = spec
      end
    end
    return list
  end --- @diagnostic disable-line missing-return
end

commands.WorkspaceList = {
  function(opts) print(vim.inspect(vim.tbl_keys(M.list(opts.fargs[1])))) end,
  desc = "Lists configured workspaces.",
  nargs = "?",
  complete = function() return { "all", "active", "inactive" } end,
}

--- Sets up workspace commands and gets workspaces from the user config.
function M.setup()
  ws_specs = require("nvim-manager.config").user.workspaces or {}
  for k, v in pairs(commands) do
    local fn = table.remove(v, 1)
    vim.api.nvim_create_user_command(k, fn, v)
  end
end

return M
