-- simirian's NeoVim manager
-- projects manager

local uv = vim.loop

local config = {
  path = vim.fn.stdpath("data") .. (vim.fn.has("macunix") and "/" or "\\")
    .. "projects.json",
  cd_command = "cd",
  autoload = true
}

-- projects cache
local projects = {}

local M = {}

--- Sets up global project settings
--- @param opts? table options
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  if config.autoload then M.load_data() end
end

--[[
local projects = {
  ["nvim-dot"] = { -- name is key
    "C:\\Users\\what\\AppData\\local\\nvim\\", -- path is [1]
    nvim = {} -- workspaces are in pairs(project)
  }
}
]]

--- Loads and caches project data.
--- @return boolean success
function M.load_data()
  -- read the projects file
  local fok, file = pcall(vim.fn.readfile, config.path)

  -- it it fails, attempt to recreate and reread it
  if not fok then
    vim.fn.writefile({"{}"}, config.path)
    fok, file = pcall(vim.fn.readfile, config.path)
  end

  -- if that still fails, abort
  if not fok then
    vim.notify("projects: could not read projects file " .. config.path,
      vim.log.levels.ERROR);
    return false
  end

  -- return the decoded file
  projects = vim.fn.json_decode(file)
  return true
end

--- Loads a project.
--- @param name string the project to load
function M.load_project(name)
  if not projects and not M.load_data() then return end

  if not projects[name] then
    vim.notify("projects: project " .. name .. " does not exist",
      vim.log.levels.ERROR)
    return
  end

  local project = projects[name]
  vim.cmd(config.cd_command .. " " .. project.path)
  for _, ws_name in pairs(project.workspaces) do
    require("nvim-manager.workspaces").activate(ws_name)
  end
end

--- Saves currently loaded project data. DO NOT run if loading failed, your
---   projects will be cleared!
--- @return boolean success
function M.save_data()
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

--- Adds a project to the loaded data, then saves the data.
--- @param name string the name of the project to add
--- @param opts table the project options
--- @return boolean success
function M.add_project(name, opts)
  -- make sure the project has a path
  if not opts or not opts.path then
    vim.notify("projects: new project ".. name .. " must have a path",
      vim.log.levels.ERROR)
    return false
  end

  -- add to data, then save
  projects[name] = opts
  return M.save_data()
end

-- figure out how this will work
--- Save the current instance as a project.
function M.save_project()
  local path = vim.fn.getcwd()
  local name = vim.fs.basename(path)
  local active = require("nvim-manager.workspaces").active_workspaces()
  return M.add_project(name, { path = path, workspaces = active })
end

function M.list_projects()
  if not projects and not M.load_data() then return {} end
  return vim.tbl_keys(projects)
end

return M
