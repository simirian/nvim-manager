-- simirian's NeoVim manager
-- projects manager

local WS = require("nvim-manager.workspaces")

local config = {
  --- The path to the file that projects will be saved in.
  --- @type string
  path = vim.fn.stdpath("data") .. (vim.fn.has("macunix") and "/" or "\\")
      .. "projects.json",

  --- Command to use to move to a project directory.
  --- @type string|fun(path: string)
  cd_command = "cd",

  --- Should vim cd to the first file argument?
  --- @type boolean
  arg_cd = true,

  --- How to autodetect projects when entering neovim. Occurs after atg_cd.
  ---   `false` to not autodetect.
  ---   `"within"` to detect any directory within a saved project.
  ---   `"exact"` to detect exactly a saved project directory.
  --- @type false|"within"|"exact"
  autodetect = "within",
}

--- Projects cache.
--- @type { string: table }
local projects = {}
-- projects[name] = { path = "/...", workspaces = { "name" } }

--- Takes a directory and returns if our cwd is in that directory.
--- @param dirname string The directory path to check.
--- @param mode? "within"|"exact" The mode to search for the file
--- @return boolean contained
local function in_dir(dirname, mode)
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  if mode == "exact" then return cwd == dirname end
  -- this will be changed immediately, so we can leave it empty
  local old = ""

  repeat
    -- if the paths match, then we are in the dir
    if cwd == dirname then return true end

    -- keep track of the old dir so we can end when there are no changes
    old = cwd
    -- remove the last file/directory in the path, so it is still valid
    cwd = vim.fn.fnamemodify(cwd, ":h")
  until cwd == old

  return false
end

--- Changes the vim directory to the specified path with the user's configured
---   cd command.
--- @param path string The path to move to.
local function cd(path)
  if type(config.cd_command) == "string" then
    vim.cmd(config.cd_command .. " " .. path)
  elseif type(config.cd_command) == "function" then
    config.cd_command(path)
  end
end

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
--- @param name string The project to load.
function M.load(name)
  -- if we can't get projects then we end early
  if not projects and not load_data() then return end

  -- if this project does not exist, we notify the caller
  if not projects[name] then
    vim.notify("projects: project " .. name .. " does not exist",
      vim.log.levels.ERROR)
    return
  end

  -- attempt to deactivate active workspaces
  for _, ws_name in ipairs(WS.list_active()) do
    WS.deactivate(ws_name)
  end

  -- otherwise we try to load the project by cd-ing to the path and loading its
  --   workspaces
  local project = projects[name]
  cd(project.path)
  for _, ws_name in ipairs(project.workspaces) do
    WS.activate(ws_name)
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
  local active = WS.list_active()
  projects[name] = { path = path, workspaces = active }
  return save_data()
end

--- Remove a project from the list of saved projects. This will NOT delete the
---   project from your hard drive.
--- @param name string The name of the project to delete.
--- @return boolean success
function M.remove(name)
  projects[name] = nil
  return save_data()
end

--- List all of the saved projects.
--- @return table projects
function M.list()
  if not projects and not load_data() then return {} end
  return vim.tbl_keys(projects)
end

--- Table of commands for this module.
--- @type { string: table }
local commands = {

  --- Load an existng project.
  ProjectLoad = {
    function(opts)
      M.load(opts.fargs[1])
    end,
    nargs = 1,
    complete = function()
      return M.list()
    end,
  },

  --- Save the current instance as a project.
  ProjectSave = {
    function()
      M.save()
    end,
  },

  --- Remove a project.
  ProjectRemove = {
    function(opts)
      M.remove(opts.fargs[1])
    end,
    nargs = 1,
    complete = function()
      return M.list()
    end,
  },

  --- List saved projects.
  ProjectList = {
    function()
      for _, v in ipairs(M.list()) do print(v) end
    end,
  },
}

--- Sets up global project settings.
--- @param opts? table
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  load_data()

  -- load commands
  for k, v in pairs(commands) do
    local copts = vim.deepcopy(v)
    table.remove(copts, 1)
    vim.api.nvim_create_user_command(k, v[1], copts)
  end

  -- if launched with a file argument and the user has it configured, cd to
  --   that file's directory
  local fargs = vim.fn.argv()
  if config.arg_cd and fargs[1] then
    cd(vim.fn.fnamemodify(fargs[1], ":p:h"))
  end

  -- autodetect based on config setting
  if config.autodetect then
    for k, v in pairs(projects) do
      if in_dir(v.path, config.autodetect) then M.load(k) end
    end
  end
end

return M
