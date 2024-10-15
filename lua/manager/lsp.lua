-- simirian's NeoVim manager
-- lsp manager

local lsp = vim.lsp
local vfn = vim.fn
local api = vim.api
local uv = vim.loop

local H = {}
local M = {}

--- Language server config.
--- @class Manager.LSP.Config: vim.lsp.ClientConfig
--- The filetypes to attach the language server to.
--- @field filetypes string|string[]
--- A function that gets the root directory for the language server.
--- @field get_root? fun(): string

--- @type { [string]: Manager.LSP.Config }
H.specs = {}

--- Prints an error message.
--- @param msg any
function H.error(msg)
  vim.notify("nvim-manager.lsp:\n    " .. msg:gsub("\n", "\n    "),
    vim.log.levels.ERROR)
end

H.augroup = api.nvim_create_augroup("Manager_LSP", { clear = false })

--- Cleans a language server config.
--- @param server Manager.LSP.Config
--- @return boolean success
function H.validate(server)
  local ok = true
  if not server.name then
    H.error("Unnamed language server.")
    server.name = "(unnamed server)"
    ok = false
  end
  if not server.cmd then
    H.error("Language server has no `cmd`, it cannot be run: " .. server.name)
    ok = false
  end
  if not server.filetypes then
    H.error("Language server has no `filetypes`, it will never attach: "
      .. server.name)
    ok = false
  end
  return ok
end

--- Cleans a language server config to ensure that it works properly.
--- @param server Manager.LSP.Config
function H.clean(server)
  if not server.root_dir and not server.get_root then
    server.get_root = function() return uv.cwd() end
  end
  if uv.os_uname().sysname == "Windows_NT" and server.cmd[1] ~= vim.o.shell then
    local cmd = vim.list_extend({ vim.o.shell }, vim.split(vim.o.shellcmdflag, " "))
    for _, arg in ipairs(server.cmd --[[ @as string[] ]]) do cmd[#cmd + 1] = arg end
    server.cmd = cmd
  end
end

--- Registers a server config.
--- @param server Manager.LSP.Config The server config to register.
function M.register(server)
  H.clean(server)
  local ok = H.validate(server)
  if not ok then return end

  H.specs[server.name] = server

  api.nvim_create_autocmd("FileType", {
    group = H.augroup,
    pattern = server.filetypes,
    callback = function()
      local copy = vfn.copy(server)
      if not copy.root_dir and copy.get_root then
        copy.root_dir = copy.get_root()
      end
      lsp.start(copy)
    end
  })
end

--- Removes a language server registry entry.
--- @param name string The server name.
function M.remove(name)
  local clients = lsp.get_clients { name = name }
  if not next(clients) then
    H.error("Tried to remove an unknown language server: " .. name)
    return
  end
  for _, client in ipairs(clients) do client.stop() end
end

return M
