-- simirian's NeoVim manager
-- telescope integration

local tok, telescope = pcall(require, "telescope")

local projects = require("nvim-manager.projects")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local astate = require("telescope.actions.state")
local config = require("telescope.config").values

if not tok then return end

local function pproj(opts)
  opts = opts or {}

  pickers.new(opts, {
    finder = finders.new_table { results = projects.list_projects() },
    previwer = false,
    sorter = config.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        projects.load_project(astate.get_selected_entry()[1])
      end)
      return true
    end,
  }):find()
end

return telescope.register_extension {
  setup = function() end,
  exports = {
    projects = pproj,
  },
}
