# Battery Alert

A macOS menu bar app that shows a notch-style alert when the battery reaches 2% or 1%, plus a brief charging indicator when power is connected.

Click an alert to dismiss it. The menu bar menu includes alert previews and a Launch at Login option.

## Build and run

Requires macOS 26 or later and an installed Swift 6 toolchain with the macOS SDK. Complete Xcode's initial setup and license acceptance before building.

```sh
./build-app.sh
open "Battery Alert.app"
```

The build script creates an ad-hoc signed app bundle. The first launch may require right-clicking the app and choosing Open.

## Project layout

- `Sources/BatteryAlert/`: app, battery monitoring, and alert UI.
- `Package.swift`: Swift package definition.
- `build-app.sh` and `Info.plist`: app bundle packaging.
- `AppIcon.icns`, `AppIcon.iconset/`, `icon_master.png`, and `make_icon.swift`: icon assets and generator.

Generated build files and app bundles are excluded from the repository.
