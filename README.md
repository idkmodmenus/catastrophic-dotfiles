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

## Before you run it

Arch Linux or CachyOS, your normal user with `sudo`, an internet connection and about 6 GB of free
disk space. The installer checks these first. If it stops partway it is safe to run the same command
again: steps that are done are skipped, and your previous setup was backed up in `~/.mydotfiles/backups/`.

## What it does

1. Checks for Arch or CachyOS and an internet connection.
2. Offers a full system update first, then installs Hyprland and everything the desktop needs
   (`setup/dependencies/packages-arch`, plus AUR packages in `packages-aur`).
3. Installs the dock, window overview, settings app, walker and elephant. The overview, settings
   app, walker and elephant are not started at login; they start the first time you use them
   (see Memory use).
4. Copies the dotfiles to `~/.mydotfiles` and symlinks them into `~/.config`.
   Anything it replaces is backed up first.
5. Asks before each system-level change: services, login manager (SDDM),
   NVIDIA driver, system icon and boot splash. `--yes` does not skip these.

## The shell

The panels slide out of the screen frame. Keys are on `Super`:

| Keys | Opens |
| --- | --- |
| `Super + D` | Dashboard: clock, weather, calendar, media, system load. Resting the pointer on the top border opens it too. |
| `Super + N` | Notification centre (or click the bell; right-click it for Silent mode) |
| `Super + Ctrl + P` | Session menu: lock, log out, sleep, restart, shut down (or the power icon in the bar) |
| `Super + Ctrl + Return` | Application launcher |
| `Super + Ctrl + S` | Sidebar: volume, brightness and toggles |
| `Super + Tab` | Window overview |

Hover the volume, battery, clock, Wi-Fi, Bluetooth and media icons in the bar for a popout.
Notifications are served by the shell itself, with action buttons such as the update prompt.

## Memory use

Things that are only needed now and then are not started at login: the settings app and the
window overview start the first time they are opened (`catastrophic-app`), the sidebar, wallpaper
picker and welcome window are created when first shown, and walker and its backend elephant
start when a menu such as the clipboard history or the screenshot menu is first shown, and walker
quits when the menu closes. The first time you open one of these there is a short wait of a
second or so. On a test machine this took what runs at login for the shell and its helpers from
about 850 MB to about 370 MB.

## Updating

Run the same command again, or `~/.config/catastrophic/scripts/catastrophic-update`, which
downloads the installer, checks it and runs it. Either pulls the latest version from GitHub
and makes the system match it:

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

## Theme and wallpapers

The colors of the whole desktop come from your wallpaper. Set a new one (Super + Ctrl + W, or from the
sidebar) and the shell, dock, terminal, launcher, GTK and Qt apps recolor to match, in light or dark. This
works for pictures you download too: JPG, PNG, WebP, GIF, AVIF, HEIC and more. Pictures with transparency are
flattened first, and if a file cannot be read you get a message and the old theme stays.

If you want one color whatever the wallpaper, pick it in the sidebar's Theme settings. Remove
`~/.config/catastrophic/settings/theme-color` to follow the wallpaper again.

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
