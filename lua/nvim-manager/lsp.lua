-- simirian's NeoVim manager
-- lsp manager

local vls = vim.lsp
local vfn = vim.fn
local vfs = vim.fs
local api = vim.api
local uv = vim.loop

local H = {}
local M = {}

--- Language server config.
--- @class Manager.LSP.Config: vim.lsp.ClientConfig
--- The filetypes to attach the language server to.
--- @field filetypes string[]
--- The root directory in which the server should be activated.
--- @field root_dir string|fun(): string

--- @type { [string]: Manager.LSP.Config }
H.specs = {}

--- Prints an error message.
--- @param msg any
function H.error(msg)
  vim.notify("nvim-manager.lsp:\n    " .. msg:gsub("\n", "\n    "),
    vim.log.levels.ERROR)
end

--- Generates an augroup for a server.
--- @param server Manager.LSP.Config The server to generate an augroup for.
--- @return integer gid
function H.augroup(server)
  return api.nvim_create_augroup(
    "Manager.LSP." .. server.name, { clear = false })
end

--- Cleans a language server config.
--- @param server Manager.LSP.Config
--- @return boolean success
function H.clean_config(server)
  local ok = true
  if not server.name then
    H.error("Unnamed language server.")
    ok = false
  end
  if not server.cmd then
    H.error("Language server has no `cmd`, it cannot be run: "
      .. (server.name or "unnamed"))
    ok = false
  end
  if not server.filetypes then
    H.error("Language server has no `filetypes`, it will never attach: "
      .. (server.name or "unnamed"))
    ok = false
  end
  if not ok then return false end

  if not server.root_dir then
    server.root_dir = function()
      return vfs.root(0, ".git") or vfs.normalize(uv.cwd())
    end
  end

  if uv.os_uname().sysname == "Windows_NT" and server.cmd[1] ~= vim.o.shell then
    local cmd = { vim.o.shell, vim.o.shellcmdflag }
    for _, arg in ipairs(server.cmd --[[ @as string[] ]]) do cmd[#cmd] = arg end
    server.cmd = cmd
  end
  return true
end

--- Registers a server config.
--- @param server Manager.LSP.Config The server config to register.
function M.register(server)
  local cleaned = H.clean_config(server)
  if not cleaned then return end

  H.specs[server.name] = server

  api.nvim_create_autocmd("FileType", {
    group = H.augroup(server),
    pattern = server.filetypes,
    callback = function()
      local copy = vfn.copy(server)
      if type(copy.root_dir) == "function" then
        copy.root_dir = copy.root_dir()
      end
      vls.start(copy)
    end
  })
end

--- Removes a language server registry entry.
--- @param name string The server name.
function M.remove(name)
  if not H.specs[name] then
    H.error("Tried to remove an unknown language server: " .. name .. ".")
    return
  end
  local clients = vls.get_clients { name = name }
  for _, client in ipairs(clients) do client.stop() end
  api.nvim_del_augroup_by_id(H.augroup(H.specs[name]))
end

return M
