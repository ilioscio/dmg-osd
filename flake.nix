{
  description = "dmg-osd - Low Battery Overlay for Wayland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # Systems we support
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      
      # Helper to generate per-system outputs
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # Package derivation (reusable across systems)
      mkDmgOsd = pkgs: pkgs.stdenv.mkDerivation {
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
        
        meta = with pkgs.lib; {
          description = "Low battery overlay for Wayland compositors";
          longDescription = ''
            A video game-inspired battery warning overlay for Wayland.
            When battery is low, screen edges pulse red like health damage
            effects in certain video games. Works with wlroots-based 
            compositors like Hyprland and Sway.
          '';
          homepage = "https://github.com/ilioscio/dmg-osd";
          license = licenses.mit;
          platforms = platforms.linux;
          maintainers = [];
          mainProgram = "dmg-osd";
        };
      };
    in
    {
      # ============================================================
      # OVERLAY - For users who want to add dmg-osd to their pkgs
      # ============================================================
      # Usage in user's flake.nix:
      #   nixpkgs.overlays = [ dmg-osd.overlays.default ];
      #   environment.systemPackages = [ pkgs.dmg-osd ];
      overlays.default = final: prev: {
        dmg-osd = mkDmgOsd final;
      };

      # ============================================================
      # PACKAGES - Direct package access per system
      # ============================================================
      # Usage: dmg-osd.packages.x86_64-linux.default
      # Or: nix build github:ilioscio/dmg-osd
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = mkDmgOsd pkgs;
          dmg-osd = mkDmgOsd pkgs;
        }
      );

      # ============================================================
      # APPS - For `nix run github:ilioscio/dmg-osd`
      # ============================================================
      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/dmg-osd";
        };
      });

      # ============================================================
      # DEV SHELLS - For contributors/developers
      # ============================================================
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
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
              libayatana-appindicator
              
              # Development tools
              gdb
              valgrind
              
              # Language server
              vala-language-server
            ];
            
            shellHook = ''
              echo "Welcome to the dmg-osd development environment!"
              echo "Low battery overlay for Wayland compositors"
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
        }
      );
    };
}
