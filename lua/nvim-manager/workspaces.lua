-- simirian's NeoVim manager
-- workspace manager

local config = {
  workspace_module = "workspaces",
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

--- workspaces cache
--- @type { string: table }
local workspaces = {}

--- list of active workspaces
--- @type string[]
local active_workspaces = {}

local M = {}

--- Loads workspaces from user config
local function load_data()
  -- get files in workspace path
  local files = vim.api.nvim_get_runtime_file("lua/"
    .. config.workspace_module .. "/*.lua", true)

  for _, file in ipairs(files) do
    -- convert them to workspace and module names
    local basename = vim.fs.basename(file)
    local wsname = basename:sub(0, -5)
    local module = config.workspace_module .. "." .. wsname

    -- require them into workspaces cache
    workspaces[wsname] = require(module)
  end
end

--- Activates the given workspace.
--- @param ws_name string
--- @return boolean success
function M.activate(ws_name)
  -- make sure workspaces have been loaded
  if not next(workspaces) then load_data() end

  -- make sure the workspace exists
  if not workspaces[ws_name] then
    vim.notify("workspaces: failed to load workspace " .. ws_name,
      vim.log.levels.ERROR)
    return false
  end

  local ws_opts = workspaces[ws_name]

  -- pre-activation callback
  if ws_opts.pre_activate then ws_opts.pre_activate() end

  if not vim.tbl_contains(active_workspaces, ws_name) then
    table.insert(active_workspaces, ws_name)
  end

  -- activate lsp
  if ws_opts.lsp then
    for lsp_name, lsp_opts in pairs(ws_opts.lsp) do
      config.lsp_setup(lsp_name, lsp_opts)
    end
  end

  -- post activation callback
  if ws_opts.post_activate then ws_opts.post_activate() end
  return true
end

--- Enables all workspaces, or enables them based on their detector functions
--- @param opts? "detect"|"all" how to enable workspaces
function M.enable(opts)
  -- make sure workspaces are loaded
  if not next(workspaces) then load_data() end
  opts = opts or "detect"

  if opts == "detect" then
    for ws_name, ws_opts in pairs(workspaces) do
      if ws_opts.detector and ws_opts.detector() then
        M.activate(ws_name)
      end
    end
  elseif opts == "all" then
    for ws_name, _ in pairs(workspaces) do
      M.activate(ws_name)
    end
  else
    vim.notify("Workspaces: unrecognized enable option " .. opts
      .. "\nto load a single workspace call `activate`",
      vim.log.levels.ERROR)
  end
end

--- Load, cache, and return a list of configured workspaces.
--- @return string[] workspaces
function M.list_configured()
  -- make sure workspaces are loaded
  if not next(workspaces) then load_data() end
  return vim.tbl_keys(workspaces)
end

--- Return a list of the active workspaces.
--- @return string[] workspaces
function M.list_active()
  return vim.deepcopy(active_workspaces)
end

--- table of commands for this module
--- @type { string: table }
local commands = {

  -- activate a workspace
  WorkspaceActivate = {
    function(opts)
      M.activate(opts.fargs[1])
    end,
    nargs = 1,
    complete = function()
      return M.list_configured()
    end,
  },

  -- enable workspaces in bulk
  WorkspaceEnable = {
    function(opts)
      if #opts.fargs > 1 then
        M.enable(opts.fargs)
      else
        M.enable(opts.fargs[1])
      end
    end,
    nargs = "+",
    complete = function()
      return { "all", "detect" }
    end,
  },

  -- list configured workspaces
  WorkspaceListConf = {
    function()
      for _, v in pairs(M.list_configured()) do print(v) end
    end,
  },

  -- list active workspaces
  WorkspaceListActive = {
    function()
      for _, v in ipairs(M.list_active()) do print(v) end
    end,
  },
}

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  load_data()

  for k, v in pairs(commands) do
    local copts = vim.deepcopy(v)
    table.remove(copts, 1)
    vim.api.nvim_create_user_command(k, v[1], copts)
  end
end

return M
