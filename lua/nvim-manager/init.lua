-- simirian's NeoVim manager

local M = { }

function M.setup(opts)
  ManagerOpts = vim.tbl_deep_extend("force", ManagerOpts, opts or { })
end

return M

