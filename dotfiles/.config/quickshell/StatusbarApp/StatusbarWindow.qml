import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.CustomTheme

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Top

    HyprlandFocusGrab {
        windows: [root]
        active: root.barExpanded || root.calendarOpen
        onCleared: {
            root.calendarOpen = false
            root.barExpanded = false
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.calendarOpen
        onActivated: root.calendarOpen = false
    }

    readonly property var defaultSettings: ({
        "bar":    { "height": 40, "reservedHeight": 72, "enabled": true,
                    "alwaysExpanded": true, "autohide": false, "hideDelay": 400 },
        "pill":   { "collapsedWidth": 0, "expandedWidth": 680, "radius": 12, "animationDuration": 350,
                    "spacing": 14 },
        "modules":{ "left": ["terminal", "workspaces"],
                    "center": ["launcher", "clock", "swaync"],
                    "right": ["updates", "battery", "powerprofile", "volume", "systemtray", "logo", "power"] },
        "border": { "width": 2, "colorTop": "", "colorBottom": "" },
        "opacity":{ "collapsed": 0.6, "expanded": 0.8 },
        "clock":  { "format": "HH:mm", "dateFormat": "ddd, dd MMM", "calendarCommand": "" },
        "workspaces": { "count": 5 },
        "systemtray": { "chip": true }
    })

    property var settings: defaultSettings

    property bool ready: false

    property bool seeded: false

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/catastrophic-statusbar/config.json"
        blockLoading: true
        printErrors: false
        onLoaded: { root.applySettings(); root.ready = true }
        onLoadFailed: {
            if (!root.seeded) {
                root.seeded = true
                Qt.callLater(function() { seedProc.running = true })
                return
            }
            root.applySettings()
            root.ready = true
        }
    }

    Process {
        id: seedProc
        command: ["bash", "-c",
            'd="$HOME/.config/catastrophic-statusbar"; f="$d/config.json";'
            + ' mkdir -p "$d" || exit 1;'
            + ' [ -f "$f" ] && exit 0;'
            + ' [ -f "$d/statusbar.json" ] && exec mv "$d/statusbar.json" "$f";'
            + ' o="$HOME/.config/catastrophic/settings/statusbar.json";'
            + ' if [ -f "$o" ]; then cp "$o" "$f";'
            + ' else printf "{\\n}\\n" > "$f"; fi']
        onExited: settingsFile.reload()
    }

    function reloadSettings(): void {
        settingsFile.reload()
        applySettings()
    }

    function parseSettings(src) {
        if (!src)
            return undefined
        let raw = src.replace(/\/\*[\s\S]*?\*\//g, "")
        if (raw.trim() === "")
            return undefined
        try {
            return JSON.parse(raw)
        } catch (e) {
            try {
                return JSON.parse(raw.replace(/,(\s*[}\]])/g, "$1"))
            } catch (e2) {
                console.warn("statusbar settings: could not parse the settings"
                    + " file,"
                    + " ignoring it:", e2)
                return undefined
            }
        }
    }

    function mergeSettings(merged, src): void {
        let parsed = parseSettings(src)
        if (parsed === undefined)
            return
        for (let group in parsed)
            for (let key in parsed[group])
                if (merged[group] !== undefined)
                    merged[group][key] = parsed[group][key]
    }

    function applySettings(text): void {
        let merged = JSON.parse(JSON.stringify(root.defaultSettings))
        mergeSettings(merged, (text !== undefined) ? text : settingsFile.text())
        root.settings = merged
    }

    function persistBarFlag(key, on): string {
        let src = settingsFile.text()
        let re = new RegExp('("' + key + '"\\s*:\\s*)(true|false)')
        let updated
        if (re.test(src)) {
            updated = src.replace(re, "$1" + (on ? "true" : "false"))
        } else {
            let obj = root.parseSettings(src)
            if (obj === undefined && src && src.trim() !== "") {
                console.warn("statusbar settings: the settings file is not"
                    + " valid"
                    + " JSON; leaving it untouched instead of overwriting.")
                return src
            }
            if (typeof obj !== "object" || obj === null)
                obj = {}
            if (obj.bar === undefined)
                obj.bar = {}
            obj.bar[key] = on
            updated = JSON.stringify(obj, null, 4) + "\n"
        }
        settingsFile.setText(updated)
        return updated
    }

    property int barHeight: settings.bar.height
    property int reservedHeight: settings.bar.reservedHeight

    property bool barEnabled: settings.bar.enabled

    visible: (barEnabled || calendarPanel.showPanel) && ready
    readonly property int windowGap: 16
    exclusiveZone: (barEnabled && !autohide) ? reservedHeight - windowGap : 0

    function setEnabled(on: bool): void {
        applySettings(persistBarFlag("enabled", on))
    }

    property bool barExpanded: false

    property bool alwaysExpanded: settings.bar.alwaysExpanded

    function setAlwaysExpanded(on: bool): void {
        applySettings(persistBarFlag("alwaysExpanded", on))
    }

    property bool autohide: settings.bar.autohide

    function setAutohide(on: bool): void {
        applySettings(persistBarFlag("autohide", on))
    }

    readonly property bool revealed: !autohide || root.pointerHeld
        || root.barExpanded || root.trayMenuOpen || root.calendarOpen

    property bool pointerHeld: false

    Timer {
        id: hideDelay
        interval: root.settings.bar.hideDelay
        onTriggered: root.pointerHeld = false
    }

    HoverHandler {
        id: barHover
        onHoveredChanged: {
            if (barHover.hovered) {
                hideDelay.stop()
                root.pointerHeld = true
            } else {
                hideDelay.restart()
            }
        }
    }

    Component { id: cTerminal;   TerminalModule {} }
    Component {
        id: cWorkspaces
        WorkspacesModule {
            minWorkspaces: root.settings.workspaces.count
        }
    }
    Component { id: cLauncher;   LauncherModule {} }
    property bool calendarOpen: false

    property var clockRef: null

    Component {
        id: cClock
        ClockModule {
            id: clockModule
            expanded: pill.expanded
            timeFormat: root.settings.clock.format
            dateFormat: root.settings.clock.dateFormat
            calendarCommand: root.settings.clock.calendarCommand
            onCalendarToggleRequested: root.calendarOpen = !root.calendarOpen
            Component.onCompleted: root.clockRef = clockModule
            Component.onDestruction: {
                if (root.clockRef === clockModule)
                    root.clockRef = null
            }
        }
    }
    Component { id: cSwaync;     SwayncModule {} }
    property bool trayMenuOpen: false
    Component {
        id: cSystemTray
        SystemTrayModule {
            chip: root.settings.systemtray.chip
            onCollapsedChanged: Qt.callLater(root.rebuildNavItems)
            Binding {
                target: root
                property: "trayMenuOpen"
                value: menuOpen
            }
        }
    }
    Component { id: cLogo;       CatastrophicLogoModule {} }
    Component { id: cPower;      PowerModule {} }
    Component { id: cVolume;     VolumeModule {} }
    Component {
        id: cUpdates
        UpdatesModule {
            onCollapsedChanged: Qt.callLater(root.rebuildNavItems)
        }
    }
    Component {
        id: cBattery
        BatteryModule {
            onCollapsedChanged: Qt.callLater(root.rebuildNavItems)
        }
    }
    Component { id: cPowerProfile; PowerProfileModule {} }

    readonly property var moduleComponents: ({
        "terminal":   cTerminal,
        "workspaces": cWorkspaces,
        "launcher":   cLauncher,
        "clock":      cClock,
        "swaync":     cSwaync,
        "systemtray": cSystemTray,
        "logo":       cLogo,
        "power":      cPower,
        "updates":      cUpdates,
        "volume":       cVolume,
        "battery":      cBattery,
        "powerprofile": cPowerProfile
    })

    property var navItems: []
    property int focusIndex: -1

    property var workspacesRef: null
    Connections {
        target: root.workspacesRef
        ignoreUnknownSignals: true
        function onNavButtonsChanged(): void { root.rebuildNavItems() }
    }

    function rebuildNavItems(): void {
        let items = []
        let ws = null
        let groups = [leftRepeater, centerRepeater, rightRepeater]
        for (let g = 0; g < groups.length; g++) {
            let rep = groups[g]
            for (let i = 0; i < rep.count; i++) {
                let loader = rep.itemAt(i)
                let m = loader ? loader.item : null
                if (!m)
                    continue
                if (m.collapsed === true)
                    continue
                if (m.navButtons !== undefined) {
                    ws = m
                    items = items.concat(m.navButtons)
                } else if (typeof m.activate === "function") {
                    items.push(m)
                }
            }
        }
        root.workspacesRef = ws
        root.navItems = items
    }

    Component.onCompleted: Qt.callLater(rebuildNavItems)
    onSettingsChanged: Qt.callLater(rebuildNavItems)

    function applyFocus(): void {
        let items = root.navItems
        for (let i = 0; i < items.length; i++)
            if (items[i])
                items[i].focused = (i === root.focusIndex)
    }

    onFocusIndexChanged: applyFocus()
    onNavItemsChanged: {
        if (root.focusIndex >= root.navItems.length)
            root.focusIndex = root.navItems.length - 1
        applyFocus()
    }

    onBarExpandedChanged: {
        if (barExpanded) {
            focusIndex = 0
            keyHandler.forceActiveFocus()
        } else {
            focusIndex = -1
        }
    }

    function moveFocus(dir: int): void {
        if (!barExpanded)
            return
        let n = root.navItems.length
        root.focusIndex = (root.focusIndex + dir + n) % n
    }

    function stepFocused(dir: int): void {
        if (root.focusIndex < 0 || root.focusIndex >= root.navItems.length)
            return
        let m = root.navItems[root.focusIndex]
        if (typeof m.step === "function")
            m.step(dir)
    }

    function activateFocused(): void {
        let m = (root.focusIndex >= 0 && root.focusIndex < root.navItems.length)
            ? root.navItems[root.focusIndex] : null
        if (m && m !== root.clockRef)
            root.calendarOpen = false
        if (m)
            m.activate()
        root.barExpanded = false
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void { root.calendarOpen = !root.calendarOpen }
        function open(): void { root.calendarOpen = true }
        function close(): void { root.calendarOpen = false }
        function isOpen(): bool { return root.calendarOpen }
    }

    IpcHandler {
        target: "statusbar"
        function toggle(): void { root.setEnabled(!root.settings.bar.enabled) }
        function enable(): void { root.setEnabled(true) }
        function disable(): void { root.setEnabled(false) }
        function alwaysExpand(): void { root.setAlwaysExpanded(true) }
        function autoCollapse(): void { root.setAlwaysExpanded(false) }
        function autohideOn(): void { root.setAutohide(true) }
        function autohideOff(): void { root.setAutohide(false) }
        function autohideToggle(): void {
            root.setAutohide(!root.settings.bar.autohide)
        }
        function refresh(): void { root.reloadSettings() }
        function focus(): void {
            root.barExpanded = true
            keyHandler.forceActiveFocus()
        }
        function expand(): void { root.barExpanded = !root.barExpanded }
        function collapse(): void { root.barExpanded = false }
        function reload(): void { root.reloadSettings() }
    }

    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 0
    }

    readonly property int bandHeight: barHeight + 40

    readonly property int calendarReserve: calendarPanel.implicitHeight + 40
    implicitHeight: bandHeight + calendarReserve

    readonly property int hotZoneHeight: root.revealed
        ? Math.max(3, Math.round(pill.y))
        : 3

    readonly property int pillTop: Math.max(0, Math.round(pill.y))

    readonly property int calendarTop: Math.max(0, Math.round(calendarPanel.y))

    readonly property bool barTakesInput: root.barEnabled

    mask: Region {
        Region {
            x: 0
            y: 0
            width: (root.autohide || !root.barTakesInput) ? 0 : root.width
            height: (root.autohide || !root.barTakesInput) ? 0 : root.bandHeight
        }
        Region {
            x: Math.round(pill.x)
            y: root.pillTop
            width: (root.autohide && root.barTakesInput) ? Math.round(pill.width) : 0
            height: (root.autohide && root.barTakesInput)
                ? Math.max(0, Math.round(pill.y + pill.height) - root.pillTop)
                : 0
        }
        Region {
            x: 0
            y: 0
            width: (root.autohide && root.barTakesInput) ? root.width : 0
            height: (root.autohide && root.barTakesInput) ? root.hotZoneHeight : 0
        }
        Region {
            x: Math.round(calendarPanel.x)
            y: root.calendarTop
            width: root.calendarOpen ? Math.round(calendarPanel.width) : 0
            height: root.calendarOpen
                ? Math.max(0, Math.round(calendarPanel.y + calendarPanel.height)
                    - root.calendarTop)
                : 0
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.calendarOpen
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.calendarOpen = false
    }

    Item {
        id: pill
        visible: root.barEnabled
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: revealedOffset + revealShift

        readonly property real revealedOffset:
            (root.reservedHeight / 2) - (root.implicitHeight / 2)
        readonly property real hiddenOffset:
            3 - height - (root.implicitHeight - height) / 2

        property real revealShift: root.revealed
            ? 0
            : (hiddenOffset - revealedOffset)

        Behavior on revealShift {
            NumberAnimation {
                duration: root.settings.pill.animationDuration
                easing.type: Easing.OutQuint
            }
        }

        property bool expanded: hoverHandler.hovered || root.barExpanded
            || root.alwaysExpanded || root.trayMenuOpen
            || (root.autohide && root.pointerHeld)
        property real collapsedWidth: root.settings.pill.collapsedWidth > 0
            ? root.settings.pill.collapsedWidth
            : centerArea.implicitWidth + 32

        property real contentWidth: centerArea.implicitWidth
            + 2 * Math.max(leftArea.implicitWidth, rightArea.implicitWidth)
            + 64
        property real expandedWidth: Math.max(
            root.settings.pill.expandedWidth, contentWidth)

        width: expanded ? expandedWidth : collapsedWidth
        height: expanded ? root.barHeight + 10 : root.barHeight

        Behavior on width {
            NumberAnimation {
                duration: root.settings.pill.animationDuration
                easing.type: Easing.OutQuint
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: root.settings.pill.animationDuration
                easing.type: Easing.OutQuint
            }
        }

        HoverHandler {
            id: hoverHandler
        }

        FocusScope {
            id: keyHandler
            anchors.fill: parent
            focus: root.barExpanded
            Keys.onLeftPressed: root.moveFocus(-1)
            Keys.onRightPressed: root.moveFocus(1)
            Keys.onUpPressed: root.stepFocused(1)
            Keys.onDownPressed: root.stepFocused(-1)
            Keys.onReturnPressed: root.activateFocused()
            Keys.onEnterPressed: root.activateFocused()
            Keys.onEscapePressed: {
                if (root.calendarOpen)
                    root.calendarOpen = false
                else
                    root.barExpanded = false
            }
        }

        RectangularShadow {
            anchors.fill: pillBg
            radius: pillBg.radius
            blur: 15
            color: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.4 * pillBg.opacity)
        }

        Rectangle {
            id: pillBg
            anchors.fill: parent
            radius: root.settings.pill.radius
            opacity: pill.expanded
                ? root.settings.opacity.expanded
                : root.settings.opacity.collapsed
            Behavior on opacity {
                NumberAnimation {
                    duration: root.settings.pill.animationDuration
                    easing.type: Easing.OutQuint
                }
            }

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: root.settings.border.colorTop !== ""
                        ? root.settings.border.colorTop
                        : Theme.primary
                }
                GradientStop {
                    position: 1.0
                    color: root.settings.border.colorBottom !== ""
                        ? root.settings.border.colorBottom
                        : Theme.on_primary
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: root.settings.border.width
                radius: parent.radius - anchors.margins
                color: Theme.background
            }
        }

        RowLayout {
            id: leftArea
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.settings.pill.spacing

            opacity: pill.expanded ? 1 : 0
            visible: opacity > 0
            enabled: pill.expanded

            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
            }

            Repeater {
                id: leftRepeater
                model: root.settings.modules.left
                Loader {
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: root.moduleComponents[modelData] || null
                    onLoaded: Qt.callLater(root.rebuildNavItems)
                }
            }
        }

        RowLayout {
            id: centerArea
            anchors.centerIn: parent
            spacing: root.settings.pill.spacing

            Repeater {
                id: centerRepeater
                model: root.settings.modules.center
                Loader {
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: root.moduleComponents[modelData] || null
                    onLoaded: Qt.callLater(root.rebuildNavItems)
                }
            }
        }

        RowLayout {
            id: rightArea
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.settings.pill.spacing

            opacity: pill.expanded ? 1 : 0
            visible: opacity > 0
            enabled: pill.expanded

            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
            }

            Repeater {
                id: rightRepeater
                model: root.settings.modules.right
                Loader {
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: root.moduleComponents[modelData] || null
                    visible: (item && item.collapsed !== undefined) ? !item.collapsed : true
                    onLoaded: Qt.callLater(root.rebuildNavItems)
                }
            }
        }
    }

    CalendarPanel {
        id: calendarPanel

        isOpen: root.calendarOpen

        x: {
            let holder = root.clockRef ? root.clockRef.parent : null
            if (!holder)
                return Math.round((root.width - width) / 2)
            let center = pill.x + centerArea.x + holder.x + holder.width / 2
            return Math.round(Math.max(8,
                Math.min(root.width - width - 8, center - width / 2)))
        }

        readonly property int calendarGap: 26
        openY: Math.round(pill.y + pill.height + calendarGap - cardInset)
    }
}
