using Gtk;

namespace DmgOsd {
    public class DmgOsdApplication : Gtk.Application {
        private OverlayWindow? overlay_window = null;
        private BatteryMonitor? battery_monitor = null;
        private Config config;
        
        public DmgOsdApplication() {
            Object(application_id: "com.github.dmg-osd",
                   flags: ApplicationFlags.DEFAULT_FLAGS);
            config = new Config();
        }
        
        protected override void activate() {
            // Create overlay window if it doesn't exist
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
            
            // Present the window
            overlay_window.present();
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
            
            print("Configuration reloaded\n");
        }
        
        private void on_battery_changed(double percentage, bool is_charging, BatteryState state) {
            if (overlay_window != null) {
                overlay_window.update_damage_effect(percentage, is_charging, state);
            }
        }
    }
}
