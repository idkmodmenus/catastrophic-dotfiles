# Catastrophic OS

Hyprland desktop for Arch Linux and CachyOS.

## Install

```
curl -fsSL https://raw.githubusercontent.com/idkmodmenus/catastrophic-dotfiles/main/install.sh | bash
```

Preview first, changing nothing:

```
curl -fsSL https://raw.githubusercontent.com/idkmodmenus/catastrophic-dotfiles/main/install.sh | bash -s -- --dry-run
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

## Updating

Run the same command again. It pulls the latest version from GitHub and makes the
system match it:

- Files that changed in the repo are overwritten with the new version (the old
  profile is backed up first, in `~/.mydotfiles/backups/`).
- Your settings are kept: the default apps, theme, launcher and the other choices in
  `~/.config/catastrophic/settings`. The installer asks "Keep my Catastrophic settings"
  and keeps them by default. New settings from the repo are added next to them.
- Files the repo no longer ships are removed, along with their links in `~/.config`.
  `setup/obsolete-paths` covers installs from before the installer kept a record.
- Files you created yourself are left alone.
- The default terminal, browser, file manager and editor are chosen on the first install
  only. Updates never change them.
- Packages the desktop no longer uses (`setup/obsolete-packages`) are offered for
  removal. It asks first. Other packages are never removed.

## Update notification

A small background check watches GitHub. It starts at login and looks again every
half hour, so you hear about a new version while you are working, not only after a
reboot. While your installed version is behind GitHub:

- A **warning badge** (a yellow triangle) stays in the status group of the rail on the
  left edge, because this system may be out of date. Click it to see the notification again.
- A **notification** appears once for each new version, with three buttons:
  - **Update now** opens a terminal and runs the install command.
  - **Later** asks again at the next login.
  - **Skip this version** stops the pop-ups for that version. The badge stays.

The badge disappears as soon as the update is installed. The check is cheap: one tiny
request to GitHub every half hour at low priority, and the badge watches a file
instead of polling, so nothing runs while it is idle. It waits for the network after
login, and does nothing if GitHub cannot be reached. Turn it off with the "Notify me
about updates" setting. The state is in `~/.local/state/catastrophic/`
(`installed-commit` and `update-status`). Run
`~/.config/catastrophic/scripts/catastrophic-update-check --now` to check immediately.

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
