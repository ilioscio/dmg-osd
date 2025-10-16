# dmg-osd

A low battery overlay for Wayland compositors inspired by classic video game health indicators. Your screen pulses red when battery is low.

## Demo

Default low battery:
<video src='https://github.com/user-attachments/assets/c35754d5-26a9-4da4-a929-c6309cae2501' width=180/>

Critical battery:
<video src='https://github.com/user-attachments/assets/34d0117c-fbfc-46d0-acca-96ab1005f483' width=180/>

## Features

- **Wayland Native**: Uses GTK4 Layer Shell for proper overlay rendering
- **Always On Top**: Stays above fullscreen windows using the overlay layer
- **Battery Aware**: Monitors battery via UPower through DBus
- **Configurable**: Battery thresholds, colors, pulse rates, intensity
- **Smart Behavior**: Automatically hides when charging
- **Hot-Reload Configuration**: Send linux signals to reload your config

## Requirements

- NixOS (or Nix package manager) *Or see note below
- Wayland compositor (tested on Hyprland)
- Battery-powered device (duh)

Note: Non-Nix users see BUILD.md for instructions on building with traditional package managers on Debian, Ubuntu, Arch Linux, and Fedora.

## Building

### Development Environment

Enter the Nix development shell:

```bash
nix develop
```

### Build

Use the provided build script:

```bash
./build.sh
```

Clean build:

```bash
./build.sh clean
```

### Run

```bash
./builddir/dmg-osd
```

## Usage

### Running

The overlay runs in the background and automatically shows when battery drops below warning threshold:

Press `Ctrl+c` to quit.

### Autostart

Add to your Hyprland config:

```
exec-once = dmg-osd
```

Or create a systemd user service (not recommended unless you know what you're doing):

```ini
[Unit]
Description=Battery Damage Overlay
After=graphical-session.target

[Service]
ExecStart=/path/to/dmg-osd
Restart=on-failure

[Install]
WantedBy=default.target
```

## Configuration

User config will be loaded if it is found in either ~/.config/dmg-osd/dmg-osd.config or ./dmg-osd.config with the former taking priority.

An example config is provided with defaults.

## Hot-reload Configuration
To reload your configuration changes without restarting dmg-osd, just send either a SIGHUP or USR1 linux signal, you can use the posix kill command for this, but you will need the process id of dmg-osd to use it. 

```
kill -s hup <dmg-osd pid>
```
It's easier to use pkill, if you have it installed because you won't need dmg-osd's process id.

```
pkill -HUP dmg-osd
```

## Project Structure

```
dmg-osd/
├── flake.nix           # Nix flake with dependencies
├── meson.build         # Meson build configuration
├── build.sh            # Build script
├── src/
│   ├── main.vala               # Entry point
│   ├── application.vala        # GTK Application
│   ├── overlay_window.vala     # Wayland overlay window
│   ├── battery_monitor.vala    # Battery monitoring via UPower using DBus
│   ├── config.vala             # Application configuration
│   └── dmg-osd.config.example  # Example configuration file
├── README.md
└── BUILD.md                    # Build information for different distros.
```

## Compatibility

Tested on:
- Hyprland
- Sway (should work)
- Other wlroots-based compositors (should work)

Requires compositor support for:
- `wlr-layer-shell-unstable-v1` protocol
- Overlay layer

## Troubleshooting

### Overlay not showing
- Check if battery device is detected: Look for "Found battery device" message
- Verify battery is below threshold and not charging
- Ensure compositor supports layer-shell protocol

### Permission issues
- UPower access should work without special permissions
- If issues persist, check D-Bus permissions

## License

MIT

## Authors
[ilioscio](https://github.com/ilioscio)

claude.ai
