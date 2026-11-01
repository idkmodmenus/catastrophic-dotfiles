//@ pragma UseQApplication

import Quickshell
import qs.PowerApp

// Entry point of the Catastrophic Power Menu. Start it with:
//
//   qs -p ~/.local/share/catastrophic-powermenu
//
// and control it over IPC (qs ipc show lists the functions):
//
//   qs -p ~/.local/share/catastrophic-powermenu ipc call power toggle
ShellRoot {
    PowerWindow {}
}
