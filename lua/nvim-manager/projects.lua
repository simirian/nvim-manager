-- simirian's NeoVim manager
-- projects manager

local ws = require("nvim-manager.workspaces")

local vfn = vim.fn
local vfs = vim.fs
local uv = vim.loop

--- This class represents project data.
--- @class Manager.Project
--- The path to the project.
--- @field path string
--- List of workspaces to activate when entering this project.
--- @field workspaces string[]

--- List of saved projects.
--- @type { [string]: Manager.Project }
local projects = {}

--- The currently active project.
--- @type string
local current_project = ""

local H = {}
local M = {}

--- @class Manager.Project.Config
--- The path in which to save the projects.json file.
--- @field project_path? string
--- Whether or not to automatically change directory to the first command-line
--- file argument.
--- @field arg_cd? boolean
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
  arg_cd = true,
  auto_detect = "within",
}

--- Appropriately decorates a warning message for this module.
--- @param msg string The warning message.
function H.warn(msg)
  vim.notify("nvim-manager.projects:\n    " .. msg:gsub("\n", "\n    "),
    vim.log.levels.WARN)
end

--- Appropriately decorates an error for this module.
--- @param msg string The error message.
function H.error(msg)
  vim.notify("nvim-manager.projects:\n    " .. msg:gsub("\n", "\n    "),
    vim.log.levels.ERROR)
end

--- Saves currently loaded project data. DO NOT run if loading failed!
function H.save_data()
  for _, project in pairs(projects) do
    project.path = vfs.normalize(project.path)
  end
  if vfn.writefile({ vfn.json_encode(projects) }, H.defaults.project_path) == -1 then
    H.error("Failed to save projects data to " .. H.defaults.project_path)
  end
end

--- Loads the currently saved project data.
function H.load_data()
  if vfn.filereadable(H.defaults.project_path) == 0 then
    vfn.writefile({ "{}" }, H.defaults.project_path)
  end
  local readok, contents = pcall(vfn.readfile, H.defaults.project_path)
  if not readok then
    H.error("Failed to load project data file " .. H.defaults.project_path)
    return
  end
  projects = vfn.json_decode(contents)
end

local commands = {}

--- Load a saved project.
--- @param name string The project to load.
function M.load(name)
  -- load from name
  local project = projects[name]
  if not project then
    H.error("Unknown project: " .. name)
    return
  end

  ws.disable()
  current_project = name
  vim.cmd.cd(project.path)
  for _, ws_name in ipairs(project.workspaces) do
    ws.activate(ws_name)
  end
end

commands.ProjectLoad = {
  function(opts)
    M.load(opts.fargs[1])
  end,
  desc = "Load a saved project.",
  nargs = "?",
  complete = function()
    return vim.tbl_keys(projects)
  end,
}

--- Save the current nvim instance as a project.
function M.save()
  local path = uv.cwd()
  local name = vfs.basename(path)
  local active = ws.list("active")
  projects[name] = { path = path, workspaces = active }
  H.save_data()
end

commands.ProjectSave = {
  function() M.save() end,
  desc = "Save the current nvim instance as a project.",
}

--- Remove a project from the list of saved projects.
--- This will NOT delete the project from your hard drive.
--- @param name string The name of the project to delete.
function M.remove(name)
  name = name or current_project
  projects[name] = nil
  H.save_data()
end

commands.ProjectRemove = {
  function(opts) M.remove(opts.fargs[1]) end,
  desc = "Remove a project from the list if saved projects.",
  nargs = "?",
  complete = function() return vim.tbl_keys(projects) end,
}

--- Lists the saved projects.
--- @return Manager.Project[]
function M.list()
  return projects
end

commands.ProjectList = {
  function(_) vim.print(vim.tbl_keys(projects)) end,
  desc = "Lists the saved projects.",
}

--- Sets up the projects module.
function M.setup(opts)
  opts = setmetatable(opts or {}, { __index = H.defaults })
  H.load_data()

  for k, v in pairs(commands) do
    local fn = table.remove(v, 1)
    vim.api.nvim_create_user_command(k, fn, v)
  end

  if H.defaults.arg_cd then
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

  if H.defaults.autodetect == "exact" or H.defaults.autodetect == "within" then
    local cwd = vfs.normalize(uv.cwd())
    for name, project in pairs(projects) do
      if project.path == cwd then M.load(name) end
    end
  end

  if H.defaults.autodetect == "within" then
    local cwd = vfs.normalize(uv.cwd())
    for parent in vfs.parents(cwd) do
      for name, project in pairs(projects) do
        if parent == project.path then M.load(name) end
      end
    end
  end
end

return M
