-- simirian's NeoVim manager
-- workspace manager

local config = {
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

--- Workspaces cache.
--- @type { string: table }
local workspaces = {}

--- List of active workspaces.
--- @type string[]
local active_workspaces = {}

local M = {}

--- Loads workspaces from user config.
local function load_data()
  -- if the user provided a table directly
  if type(config.workspaces) == "table" then
    workspaces = vim.deepcopy(config.workspaces --[[ @as { string: table }]])
    return
  end

  -- get files in workspace path
  local files = vim.api.nvim_get_runtime_file("lua/"
    .. config.workspaces .. "/*.lua", true)

  for _, file in ipairs(files) do
    -- convert them to workspace and module names
    local basename = vim.fs.basename(file)
    local wsname = basename:sub(0, -5)
    local module = config.workspaces .. "." .. wsname

    -- require them into workspaces cache
    workspaces[wsname] = require(module)
  end
end

--- Activates the given workspace.
--- @param ws_name string The workspace name.
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

  -- record that this workspace is now active
  if not vim.tbl_contains(active_workspaces, ws_name) then
    table.insert(active_workspaces, ws_name)
  end

  if ws_opts.implies then
    for _, rq_name in ipairs(ws_opts.implies) do
      if not vim.tbl_contains(active_workspaces, rq_name) then
        M.activate(rq_name)
      end
    end
  end

  -- run activation function
  if ws_opts.activate then ws_opts.activate() end

  -- activate lsp
  if ws_opts.lsp then
    for lsp_name, lsp_opts in pairs(ws_opts.lsp) do
      config.lsp_setup(lsp_name, lsp_opts)
    end
  end

  -- set mappings
  if ws_opts.maps then
    for _, kb_tbl in ipairs(ws_opts.maps) do
      vim.keymap.set(
        kb_tbl.mode or "n", kb_tbl.lhs, kb_tbl.rhs, kb_tbl.opts or {}
      )
    end
  end

  return true
end

--- Enables all workspaces, or enables them based on their detector functions.
--- @param opts? "detect"|"all" How to enable workspaces.
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

--- Returns a list of configured workspaces.
--- @return string[] workspaces
function M.list_configured()
  -- make sure workspaces are loaded
  if not next(workspaces) then load_data() end
  return vim.tbl_keys(workspaces)
end

--- Returns a list of the active workspaces.
--- @return string[] workspaces
function M.list_active()
  return vim.deepcopy(active_workspaces)
end

--- A list of all filetypes needed for treesitter parsers.
--- @return table
function M.ts_fts()
  -- make sure workspaces are loaded
  if not next(workspaces) and not load_data() then return {} end

  local fts = {}

  for _, ws in pairs(workspaces) do
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
  -- make sure workspaces are loaded
  if not next(workspaces) and not load_data() then return {} end

  local servers = {}

  for _, ws in pairs(workspaces) do
    for server, _ in pairs(ws.lsp) do
      if not vim.tbl_contains(servers, server) then
        table.insert(servers, server)
      end
    end
  end

  return servers
end

--- Table of commands for this module.
--- @type { string: table }
local commands = {

  --- Activate a workspace.
  WorkspaceActivate = {
    function(opts)
      M.activate(opts.fargs[1])
    end,
    nargs = 1,
    complete = function()
      return M.list_configured()
    end,
  },

  --- Enable workspaces in bulk.
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

  --- List configured workspaces.
  WorkspaceListConf = {
    function()
      for _, v in pairs(M.list_configured()) do print(v) end
    end,
  },

  --- List active workspaces.
  WorkspaceListActive = {
    function()
      for _, v in ipairs(M.list_active()) do print(v) end
    end,
  },
}

--- Sets up global workspace settings.
--- @param opts? table
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  load_data()

  -- load commands
  for k, v in pairs(commands) do
    local copts = vim.deepcopy(v)
    table.remove(copts, 1)
    vim.api.nvim_create_user_command(k, v[1], copts)
  end

  -- enable workspaces based on config
  if config.auto_enable then
    M.enable(config.auto_enable)
  end
end

return M
