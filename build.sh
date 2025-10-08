#!/usr/bin/env bash

set -e

PROJECT_NAME="dmg-osd"
BUILD_DIR="builddir"

echo "Building $PROJECT_NAME..."

# Clean previous build if requested
if [[ "$1" == "clean" ]]; then
    echo "Cleaning previous build..."
    rm -rf $BUILD_DIR
fi

# Setup build directory
if [[ ! -d "$BUILD_DIR" ]]; then
    echo "Setting up build directory..."
    meson setup $BUILD_DIR
fi

# Build the project
echo "Compiling..."
meson compile -C $BUILD_DIR

echo "Build complete!"
echo "Run with: ./$BUILD_DIR/$PROJECT_NAME"
echo ""
echo "Tips:"
echo "  - The overlay will appear when battery is below configured threshold"
echo "  - Pulsing intensity increases as battery reaches configured critical threshold"
echo "  - No overlay shown when charging"
echo "  - Ctrl+c to quit"
