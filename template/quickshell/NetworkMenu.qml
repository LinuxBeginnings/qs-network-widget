import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root

    // LayerShell overlay positioning (Top-right flyout)
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        right: true
    }
    margins {
        top: 10
        right: 12
    }

    implicitWidth: 380
    implicitHeight: mainLayout.implicitHeight + 24
    color: "transparent"

    // --- State Properties ---
    property bool wifiEnabled: true
    property bool btEnabled: true
    property bool airplaneMode: false

    property string rxRate: "0 KB/s"
    property string txRate: "0 KB/s"
    property var lastRx: 0
    property var lastTx: 0

    property var wifiNetworks: []
    property var btDevices: []

    // Background Container
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.bg
        border.color: Theme.surface
        border.width: 1

        ColumnLayout {
            id: mainLayout
            anchors {
                fill: parent
                margins: 14
            }
            spacing: 12

            // Top Quick Toggles
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Wi-Fi Toggle
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 8
                    color: root.wifiEnabled ? Theme.primary : Theme.surface
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var cmd = root.wifiEnabled ? "off" : "on";
                            Quickshell.execDetached(["nmcli", "radio", "wifi", cmd]);
                            root.wifiEnabled = !root.wifiEnabled;
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: (root.wifiEnabled ? "󰖩 " : "󰖪 ") + "Wi-Fi"
                        color: root.wifiEnabled ? Theme.bg : Theme.fg
                        font.bold: true
                    }
                }

                // Bluetooth Toggle
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 8
                    color: root.btEnabled ? Theme.primary : Theme.surface
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var cmd = root.btEnabled ? "power off" : "power on";
                            Quickshell.execDetached(["sh", "-c", "bluetoothctl " + cmd]);
                            root.btEnabled = !root.btEnabled;
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: (root.btEnabled ? "󰂯 " : "󰂲 ") + "Bluetooth"
                        color: root.btEnabled ? Theme.bg : Theme.fg
                        font.bold: true
                    }
                }

                // Airplane Mode
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 8
                    color: root.airplaneMode ? Theme.alert : Theme.surface
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var state = !root.airplaneMode;
                            var cmd = state ? "block all" : "unblock all";
                            Quickshell.execDetached(["rfkill", state ? "block" : "unblock", "all"]);
                            root.airplaneMode = state;
                            if (state) {
                                root.wifiEnabled = false;
                                root.btEnabled = false;
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "󰀝 Airplane"
                        color: root.airplaneMode ? Theme.bg : Theme.fg
                        font.bold: true
                    }
                }
            }

            // Network Activity Rate Bar
            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 6
                color: Theme.surface

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    Text {
                        text: "  " + root.rxRate
                        color: Theme.active
                        font.pointSize: 9
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "  " + root.txRate
                        color: Theme.primary
                        font.pointSize: 9
                    }
                }
            }

            // Wi-Fi Available Networks Header
            Text {
                text: "Available Wireless Networks"
                color: Theme.fg
                font.bold: true
                font.pointSize: 10
            }

            // Wi-Fi List
            ListView {
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, 130)
                clip: true
                model: root.wifiNetworks
                spacing: 4

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 28
                    radius: 4
                    color: modelData.inUse ? Theme.surface : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        Text {
                            text: modelData.inUse ? "󰤨" : "󰤥"
                            color: modelData.inUse ? Theme.active : Theme.fg
                        }
                        Text {
                            text: modelData.ssid
                            color: Theme.fg
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.signal + "%"
                            color: Theme.fg
                            opacity: 0.6
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // Connect using nmcli
                            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", modelData.ssid]);
                        }
                    }
                }
            }

            // Bluetooth Connected / Available Section
            Text {
                text: "Bluetooth Devices"
                color: Theme.fg
                font.bold: true
                font.pointSize: 10
            }

            ListView {
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, 100)
                clip: true
                model: root.btDevices
                spacing: 4

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 28
                    radius: 4
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        Text {
                            text: "󰂱"
                            color: modelData.connected ? Theme.active : Theme.fg
                        }
                        Text {
                            text: modelData.name
                            color: Theme.fg
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        // Battery display (if reported via bluez)
                        Text {
                            visible: modelData.battery !== ""
                            text: "󰁹 " + modelData.battery + "%"
                            color: Theme.active
                            font.pointSize: 9
                        }
                        // RSSI Signal indicator
                        Text {
                            visible: modelData.rssi !== ""
                            text: modelData.rssi + " dBm"
                            color: Theme.fg
                            opacity: 0.6
                            font.pointSize: 8
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var action = modelData.connected ? "disconnect" : "connect";
                            Quickshell.execDetached(["bluetoothctl", action, modelData.mac]);
                        }
                    }
                }
            }
        }
    }

    // --- Backend Polling Handlers ---

    // 1. Poller Timer
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiPoll.running = true;
            btPoll.running = true;
            rfkillPoll.running = true;
        }
    }

    // 2. High frequency network throughput poller
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: netRatePoll.running = true
    }

    // 3. Scan Wi-Fi via nmcli
    Process {
        id: wifiPoll
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var list = [];
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue;
                    var parts = lines[i].split(":");
                    var inUse = parts[0] === "*";
                    var ssid = parts[1];
                    var signal = parts[2];
                    if (ssid && ssid.length > 0) {
                        list.push({ inUse: inUse, ssid: ssid, signal: signal });
                    }
                }
                root.wifiNetworks = list;
            }
        }
    }

    // 4. Query Bluetooth Devices (paired, connected, battery, RSSI)
    Process {
        id: btPoll
        command: [
            "sh", "-c",
            "bluetoothctl devices | while read -r _ mac name; do " +
            "info=$(bluetoothctl info \"$mac\"); " +
            "conn=$(echo \"$info\" | grep 'Connected: yes'); " +
            "batt=$(echo \"$info\" | awk -F'[(%)]' '/Battery Percentage/{print $2}'); " +
            "rssi=$(echo \"$info\" | awk '/RSSI:/{print $2}'); " +
            "echo \"$mac|$name|$conn|$batt|$rssi\"; done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var list = [];
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue;
                    var p = lines[i].split("|");
                    list.push({
                        mac: p[0],
                        name: p[1] || p[0],
                        connected: p[2] !== "",
                        battery: p[3] || "",
                        rssi: p[4] || ""
                    });
                }
                root.btDevices = list;
            }
        }
    }

    // 5. Query Network Traffic from /proc/net/dev
    Process {
        id: netRatePoll
        command: [
            "sh", "-c",
            "awk 'NR>2 {rx+=$2; tx+=$10} END {print rx, tx}' /proc/net/dev"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(" ");
                if (parts.length >= 2) {
                    var currentRx = parseInt(parts[0]);
                    var currentTx = parseInt(parts[1]);

                    if (root.lastRx !== 0) {
                        var diffRx = (currentRx - root.lastRx) / 1024; // KB
                        var diffTx = (currentTx - root.lastTx) / 1024; // KB

                        root.rxRate = diffRx > 1024 ? (diffRx / 1024).toFixed(1) + " MB/s" : diffRx.toFixed(0) + " KB/s";
                        root.txRate = diffTx > 1024 ? (diffTx / 1024).toFixed(1) + " MB/s" : diffTx.toFixed(0) + " KB/s";
                    }

                    root.lastRx = currentRx;
                    root.lastTx = currentTx;
                }
            }
        }
    }

    // 6. Check Global RFKill state
    Process {
        id: rfkillPoll
        command: ["rfkill", "list", "-n", "-o", "TYPE,SOFT"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var wBlocked = false;
                var bBlocked = false;
                for (var i = 0; i < lines.length; i++) {
                    var cols = lines[i].split(/\s+/);
                    if (cols[0] === "wlan" && cols[1] === "blocked") wBlocked = true;
                    if (cols[0] === "bluetooth" && cols[1] === "blocked") bBlocked = true;
                }
                root.wifiEnabled = !wBlocked;
                root.btEnabled = !bBlocked;
                root.airplaneMode = (wBlocked && bBlocked);
            }
        }
    }
}
