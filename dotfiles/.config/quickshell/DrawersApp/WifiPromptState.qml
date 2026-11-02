pragma Singleton

import QtQuick

QtObject {
    id: state

    property var network: null
    signal requested()

    function request(net): void {
        if (!net) return
        state.network = net
        requested()
    }
}
