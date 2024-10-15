-- simirian's NeoVim manager
-- projects manager

local ws = require("manager.workspaces")

local vfn = vim.fn
local vfs = vim.fs
local uv = vim.loop

local H = {}
local M = {}

--- This class represents project data.
--- @class Manager.Project
--- The path to the project.
--- @field path string
--- List of workspaces to activate when entering this project.
--- @field workspaces string[]

--- List of saved projects.
--- @type { [string]: Manager.Project }
H.projects = {}

--- The currently active project.
--- @type string
H.current = ""

--- @class Manager.Project.Config
--- The path in which to save the projects.json file.
--- @field project_path? string
--- How to autodetect loading projects in a certain directory, *after* arg_cd.
--- eg. `nvim` will load the project in the current directory
--- eg. `nvim ./path/to/project/` would load the project there with arg_cd on
--- - "never": do not auto detect projects
--- - "exact": load projects when their directory exactly is opened
--- - "within": load projects when you enter any subdirectory
--- @field autodetect? "never"|"exact"|"within"
H.defaults = {
  project_path =
      vim.fs.joinpath(vfn.stdpath("data") --[[ @as string ]], "projects.json"),
  autodetect = "exact",
}

--- @type Manager.Project.Config
H.config = {}

--- Appropriately decorates an error for this module.
--- @param msg string The error message.
function H.error(msg)
  vim.notify("nvim-manager.projects:\n    " .. msg:gsub("\n", "\n    "),
    vim.log.levels.ERROR)
end

--- Saves currently loaded project data. DO NOT run if loading failed!
function H.save_data()
  for _, project in pairs(H.projects) do
    project.path = vfs.normalize(project.path)
  end
  local file, error = io.open(H.config.project_path, "w")
  if not file then
    H.error("Failed to save projects data. " .. error)
    return
  end
  file:write(vfn.json_encode(H.projects))
  file:close()
end

--- Loads the currently saved project data.
function H.load_data()
  local file, error = io.open(H.config.project_path, "r")
  if not file then
    local wfile = io.open(H.config.project_path, "w")
    if not wfile then
      H.error("Failed to load project data. " .. error)
      return
    else
      wfile:write("{}", H.config.project_path)
      wfile:close()
    end
  end
  file, error = io.open(H.config.project_path, "r")
  if not file then
    H.error("Failed to laod project data. " .. error)
    return
  end
  H.projects = vfn.json_decode(file:read("*a") or "{}")
  file:close()
end

H.commands = {}

--- Load a saved project.
--- @param name string The project to load.
function M.load(name)
  -- load from name
  local project = H.projects[name]
  if not project then
    H.error("Unknown project: " .. name)
    return
  end

  ws.disable()
  H.current_project = name
  vim.cmd.cd(project.path)
  for _, ws_name in ipairs(project.workspaces) do
    ws.activate(ws_name)
  end
end

H.commands.ProjectLoad = {
  function(opts)
    M.load(opts.fargs[1])
  end,
  desc = "Load a saved project.",
  nargs = 1,
  complete = function()
    return vim.tbl_keys(H.projects)
  end,
}

--- Save the current nvim instance as a project.
function M.save()
  local path = uv.cwd()
  local name = vfs.basename(path)
  local active = vim.tbl_keys(ws.list("active"))
  H.projects[name] = { path = path, workspaces = active }
  H.save_data()
end

H.commands.ProjectSave = {
  function() M.save() end,
  desc = "Save the current nvim instance as a project.",
}

--- Remove a project from the list of saved projects.
--- This will NOT delete the project from your hard drive.
--- @param name string The name of the project to delete.
function M.remove(name)
  name = name or H.current_project
  H.projects[name] = nil
  H.save_data()
end

H.commands.ProjectRemove = {
  function(opts) M.remove(opts.fargs[1]) end,
  desc = "Remove a project from the list if saved projects.",
  nargs = "?",
  complete = function() return vim.tbl_keys(H.projects) end,
}

--- Lists the saved projects.
--- @return Manager.Project[]
function M.list()
  return H.projects
end

H.commands.ProjectList = {
  function(_) vim.print(vim.tbl_keys(H.projects)) end,
  desc = "Lists the saved projects.",
}

--- Sets up the projects module.
function M.setup(opts)
  H.config = setmetatable(opts or {}, { __index = H.defaults })
  H.load_data()

  for k, v in pairs(H.commands) do
    local fn = table.remove(v, 1)
    vim.api.nvim_create_user_command(k, fn, v)
  end

  if H.config.autodetect == "exact" or H.config.autodetect == "within" then
    local cwd = vfs.normalize(uv.cwd())
    for name, project in pairs(H.projects) do
      if project.path == cwd then M.load(name) end
    end
  end

  if H.config.autodetect == "within" then
    local cwd = vfs.normalize(uv.cwd())
    for parent in vfs.parents(cwd) do
      for name, project in pairs(H.projects) do
        if parent == project.path then M.load(name) end
      end
    end
  end
end

return M
