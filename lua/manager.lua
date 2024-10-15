-- simirian's NeoVim manager
-- configuration and entry point

local vfs = vim.fs
local vfn = vim.fn
local uv = vim.loop

local H = {}
local M = {}

--- @class Manager.Config
--- Whether or not to automatically change directory to the first command-line
--- file argument.
--- @field arg_cd? boolean
--- The config for the projects module
--- @field projects? Manager.Project.Config
--- The config for the workspaces module
--- @field workspaces? Manager.Workspaces.Config
H.defaults = {
  arg_cd = true,
  projects = {},
  workspaces = {},
}

--- Sets up global settings.
--- @param opts? Manager.Config Desired configuration.
function M.setup(opts)
  opts = setmetatable(opts or {}, { __index = H.defaults })

  if opts.arg_cd then
    local arg_path = vfs.normalize(vfn.argv(0) --[[ @as string ]] or "")
    if arg_path ~= "" then
      local stat = uv.fs_lstat(arg_path)
      if stat and stat.type == "directory" then
        vim.cmd.cd(arg_path)
      else
        vim.cmd.cd(vfn.fnamemodify(arg_path, ":h"))
      end
    end
  end

  require("manager.workspaces").setup(opts.workspaces)
  require("manager.projects").setup(opts.projects)
end

return M
