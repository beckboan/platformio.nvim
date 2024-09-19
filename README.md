# PLATFORMIO Plugin for NVIM Intergration

## Lua overhaul of https://github.com/normen/vim-pio

This plugin is a work in progress and is being developed in Lua. The goal is to provide a more efficient and faster way to interact with PlatformIO from within Neovim.

## Commands

### Boards

There are two commands for boards:

1. `:PIOViewBoards` - List all available boards
2. `:PIOSelectBoard` - Add a new board

### Packages

Packages allow for the installation, uninstallation, and updating of packages.

There are three kinds of packages:
1. Platform
2. Library
3. Tool

#### Platform

1. `:PIOInstallPlatform` - Install a new platform

#### Library
1. `:PIOInstallLibrary` - Install a new library

#### Tool
1. `:PIOInstallTool` - Install a new tool

#### General
1. `:PIOUpdate` - view outdated packages and select packages to update or update all
2. `:PIOUninstall` - select packages to uninstall


## TO DO

PIO commands:
- [x] `pio init`
- [x] `pio boards`
- [x] `pio pkg install`
- [ ] `pio pkg uninstall`
- [ ] `pio pkg update`
- [ ] `pio run`
- [ ] `pio run -t upload`
- [ ] `pio device list`
- [ ] `pio device monitor`
- [ ] `pio run clean`
- [ ] `pio run -t clean`
- [ ] `pio run test`
- [ ] `pio upgrade`



#### Note - also planning to add a telescope option for for the package installation, board selection, etc.
