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

return M

