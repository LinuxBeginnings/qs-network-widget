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

    // Path written by the wallust template in template/wallust/wallust.toml.
    // It is under ~/.config/quickshell/ because that is where Hyprland-Dots
    // already keeps its Quickshell palette; the widget does not get its own dir.
    readonly property string colorsPath:
        Quickshell.env("HOME") + "/.config/quickshell/qs-network-colors.json"

    // Watch the wallust generated json file
    property FileWatch watcher: FileWatch {
        path: theme.colorsPath
        onFileChanged: theme.loadColors()
    }

    Component.onCompleted: loadColors()

    // NOTE: XMLHttpRequest cannot read file:// URLs in Quickshell, and the
    // FileWatch above is the only thing this sketch got right. Replace this
    // function with Quickshell.Io FileView + JsonObject when the real theme
    // loader is written into src/quickshell/.
    function loadColors() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + theme.colorsPath);
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
