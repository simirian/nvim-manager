-- simirian's NeoVim manager
-- projects manager

local config = {
  path = vim.fn.stdpath("data") .. (vim.fn.has("macunix") and "/" or "\\")
      .. "projects.json",
  cd_command = "cd",
  autodetect = true
}

--- projects cache
local projects = {}
-- projects[name] = { path = "/...", workspaces = { "name" } }

local M = {}

--- Loads and caches project data.
--- @return boolean success
local function load_data()
  -- read the projects file
  local fok, file = pcall(vim.fn.readfile, config.path)

  -- it it fails, attempt to recreate and reread it
  if not fok then
    vim.fn.writefile({ "{}" }, config.path)
    fok, file = pcall(vim.fn.readfile, config.path)
  end

  -- if that still fails, abort
  if not fok then
    vim.notify("projects: could not read projects file " .. config.path,
      vim.log.levels.ERROR);
    return false
  end

  -- if not then decode and cache the file
  projects = vim.fn.json_decode(file)
  return true
end

--- Loads a project.
--- @param name string the project to load
function M.load(name)
  -- if we can't get projects then we end early
  if not projects and not load_data() then return end

  -- if this project does not exist, we notify the caller
  if not projects[name] then
    vim.notify("projects: project " .. name .. " does not exist",
      vim.log.levels.ERROR)
    return
  end

  -- otherwise we try to load the project by cd-ing to the path and loading its
  --   workspaces
  local project = projects[name]
  vim.cmd(config.cd_command .. " " .. project.path)
  for _, ws_name in ipairs(project.workspaces) do
    require("nvim-manager.workspaces").activate(ws_name)
  end
end

--- Saves currently loaded project data. DO NOT run if loading failed!
--- @return boolean success
local function save_data()
  -- normalize paths here because we save less than we load
  for _, project in pairs(projects) do
    project.path = vim.fs.normalize(project.path)
  end

  -- try to write, and return success or failure
  if vim.fn.writefile({ vim.fn.json_encode(projects) }, config.path) == -1 then
    vim.notify("projects: failed to save projects, write failed",
      vim.log.levels.ERROR)
    return false
  end

  return true
end

--- Save the current instance as a project.
--- @return boolean success
function M.save()
  local path = vim.fn.getcwd()
  local name = vim.fs.basename(path)
  local active = require("nvim-manager.workspaces").active_workspaces()
  projects[name] = { path = path, workspaces = active }
  return save_data()
end

--- Remove a project from the list of saved projects. This WILL NOT delete the
---   project from your hard drive
--- @param name string the name of the project to delete
--- @return boolean success
function M.remove(name)
  projects[name] = nil
  return save_data()
end

function M.list()
  if not projects and not load_data() then return {} end
  return vim.tbl_keys(projects)
end

--- table of commands for this module
--- @type { string: table }
local commands = {

  -- load an existng project
  ProjectLoad = {
    function(opts)
      M.load(opts.fargs[1])
    end,
    nargs = 1,
    complete = function()
      return M.list()
    end,
  },

  -- save the current instance as a project
  ProjectSave = {
    function()
      M.save()
    end,
  },

  -- list saved projects
  ProjectList = {
    function()
      for _, v in ipairs(M.list()) do print(v) end
    end,
  },

  -- remove a project
  ProjectRemove = {
    function(opts)
      M.remove(opts.fargs[1])
    end,
    nargs = 1,
    complete = function()
      return M.list()
    end,
  },
}

--- Sets up global project settings
--- @param opts? table options
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  load_data()

  for k, v in pairs(commands) do
    local copts = vim.deepcopy(v)
    table.remove(copts, 1)
    vim.api.nvim_create_user_command(k, v[1], copts)
  end
end

return M
