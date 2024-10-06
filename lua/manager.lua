-- simirian's NeoVim manager
-- configuration and entry point

local H = {}
local M = {}

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
  opts = setmetatable(opts or {}, { __index = H.defaults })
  require("manager.workspaces").setup(opts.workspaces)
  require("manager.projects").setup(opts.projects)
end

return M
