---
name: iOS deploy pipeline
description: How to deploy Gravity Flip to the user's paired iPhone after Godot script changes
type: reference
originSessionId: 81f843f2-db11-4d20-9cfc-764d94a96cda
---
Pipeline for deploying to the user's iPhone 13 Pro (device id `B7CC8868-E918-5043-A37E-32AC17F755E7`, paired and available via `xcrun devicectl list devices`):

1. Re-export the Godot pack so script changes are picked up:
   `godot --headless --export-pack "iOS" "Gravity Flip.pck"` (run from project root)
2. Build for the device:
   `xcodebuild -project "Gravity Flip.xcodeproj" -scheme "Gravity Flip" -configuration Debug -destination "id=<device-id>" -allowProvisioningUpdates build`
3. Install:
   `xcrun devicectl device install app --device <device-id> "<DerivedData>/Build/Products/Debug-iphoneos/Gravity Flip.app"`
4. Launch:
   `xcrun devicectl device process launch --device <device-id> com.jfun.gravityflip`

Bundle id: `com.jfun.gravityflip`. Team id: `N9DH28SYTB` (set in `export_presets.cfg`). The Xcode project lives at the repo root alongside the .pck — do not regenerate it from Godot, just refresh the .pck in place.
