{
  description = "dmg-osd - Battery Damage Overlay for Wayland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        dmg-osd = pkgs.stdenv.mkDerivation {
          pname = "dmg-osd";
          version = "0.1.0";
          
          src = ./.;
          
          nativeBuildInputs = with pkgs; [
            vala
            pkg-config
            meson
            ninja
          ];
          
          buildInputs = with pkgs; [
            gtk4
            glib
            gobject-introspection
            gtk4-layer-shell
          ];
          
          mesonFlags = [
            "-Doptimization=2"
          ];
        };
        
      in
      {
        packages = {
          default = dmg-osd;
          dmg-osd = dmg-osd;
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Build tools
            vala
            pkg-config
            meson
            ninja
            
            # GTK and layer-shell for Wayland
            gtk4
            glib
            gobject-introspection
            gtk4-layer-shell
            upower
            
            # Development tools
            gdb
            valgrind
            
            # Language server
            vala-language-server
          ];
          
          shellHook = ''
            echo "🩸 Welcome to the dmg-osd development environment!"
            echo "Battery damage overlay for Wayland compositors"
            echo ""
            echo "Available commands:"
            echo "  meson setup builddir       - Setup build directory"
            echo "  meson compile -C builddir  - Build the project"
            echo "  ./builddir/dmg-osd         - Run the application"
            echo ""
            echo "Vala version: $(valac --version)"
            echo "GTK version: $(pkg-config --modversion gtk4)"
            echo "Layer Shell: $(pkg-config --modversion gtk4-layer-shell-0)"
          '';
        };
      });
}
