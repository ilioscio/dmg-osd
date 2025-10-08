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
        }
        
        private void on_battery_changed(double percentage, bool is_charging, BatteryState state) {
            if (overlay_window != null) {
                overlay_window.update_damage_effect(percentage, is_charging, state);
            }
        }
    }
}
