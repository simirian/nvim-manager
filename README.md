# NeoVim Manager

Project and workspace manager for NeoVim<br>

by simirian

## Features

### Workspaces

- [ ] automatically detect workspaces on entering NeoVim
    - [x] custom detection with detector functions
    - [ ] does not attempt detection when run with certain args
- [x] dynamically load lazy.nvim plugins with workspace events
- [ ] automatically setup keymaps, commands, and more in specific workspaces
    - [ ] enable keymaps and settings on entering a workspace
    - [ ] disable these settings when leaving the workspace

### Projects

- [ ] memorize project directories and active workspaces
- [ ] pick from memorized projects with telescope
- [ ] new project templates with lua and scripts
