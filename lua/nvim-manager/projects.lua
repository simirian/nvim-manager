-- simirian's NeoVim manager
-- projects manager

local uv = vim.loop

local config = {
  path = vim.fn.stdpath("data")
      .. (vim.fn.has("macunix") and "/projects.txt" or "\\projects.txt"),
  cd_command = "cd"
}

local data = {}

local M = {}

--- Sets up global project settings
--- @param opts? table options
function M.setup(opts)
  opts = opts or {}
  vim.tbl_deep_extend("force", config, opts)
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
  local file = vim.fn.readfile(config.path)

  -- it it fails, attempt to recreate and reread it
  if not file then
    vim.fn.writefile("", config.path)
    file = vim.fn.readfile(config.path)
  end

  -- if that still fails, abort
  if not file then
    vim.notify("projects: could not read projects file " .. config.path,
      vim.log.levels.ERROR);
    return false
  end

  -- return the decoded file
  data = vim.fn.json_decode(file)
  return true
end

--- Loads a project.
--- @param name string the project to load
function M.load_project(name)
  if not data and not M.load_data() then return end

  if not data[name] then
    vim.notify("projects: could not load project " .. name,
      vim.log.levels.ERROR)
    return
  end

  local project = data[name]
  vim.cmd(config.cd_command .. " " .. project[1])
  for ws_name, ws_opts in pairs(project) do
    require("nvim-manager.workspaces").activate(ws_name, ws_opts)
  end
end

--- Saves currently loaded project data. DO NOT run if loading failed, your
---   projects will be cleared!
--- @return boolean success
function M.save_data()
  -- normalize paths here because we save less than we load
  for _, project in pairs(data) do
    project[1] = vim.fs.normalize(project[1])
  end

  -- try to write, and return success or failure
  if vim.fn.writefile({ vim.fn.json_encode(data) }, config.path) == -1 then
    vim.notify("projects: failed to save projects",
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
  if not opts or not opts[1] then
    vim.notify("projects: new project must have a path: " .. name,
      vim.log.levels.ERROR)
    return false
  end

  -- add to data, then save
  data[name] = opts
  return M.save_data()
end

-- figure out how this will work
--- Save the current instance as a project.
function M.save_project()
  local path = vim.fn.getcwd()
  local name = vim.fs.basename(path)
  M.add_project(name, { path })
end

function M.list_projects()
  if not data and not M.load_data() then return {} end
  return vim.tbl_keys(data)
end

return M
