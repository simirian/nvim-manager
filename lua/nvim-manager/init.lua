-- simirian's NeoVim manager

return setmetatable({}, {
  __index = function(t, k)
    if k == "workspaces" then
      t[k] = require("nvim-manager.workspaces")
      return t[k]
    end
    if k == "projects" then
      t[k] = require("nvim-manager.projects")
      return t[k]
    end
  end,
})
