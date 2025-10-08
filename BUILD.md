# Building dmg-osd without Nix

This guide explains how to build dmg-osd on various Linux distributions without using Nix.

Much of this information is currently *untested* but it should work in theory, please let me know in the issues if you encounter any nessesary changes to these instructions.

## Prerequisites

dmg-osd requires the following dependencies:
- Vala compiler
- Meson build system
- Ninja build tool
- GTK4
- GLib 2.0
- GObject Introspection
- GTK4 Layer Shell
- pkg-config

## Debian / Ubuntu

### Install Dependencies

```bash
# Update package lists
sudo apt update

# Install build tools
sudo apt install -y \
    valac \
    meson \
    ninja-build \
    pkg-config

# Install GTK4 and related libraries
sudo apt install -y \
    libgtk-4-dev \
    libglib2.0-dev \
    libgirepository1.0-dev \
    gtk4-layer-shell-dev
```

**Note for Ubuntu users:** If `gtk4-layer-shell-dev` is not available in your repositories, you may need to enable the universe repository or build gtk4-layer-shell from source (see below).

### Build

```bash
# Navigate to project directory
cd dmg-osd

# Setup build directory
meson setup builddir

# Compile
meson compile -C builddir

# Run
./builddir/dmg-osd
```

### Install (Optional)

```bash
sudo meson install -C builddir
```

This will install dmg-osd to `/usr/local/bin/`.

---

## Arch Linux

### Install Dependencies

```bash
# Install all required packages
sudo pacman -S \
    vala \
    meson \
    ninja \
    gtk4 \
    glib2 \
    gobject-introspection \
    gtk4-layer-shell \
    pkgconf
```

### Build

```bash
# Navigate to project directory
cd dmg-osd

# Setup build directory
meson setup builddir

# Compile
meson compile -C builddir

# Run
./builddir/dmg-osd
```

### Install (Optional)

```bash
sudo meson install -C builddir
```

---

## Fedora

### Install Dependencies

```bash
# Install all required packages
sudo dnf install -y \
    vala \
    meson \
    ninja-build \
    gtk4-devel \
    glib2-devel \
    gobject-introspection-devel \
    gtk4-layer-shell-devel \
    pkgconfig
```

### Build

```bash
# Navigate to project directory
cd dmg-osd

# Setup build directory
meson setup builddir

# Compile
meson compile -C builddir

# Run
./builddir/dmg-osd
```

---

## Building GTK4 Layer Shell from Source

If your distribution doesn't provide gtk4-layer-shell, you can build it from source:

```bash
# Install additional build dependencies
# Debian/Ubuntu:
sudo apt install -y git libwayland-dev wayland-protocols

# Arch:
sudo pacman -S git wayland wayland-protocols

# Clone the repository
git clone https://github.com/wmww/gtk4-layer-shell.git
cd gtk4-layer-shell

# Build and install
meson setup build
meson compile -C build
sudo meson install -C build

# Update library cache
sudo ldconfig

# Return to dmg-osd directory
cd ..
```

---

## Troubleshooting

### "Package 'gtk4-layer-shell-0' not found"

If you get this error, gtk4-layer-shell is not installed. Either:
1. Check if your distribution provides it in a different package name
2. Build it from source (see above)

### "valac: command not found"

Install the Vala compiler:
```bash
# Debian/Ubuntu
sudo apt install valac

# Arch
sudo pacman -S vala

# Fedora
sudo dnf install vala
```

### GTK4 not found

Ensure you have GTK4 development files:
```bash
# Debian/Ubuntu
sudo apt install libgtk-4-dev

# Arch
sudo pacman -S gtk4

# Fedora
sudo dnf install gtk4-devel
```

### Permission errors when running

dmg-osd needs to access UPower over D-Bus, which should work without special permissions. If you encounter issues, ensure your user is in the appropriate groups (usually automatic on modern distributions).

---

## Running dmg-osd

### Manual Run
```bash
./builddir/dmg-osd
```

### Autostart with Hyprland
Add to your `~/.config/hypr/hyprland.conf`:
```
exec-once = dmg-osd
```

### Autostart with Sway
Add to your `~/.config/sway/config`:
```
exec dmg-osd
```

### Systemd User Service (not recommended unless you know what you're doing)
Create `~/.config/systemd/user/dmg-osd.service`:
```ini
[Unit]
Description=Battery Damage Overlay
After=graphical-session.target

[Service]
ExecStart=/usr/local/bin/dmg-osd
Restart=on-failure

[Install]
WantedBy=default.target
```

Enable and start:
```bash
systemctl --user enable dmg-osd.service
systemctl --user start dmg-osd.service
```

---

## Configuration

Create a config file at `~/.config/dmg-osd/dmg-osd.config`:

```bash
mkdir -p ~/.config/dmg-osd
nano ~/.config/dmg-osd/dmg-osd.config
```

See `dmg-osd.config.example` in the repository for available options.

---

## Uninstall

If you installed using `meson install`:
```bash
cd dmg-osd
sudo ninja -C builddir uninstall
```

Or manually:
```bash
sudo rm /usr/local/bin/dmg-osd
```
