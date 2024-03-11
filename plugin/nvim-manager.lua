-- simirian's NeoVim manager
-- setup variables and default config

ManagerOpts = {
  workspace_module = "workspaces",
  lsp_setup = function(lsp_name, lsp_opts)
    local lspok, lspconfig = pcall(require, "lspconfig")
    if lspok then
      lsp_opts = lsp_opts or { }
      local cmpok, cmp = pcall(require, "cmp_nvim_lsp")
      if cmpok then
        lsp_opts.capabilities = vim.tbl_deep_extend("force",
          lsp_opts.capabilities or { }, cmp.default_capabilities())
      else
        vim.notify("cmp_nvim_lsp require failed, unable to set up language server completion", vim.log.levels.WARN)
      end

      lspconfig[lsp_name].setup(lsp_opts)
    else
      vim.notify("lspconfig require failed, unable to set up language servers.", vim.log.levels.WARN)
    end
  end,
}

