-- simirian's NeoVim manager
-- workspace manager

local M = { }

function M.workspaces()
  local workspaces = { }

  local files = vim.api.nvim_get_runtime_file("lua/"
    .. ManagerOpts.workspace_module .. "/*.lua", true)
  for _, file in ipairs(files) do
    local basename = vim.fs.basename(file)
    local wsname = string.match(basename, "%w*")
    local path = ManagerOpts.workspace_module .. "." .. wsname
    workspaces[wsname] = require(path)
  end

  return workspaces
end

function M.activate(ws_name, ws_opts)
  if ws_opts.pre_activate then ws_opts.pre_activate() end

  if ws_opts.lsp then
    for lsp_name, lsp_opts in pairs(ws_opts.lsp) do
      ManagerOpts.lsp_setup(lsp_name, lsp_opts)
    end
  end

  if ws_opts.events and ws_opts.events.activate then
    vim.api.nvim_exec_autocmds("User", { pattern = ws_opts.events.activate })
  else
    vim.api.nvim_exec_autocmds("User", { pattern = "WSEnter:" .. ws_name })
  end

  if ws_opts.post_activate then ws_opts.post_activate() end
end

function M.enable(opts)
  opts = opts or "detect"
  local workspaces = M.workspaces()

  if type(opts) == "table" then
    for _, ws_name in pairs(opts) do
      M.activate(ws_name, workspaces[ws_name])
    end
  elseif opts == "detect" then
    for ws_name, ws_opts in pairs(workspaces) do
      if ws_opts.detector and ws_opts.detector() then
        M.activate(ws_name, ws_opts)
      end
    end
  elseif opts == "all" then
    for ws_name, ws_opts in pairs(workspaces) do
      M.activate(ws_name, ws_opts)
    end
  end
end

return M

