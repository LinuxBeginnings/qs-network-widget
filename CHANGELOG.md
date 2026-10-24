# Changelog — qs-network-widget

## Added:

- Wi-Fi and Bluetooth menu for the Hyprland-Dots Waybar bar
  - Intended for the Hyprland-Dots Waybar menu
  - https://github.com/LinuxBeginnings/Hyprland-Dots
- `README.md` describing the widget and its Hyprland-Dots integration
  - States the code is alpha and specific to Hyprland-Dots
  - Records that `template/` is untested and incomplete
- `AGENTS.md` project rules, with `WARP.md` as a symlink to it
  - Changelog entries are one line, with detail as nested bullets
  - Review `../Hyprland-Dots/CHANGELOG.md` and `../Hyprland-Dots/AGENTS.md`
  - Feature scope records connecting to a network, which `template/` lacks
- `src/quickshell/.gitkeep` and `src/wallust/.gitkeep`
  - Git does not track empty directories, so `src/` never reached GitHub

## Updated:

- `wallust.toml` rewritten as a Hyprland-Dots `[templates]` block
  - The old `[[entry]]` array is invalid in both Dots wallust configs
  - The block belongs in `wallust.toml` and `wallust-v4.toml`, not one
  - Dots selects the config by wallust major version, so one leaves a gap
- `colors.json` replaced by `colors-qs-network.json`
  - Follows the Dots `colors-<app>.<ext>` template naming
  - Emits `~/.config/quickshell/qs-network-colors.json`
  - Placeholders no longer carry a doubled `#`
  - Keys follow the Dots Quickshell palette vocabulary
- `Theme.qml` reads the palette the wallust template writes
  - It pointed at a path nothing produced
  - The loader itself is a stub and still needs rewriting for Quickshell
