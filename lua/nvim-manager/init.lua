-- simirian's NeoVim manager
-- configuration and entry point

local M = {}

--- Sets up global settings.
--- @param opts? ManagerConfig Desired configuration.
function M.setup(opts)
  opts = opts or {}
  local workspaces = opts.workspaces or {}
  opts.workspaces = nil
  require("nvim-manager.config").setup(opts)
  require("nvim-manager.workspaces").setup(workspaces)
  require("nvim-manager.projects").setup()
end

return M
