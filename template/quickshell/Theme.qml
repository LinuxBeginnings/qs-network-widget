pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: theme

    property color bg: "#1e1e2e"
    property color fg: "#cdd6f4"
    property color primary: "#89b4fa"
    property color active: "#a6e3a1"
    property color alert: "#f38ba8"
    property color surface: "#313244"

    // Watch the wallust generated json file
    property FileWatch watcher: FileWatch {
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        onFileChanged: theme.loadColors()
    }

    Component.onCompleted: loadColors()

    function loadColors() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + Quickshell.env("HOME") + "/.config/quickshell/colors.json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var c = JSON.parse(xhr.responseText);
                    theme.bg = c.background;
                    theme.fg = c.foreground;
                    theme.primary = c.color4;
                    theme.active = c.color2;
                    theme.alert = c.color1;
                    theme.surface = c.color0;
                } catch(e) {}
            }
        }
        xhr.send();
    }
}
