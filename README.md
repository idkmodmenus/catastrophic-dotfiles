# Catastrophic OS

Hyprland desktop for Arch Linux and CachyOS.

## Install

```
bash <(curl -fsSL https://raw.githubusercontent.com/idkmodmenus/catastrophic-dotfiles/main/install.sh)
```

Preview first, changing nothing:

```
bash <(curl -fsSL https://raw.githubusercontent.com/idkmodmenus/catastrophic-dotfiles/main/install.sh) --dry-run
```

Run it as your normal user. `sudo` asks for your password when it is needed.

## What it does

1. Checks for Arch or CachyOS and an internet connection.
2. Offers a full system update first, then installs Hyprland and everything the desktop needs
   (`setup/dependencies/packages-arch`, plus AUR packages in `packages-aur`).
3. Installs the dock, power menu, window overview, walker and elephant.
4. Copies the dotfiles to `~/.mydotfiles` and symlinks them into `~/.config`.
   Anything it replaces is backed up first.
5. Asks before each system-level change: services, login manager (SDDM),
   NVIDIA driver, system icon and boot splash. `--yes` does not skip these.

Logs are in `~/.local/state/catastrophic-dotfiles-installer/logs/`.

## Layout

| Path | Purpose |
| --- | --- |
| `install.sh` | The one-line entry point |
| `catastrophic.dotinst` | Profile read by the dotfiles installer |
| `installer/` | The dotfiles installer (bundled) |
| `dotfiles/` | The configuration that is deployed |
| `apps/` | Dock, power menu, overview, walker |
| `setup/` | Package lists and install hooks |
| `branding/` | Logo and boot splash |

## Publishing

Push this folder to a public repository, then set `source` and `homepage` in
`catastrophic.dotinst` and the URLs above to match. Users can test a fork with
`CATASTROPHIC_REPO=<git url> bash install.sh`.
