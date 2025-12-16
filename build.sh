#!/usr/bin/env sh

set -e

echo "Building dmg-osd..."

# Clean if requested
if [ "$1" = "clean" ]; then
    echo "Cleaning previous build..."
    rm -rf builddir
fi

# Setup build directory
if [ ! -d "builddir" ]; then
    echo "Setting up build directory..."
    meson setup builddir
fi

echo "Compiling..."
meson compile -C builddir

echo ""
echo "Build complete!"
echo "Run with: ./builddir/dmg-osd"
echo ""
echo "Tips:"
echo "  - The overlay will appear when battery is below configured threshold"
echo "  - Pulsing intensity increases as battery reaches configured critical threshold"
echo "  - No overlay shown when charging"
echo "  - Ctrl+c to quit"
