-- simirian's NeoVim manager
-- workspace manager

local config = {
  workspace_module = "workspaces",
  autoload = true,
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

--- @type string[]
local active_workspaces = {}

local M = {}

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  M.enable()
end

--- Loads workspaces from user config
function M.load_workspaces()
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

--- Load, cahce, and return a list of configured workspaces.
--- @return { string: table} workspaces
function M.list_workspaces()
  if next(workspaces) then return workspaces end
  M.load_workspaces()
  return workspaces
end

--- Return a list of the active workspaces.
--- @return string[] active_workspaces
function M.active_workspaces()
  return active_workspaces
end

--- Activates the given workspace.
--- @param ws_name string
--- @return boolean success
function M.activate(ws_name)
  if not next(workspaces) then M.load_workspaces() end

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

--- Enables workspaces based on the options
--- @param opts? "detect"|"all"|table detect, all, or a list of workspaces
function M.enable(opts)
  if not next(workspaces) then M.load_workspaces() end
  opts = opts or "detect"

  if type(opts) == "table" then
    for _, ws_name in ipairs(opts) do
      M.activate(ws_name)
    end
  elseif opts == "detect" then
    for ws_name, ws_opts in pairs(workspaces) do
      if ws_opts.detector and ws_opts.detector() then
        M.activate(ws_name)
      end
    end
  elseif opts == "all" then
    for ws_name, ws_opts in pairs(workspaces) do
      M.activate(ws_name)
    end
  else
    vim.notify("Workspaces: unrecognized enable option " .. opts
      .. "\nto load a single workspace call `activate`",
      vim.log.levels.ERROR)
  end
end

return M
