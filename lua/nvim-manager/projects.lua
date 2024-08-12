-- simirian's NeoVim manager
-- projects manager

local config = require("nvim-manager.config")
local ws = require("nvim-manager.workspaces")

local vfn = vim.fn
local vfs = vim.fs

--- List of saved projects.
--- @type { [string]: table }
local projects = {}

--- The currently active project.
--- @type string
local current_project = ""

local H = {}

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
  if vfn.writefile({ vfn.json_encode(projects) }, config.project_path) == -1 then
    H.error("Failed to save projects data to " .. config.project_path)
  end
end

--- Loads the currently saved project data.
function H.load_data()
  if vfn.filereadable(config.project_path) == 0 then
    vfn.writefile({ "{}" }, config.project_path)
  end
  local readok, contents = pcall(vfn.readfile, config.project_path)
  if not readok then
    H.error("Failed to load project data file " .. config.project_path)
    return
  end
  projects = vfn.json_decode(contents)
end

local M = {}
local commands = {}

--- Load a saved project.
--- @param name? string The project to load.
function M.load(name)
  if name then
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
  else
    -- TODO: load based on autodetect
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
  local path = vfn.getcwd()
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
--- @return table[] TODO: type of this
function M.list()
  return projects
end

commands.ProjectList = {
  function(_) print(vim.inspect(vim.tbl_keys(projects))) end,
  desc = "Lists the saved projects.",
}

--- Sets up the projects module.
function M.setup()
  H.load_data()

  for k, v in pairs(commands) do
    local fn = table.remove(v, 1)
    vim.api.nvim_create_user_command(k, fn, v)
  end
end

return M
