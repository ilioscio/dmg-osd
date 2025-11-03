using Gtk;

namespace DmgOsd {
    public class DmgOsdApplication : Gtk.Application {
        private OverlayWindow? overlay_window = null;
        private BatteryMonitor? battery_monitor = null;
        private Config config;
        private SettingsWindow? settings_window = null;
        private bool gui_mode = false;
        
        public DmgOsdApplication() {
            Object(application_id: "com.github.dmg-osd",
                   flags: ApplicationFlags.HANDLES_COMMAND_LINE);
            config = new Config();
        }
        
        protected override int command_line(ApplicationCommandLine command_line) {
            string[] args = command_line.get_arguments();
            
            // Parse command line arguments
            for (int i = 1; i < args.length; i++) {
                if (args[i] == "-g" || args[i] == "--gui") {
                    gui_mode = true;
                } else if (args[i] == "-h" || args[i] == "--help") {
                    print_help();
                    return 0;
                }
            }
            
            activate();
            return 0;
        }
        
        private void print_help() {
            print("dmg-osd - Battery Damage Overlay\n\n");
            print("Usage: dmg-osd [OPTIONS]\n\n");
            print("Options:\n");
            print("  -g, --gui     Launch with settings GUI\n");
            print("  -h, --help    Show this help message\n\n");
            print("Signals:\n");
            print("  SIGHUP, SIGUSR1  Reload configuration\n\n");
            print("Keyboard shortcuts:\n");
            print("  Ctrl+c        Quit application\n");
        }
        
        protected override void activate() {
            // Always create overlay window for damage effect
            if (overlay_window == null) {
                overlay_window = new OverlayWindow(this, config);
            }
            
            // Start battery monitoring
            if (battery_monitor == null) {
                battery_monitor = new BatteryMonitor(config);
                battery_monitor.battery_level_changed.connect(on_battery_changed);
            }
            
            // Set up signal handlers for config reload
            setup_signal_handlers();
            
            // Present the overlay window
            overlay_window.present();
            
            // If GUI mode, create and show settings window
            if (gui_mode) {
                if (settings_window == null) {
                    settings_window = new SettingsWindow(this, config);
                    settings_window.config_saved.connect(on_config_saved);
                    settings_window.close_request.connect(() => {
                        // When window is closed in GUI mode, quit the app
                        quit();
                        return false;
                    });
                }
                settings_window.present();
            }
        }
        
        protected override void startup() {
            base.startup();
            
            // Set up quit action
            var quit_action = new SimpleAction("quit", null);
            quit_action.activate.connect(() => {
                quit();
            });
            add_action(quit_action);
            set_accels_for_action("app.quit", {"<Control>q"});
            
            // Set up reload action
            var reload_action = new SimpleAction("reload", null);
            reload_action.activate.connect(() => {
                reload_config();
            });
            add_action(reload_action);
            set_accels_for_action("app.reload", {"<Control>r"});
            
            // Set up show settings action
            var settings_action = new SimpleAction("settings", null);
            settings_action.activate.connect(() => {
                show_settings();
            });
            add_action(settings_action);
        }
        
        public void show_settings() {
            if (settings_window == null) {
                settings_window = new SettingsWindow(this, config);
                settings_window.config_saved.connect(on_config_saved);
            }
            settings_window.present();
        }
        
        private void setup_signal_handlers() {
            // Handle SIGHUP (traditional reload signal)
            Unix.signal_add(Posix.Signal.HUP, () => {
                print("Received SIGHUP\n");
                reload_config();
                return Source.CONTINUE;
            });
            
            // Handle SIGUSR1 (alternative reload signal)
            Unix.signal_add(Posix.Signal.USR1, () => {
                print("Received SIGUSR1\n");
                reload_config();
                return Source.CONTINUE;
            });
        }
        
        private void reload_config() {
            print("Reloading configuration...\n");
            
            // Reload config values
            config.reload();
            
            // Force battery check to update with new thresholds
            if (battery_monitor != null) {
                battery_monitor.force_check();
            }
            
            // Update settings window if open
            if (settings_window != null) {
                settings_window.refresh_from_config();
            }
            
            print("Configuration reloaded\n");
        }
        
        private void on_config_saved() {
            // Config values already updated in memory, just force battery check with new thresholds
            if (battery_monitor != null) {
                battery_monitor.force_check();
            }
        }
        
        private void on_battery_changed(double percentage, bool is_charging, BatteryState state) {
            if (overlay_window != null) {
                overlay_window.update_damage_effect(percentage, is_charging, state);
            }
        }
    }
}
