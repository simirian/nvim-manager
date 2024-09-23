-- simirian's NeoVim manager
-- configuration and entry point

local H = {}
local M = {}

-- ensure we only setup once
H.setup = false

--- @class Manager.Config
--- The config for the projects module
--- @field projects? Manager.Project.Config
--- The config for the workspaces module
--- @field workspaces? Manager.Workspaces.Config
H.defaults = {
  projects = {},
  workspaces = {},
}

--- Sets up global settings.
--- @param opts? Manager.Config Desired configuration.
function M.setup(opts)
  if not H.setup then
    opts = setmetatable(opts or {}, { __index = H.defaults })
    require("nvim-manager.projects").setup(opts.projects)
    require("nvim-manager.workspaces").setup(opts.workspaces)
    H.setup = true
  end
end

return M
