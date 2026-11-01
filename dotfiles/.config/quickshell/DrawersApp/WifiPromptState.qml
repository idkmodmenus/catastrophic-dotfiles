pragma Singleton

import QtQuick

// Hands a Wi-Fi network from the bar popout to the password drawer
QtObject {
    id: state

    // Network waiting for a password, or null
    property var network: null
    signal requested()

    function request(net): void {
        if (!net) return
        state.network = net
        requested()
    }
}
