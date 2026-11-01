# Catastrophic Dock

A dock for Hyprland built with [Quickshell](https://quickshell.org). Part of 
[Catastrophic OS](https://github.com/catastrophic-os/dotfiles), but it also runs on its own.

![Catastrophic Dock](screenshots/dock.png)

## Installation

```bash
curl -sSL https://raw.githubusercontent.com/catastrophic-os/catastrophic-dock/main/install.sh | bash
```

The script clones catastrophic-dock into `$HOME/.local/share/catastrophic-dock`, or pulls the
latest version if the folder already exists, and links the `catastrophic-dock` command
into `$HOME/.local/bin`. Run it again to update.

Requires `git` and `quickshell`.

`$HOME/.local/bin` must be in your `$PATH` to run `catastrophic-dock`. Most
distributions add it by default. If yours does not, add this line to your shell
configuration (e.g. `~/.bashrc` or `~/.zshrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Start

```bash
catastrophic-dock
```

This runs `qs -p ~/.local/share/catastrophic-dock`. If the dock is already running,
nothing happens. `catastrophic-dock stop` stops it and `catastrophic-dock restart` restarts it.

To start the dock with Hyprland, add this line to your Hyprland config (the Catastrophic
Dotfiles start it from `catastrophic-autostart`):

```
hl.on("hyprland.start", function ()
  hl.exec_cmd("~/.local/bin/catastrophic-dock")
end)
```

## IPC

```bash
catastrophic-dock <function>
```

This is a shortcut for `qs -p ~/.local/share/catastrophic-dock ipc call dock <function>`.

| Function | Description |
|---|---|
| `toggle` / `enable` / `disable` | Show or hide the dock |
| `autohideToggle` / `autohideOn` / `autohideOff` | Toggle autohide |
| `reload` | Re-read `config.json` and apply it |
| `settings` | Open the settings dialog |
| `edit` | Open `config.json` in the configured editor |

Run `catastrophic-dock help` to list all commands.

## Configuration

The dock reads `~/.config/catastrophic-dock/config.json`. It is created on first start
and merged over the built-in defaults, so it only needs the values you want to
change. [`DockApp/config.json`](DockApp/config.json) lists every setting with
its default value.

- `dock.launcherCommand` runs when you left-click the launcher button.
- `dock.editorCommand` opens `config.json` ("Edit configuration" in the dock
  menu). The file path is appended as the last argument. If the command is empty
  or its program is not found, `xdg-open` is used.
- `theme.colorsFile` is a JSON file of Material color roles (matugen's
  `colors.json` format). The dock watches it and recolors when it changes.

Both commands are run through bash, so `~`, arguments and pipes work.

## Wallpaper colors with matugen

To make the dock follow your wallpaper, have [matugen](https://github.com/InioX/matugen)
write its colors to `theme.colorsFile`. Add a template to
`~/.config/matugen/config.toml`:

```toml
[templates.catastrophic_dock]
input_path  = "./templates/colors.json"
output_path = "~/.config/catastrophic-dock/colors.json"
```

`templates/colors.json` maps each Material color role to its matugen value, e.g.
`"primary": "{{colors.primary.default.hex}}"`. The dock watches the file, so no
`post_hook` is needed. Catastrophic OS ships a complete
[config and template](https://github.com/catastrophic-os/dotfiles/tree/main/dotfiles/.config/matugen).

## Uninstall

```bash
curl -sSL https://raw.githubusercontent.com/catastrophic-os/catastrophic-dock/main/uninstall.sh | bash
```

Stops the dock and removes `$HOME/.local/share/catastrophic-dock` and the
`catastrophic-dock` command in `$HOME/.local/bin`. Your configuration in
`~/.config/catastrophic-dock` is kept.
