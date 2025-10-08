# dmg-osd

A low battery overlay for Wayland compositors inspired by classic video game health indicators. Your screen pulses red when battery is low.

## Demo

Default low battery:
![dmg-osd-low-battery-demo](https://github.com/user-attachments/assets/c35754d5-26a9-4da4-a929-c6309cae2501)

Critical battery:
![dmg-osd-critical-battery-demo](https://github.com/user-attachments/assets/34d0117c-fbfc-46d0-acca-96ab1005f483)


## Features

- **Wayland Native**: Uses GTK4 Layer Shell for proper overlay rendering
- **Always On Top**: Stays above fullscreen windows using the overlay layer
- **Battery Aware**: Monitors battery via UPower
- **Configurable Thresholds**:
  - Low: ≤30% (slow red pulse)
  - Critical: ≤15% (faster red pulse)
- **Smart Behavior**: Automatically hides when charging
- **Smooth Animations**: Pulsing effect with configurable intensity

## Requirements

- NixOS (or Nix package manager) *See note below
- Wayland compositor (tested on Hyprland)
- Battery-powered device

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

Or create a systemd user service:

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

## How It Works

1. **Battery Monitoring**: Uses UPower via DBus to track battery percentage and charging state
2. **Layer Shell**: GTK4 Layer Shell protocol places window on overlay layer (above all windows)
3. **Click-Through**: Window doesn't intercept input, allowing interaction with apps beneath
4. **Smooth Animation**: Cairo drawing with sine-wave pulsing effect
5. **Smart Visibility**: Only shows when on battery power and below threshold

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

Ilios
Claude
