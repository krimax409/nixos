---
name: easycliproxyapi-webkitgtk-dpi
description: Use when EasyCLIProxyAPI on NixOS with Niri/Wayland opens with the title bar at normal size but its WebKit GUI is uniformly tiny (about 0.2 zoom), especially when GDK_SCALE changes do not help.
license: MIT
metadata:
  author: Krimax0
  version: "1.0"
---

# EasyCLIProxyAPI WebKitGTK DPI fix

This captures the verified NixOS/Niri workaround for the EasyCLIProxyAPI Tauri/WebKitGTK rendering bug.

**Failure pattern:** GTK cannot discover any GSettings schema in the NixOS service environment; WebKitGTK receives an invalid DPI/device-pixel-ratio and renders the entire WebView at roughly 0.2 scale while the native title bar remains normal.
**Verified by:** `sudo nixos-rebuild switch --flake /home/k/src/nixos-config#desktop`, a restarted `easycliproxyapi.service`, and a fresh desktop screenshot showing normal navigation, cards, text, and controls.

## When to use this

Use this when the GUI is not crashed but all HTML content is uniformly miniature, the Niri output scale is `1`, and the window itself occupies the expected size.

## Procedure

1. Edit `modules/home/packages/gui.nix` and set the user service environment to the GSettings schema path:

   ```nix
   Environment = [
     "GSETTINGS_SCHEMA_DIR=${pkgs.glib.getSchemaPath pkgs.gsettings-desktop-schemas}"
   ];
   ```

2. Keep the service ordered after the graphical session. The existing five-second delay can remain as a startup race mitigation, but it is not the DPI fix.

3. Apply the configuration and restart the service:

   ```bash
   sudo nixos-rebuild switch --flake /home/k/src/nixos-config#desktop
   systemctl --user restart easycliproxyapi.service
   ```

4. Verify the environment and service before judging the screen:

   ```bash
   systemctl --user show easycliproxyapi.service -p Environment
   systemctl --user is-active easycliproxyapi.service
   ```

   The environment must contain `GSETTINGS_SCHEMA_DIR` ending in `glib-2.0/schemas`, and the service must be `active`.

5. Capture or inspect the actual EasyCLIProxyAPI window. Confirm that the WebView content, not only the title bar, is normal-sized.

## Gotchas

- The schema path must be supplied to the EasyCLIProxyAPI user service, not only to an interactive shell; systemd user services do not automatically inherit the shell's Nix environment.
- Use `pkgs.glib.getSchemaPath pkgs.gsettings-desktop-schemas`; do not hard-code a `/nix/store` path.
- This fix does not require deleting `~/.local/share/easycliproxyapi/payload`; OAuth files live under `payload/oauth` and should be preserved.
- A clean `~/.local/share/com.cpa.gui` WebKit profile does not fix this missing-schema bug by itself. Back it up before any profile reset if investigating other UI state.
- The upstream symptom is documented in [Tauri issue #5600](https://github.com/tauri-apps/tauri/issues/5600), including the observation that `GDK_SCALE` and `GDK_DPI_SCALE` do not solve it.

## What didn't work

- Adding only `GDK_SCALE=1`, `GDK_DPI_SCALE=1`, or `GTK_SCALE=1` did not change the tiny WebView because the failure occurs before WebKitGTK gets a valid DPI from GTK settings.
- Deleting or recreating `~/.local/share/com.cpa.gui` did not fix the rendering; it only resets WebKit profile state.
- Increasing the `sleep 5` delay is not a root-cause fix. It may change startup timing but does not provide the missing GSettings schema.
