-- simirian's NeoVim manager
-- configuration and entry point

local M = {}

local setup = false

--- Sets up global settings.
--- @param opts? Manager.Config Desired configuration.
function M.setup(opts)
  if not setup then
    opts = opts or {}
    require("nvim-manager.config").setup(opts)
    require("nvim-manager.workspaces").setup()
    require("nvim-manager.projects").setup()
    setup = true
  end
end

return M
