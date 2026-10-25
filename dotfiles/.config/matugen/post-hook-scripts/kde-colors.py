#!/usr/bin/env python3
# Merge the matugen-generated KDE colors into ~/.config/kdeglobals (other
# settings are kept) and tell running KDE apps to reload their palette.
import configparser
import pathlib
import subprocess

src = pathlib.Path.home() / ".cache/matugen/kde-colors.ini"
dst = pathlib.Path.home() / ".config/kdeglobals"


def parser():
    p = configparser.ConfigParser(interpolation=None, strict=False, delimiters=("=",))
    p.optionxform = str  # KDE keys are case-sensitive
    return p


def write(p, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    with tmp.open("w") as f:
        p.write(f, space_around_delimiters=False)
    tmp.replace(path)


colors = parser()
colors.read(src)
for section in colors.sections():
    for key, value in colors.items(section):
        if value.startswith("#") and len(value) == 7:  # KDE stores colors as r,g,b
            colors.set(section, key, ",".join(str(int(value[i:i + 2], 16)) for i in (1, 3, 5)))

# KDE apps load the scheme named in kdeglobals from color-schemes/, falling
# back to Breeze Light when it is missing, so the scheme file must exist too
colors.set("General", "Name", colors.get("General", "ColorScheme"))
write(colors, pathlib.Path.home() / ".local/share/color-schemes/Matugen.colors")

globs = parser()
if dst.exists():
    globs.read(dst)
for section in colors.sections():
    if not globs.has_section(section):
        globs.add_section(section)
    for key, value in colors.items(section):
        if not (section == "General" and key == "Name"):
            globs.set(section, key, value)
write(globs, dst)

subprocess.run(["dbus-send", "--session", "--type=signal", "/KGlobalSettings",
                "org.kde.KGlobalSettings.notifyChange", "int32:0", "int32:0"],
               check=False, stderr=subprocess.DEVNULL)
