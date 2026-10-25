# Catastrophic Power Menu

A power menu for Hyprland built with [Quickshell](https://quickshell.org). It
slides in from the right edge of the screen with buttons to lock the screen,
suspend, log out, reboot and power off. Part of
[Catastrophic OS](https://github.com/catastrophic-os/dotfiles), but it also runs on its own.

![Catastrophic Power Menu](screenshots/powermenu.jpg)

## Installation

```bash
curl -sSL https://raw.githubusercontent.com/catastrophic-os/catastrophic-powermenu/main/install.sh | bash
```

The script clones catastrophic-powermenu into `$HOME/.local/share/catastrophic-powermenu`, or
pulls the latest version if the folder already exists, and links the
`catastrophic-powermenu` command into `$HOME/.local/bin`. Run it again to update.

Requires `git` and `quickshell`.

`$HOME/.local/bin` must be in your `$PATH` to run `catastrophic-powermenu`. Most
distributions add it by default. If yours does not, add this line to your shell
configuration (e.g. `~/.bashrc` or `~/.zshrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Start

```bash
catastrophic-powermenu
```

This runs `qs -p ~/.local/share/catastrophic-powermenu`. The menu stays hidden until it
is opened. If it is already running, nothing happens. `catastrophic-powermenu stop` stops it and `catastrophic-powermenu restart`
restarts it.

To start it with Hyprland, add this line to your Hyprland config (the Catastrophic
Dotfiles start it from `catastrophic-autostart`):

```
hl.on("hyprland.start", function ()
  hl.exec_cmd("~/.local/bin/catastrophic-powermenu")
end)
```

To open the menu with a key, bind `catastrophic-powermenu toggle`, e.g.:

```
hl.bind("SUPER + CTRL + P", hl.dsp.exec_cmd("catastrophic-powermenu toggle"))
```

Use the arrow keys and Enter to pick a button, Escape or a click outside to
close the menu.

## IPC

```bash
catastrophic-powermenu <function>
```

This is a shortcut for `qs -p ~/.local/share/catastrophic-powermenu ipc call power <function>`.

| Function | Description |
|---|---|
| `toggle` / `open` / `close` | Show or hide the power menu |
| `reload` | Re-read `config.json` and apply it |
| `edit` | Open `config.json` in the configured editor |

Run `catastrophic-powermenu help` to list all commands.

## Configuration

The power menu reads `~/.config/catastrophic-powermenu/config.json`. It is created on
first start and merged over the built-in defaults, so it only needs the values
you want to change. The file is watched, so changes apply as soon as you save
it. [`PowerApp/config.json`](PowerApp/config.json) lists every setting with its
default value.

- `powermenu.order` lists the buttons from top to bottom. The available buttons
  are `lock`, `suspend`, `logout`, `reboot` and `poweroff`. Leave one out to
  hide it.
- `commands.<button>` is what the button runs. The defaults call the Catastrophic
  `catastrophic-power` script; without the Catastrophic Dotfiles, set your own commands, e.g.:

  ```json
  {
      "powermenu": { "order": ["lock", "logout", "poweroff"] },
      "commands": {
          "lock": "pidof hyprlock || hyprlock",
          "logout": "hyprctl dispatch 'hl.dsp.exit()'",
          "poweroff": "systemctl poweroff"
      }
  }
  ```

- `powermenu.editorCommand` opens `config.json` (`catastrophic-powermenu edit`). The
  file path is appended as the last argument. If the command is empty or its
  program is not found, `xdg-open` is used.
- `button`, `pill`, `border` and `opacity` set the size, spacing, shape,
  animation and transparency of the menu.
- `theme.colorsFile` is a JSON file of Material color roles (matugen's
  `colors.json` format). The power menu watches it and recolors when it changes.

All commands are run through bash, so `~`, arguments and pipes work.

## Wallpaper colors with matugen

To make the power menu follow your wallpaper, have
[matugen](https://github.com/InioX/matugen) write its colors to
`theme.colorsFile`. Add a template to `~/.config/matugen/config.toml`:

```toml
[templates.catastrophic_powermenu]
input_path  = "./templates/colors.json"
output_path = "~/.config/catastrophic-powermenu/colors.json"
```

`templates/colors.json` maps each Material color role to its matugen value, e.g.
`"primary": "{{colors.primary.default.hex}}"`. The power menu watches the file,
so no `post_hook` is needed. Catastrophic OS ships a complete
[config and template](https://github.com/catastrophic-os/dotfiles/tree/main/dotfiles/.config/matugen).

## Uninstall

```bash
curl -sSL https://raw.githubusercontent.com/catastrophic-os/catastrophic-powermenu/main/uninstall.sh | bash
```

Stops the power menu and removes `$HOME/.local/share/catastrophic-powermenu` and the
`catastrophic-powermenu` command in `$HOME/.local/bin`. Your configuration in
`~/.config/catastrophic-powermenu` is kept.
