namespace DmgOsd {
    public enum BatteryState {
        NORMAL,
        LOW,
        CRITICAL
    }
    
    public class BatteryMonitor : Object {
        private Config config;
        private uint timeout_id = 0;
        private string battery_path = "";
        
        // D-Bus connection
        private DBusConnection? connection = null;
        
        public signal void battery_level_changed(double percentage, bool is_charging, BatteryState state);
        
        public BatteryMonitor(Config config) {
            this.config = config;
            init_dbus.begin();
            start_monitoring();
        }
        
        private async void init_dbus() {
            try {
                connection = yield Bus.get(BusType.SYSTEM);
                yield find_battery_device();
            } catch (Error e) {
                warning("Error initializing D-Bus: %s", e.message);
            }
        }
        
        private async void find_battery_device() {
            try {
                // Call UPower to enumerate devices
                var result = yield connection.call(
                    "org.freedesktop.UPower",
                    "/org/freedesktop/UPower",
                    "org.freedesktop.UPower",
                    "EnumerateDevices",
                    null,
                    new VariantType("(ao)"),
                    DBusCallFlags.NONE,
                    -1,
                    null
                );
                
                // Parse device paths
                Variant devices_variant = result.get_child_value(0);
                size_t n_devices = devices_variant.n_children();
                
                for (size_t i = 0; i < n_devices; i++) {
                    string device_path = devices_variant.get_child_value(i).get_string();
                    
                    // Check if this is a battery
                    if (yield is_battery_device(device_path)) {
                        battery_path = device_path;
                        print("Found battery device: %s\n", battery_path);
                        break;
                    }
                }
                
                if (battery_path == "") {
                    warning("No battery device found!");
                }
            } catch (Error e) {
                warning("Error finding battery device: %s", e.message);
            }
        }
        
        private async bool is_battery_device(string device_path) {
            try {
                var result = yield connection.call(
                    "org.freedesktop.UPower",
                    device_path,
                    "org.freedesktop.DBus.Properties",
                    "Get",
                    new Variant("(ss)", "org.freedesktop.UPower.Device", "Type"),
                    new VariantType("(v)"),
                    DBusCallFlags.NONE,
                    -1,
                    null
                );
                
                Variant value = result.get_child_value(0).get_variant();
                uint32 device_type = value.get_uint32();
                
                // Type 2 is Battery, Type 3 is UPS
                return (device_type == 2 || device_type == 3);
            } catch (Error e) {
                return false;
            }
        }
        
        private void start_monitoring() {
            // Initial check
            check_battery.begin();
            
            // Set up periodic checks
            timeout_id = Timeout.add(config.update_interval_ms, () => {
                check_battery.begin();
                return Source.CONTINUE;
            });
        }
        
        public void force_check() {
            // Manually trigger a battery check (used for config reload)
            check_battery.begin();
        }
        
        private async void check_battery() {
            if (connection == null || battery_path == "") {
                return;
            }
            
            try {
                // Get battery percentage
                var percentage_result = yield connection.call(
                    "org.freedesktop.UPower",
                    battery_path,
                    "org.freedesktop.DBus.Properties",
                    "Get",
                    new Variant("(ss)", "org.freedesktop.UPower.Device", "Percentage"),
                    new VariantType("(v)"),
                    DBusCallFlags.NONE,
                    -1,
                    null
                );
                
                double percentage = percentage_result.get_child_value(0).get_variant().get_double();
                
                // Get battery state
                var state_result = yield connection.call(
                    "org.freedesktop.UPower",
                    battery_path,
                    "org.freedesktop.DBus.Properties",
                    "Get",
                    new Variant("(ss)", "org.freedesktop.UPower.Device", "State"),
                    new VariantType("(v)"),
                    DBusCallFlags.NONE,
                    -1,
                    null
                );
                
                uint32 state = state_result.get_child_value(0).get_variant().get_uint32();
                
                // State: 1=Charging, 2=Discharging, 3=Empty, 4=Fully charged, 5=Pending charge, 6=Pending discharge
                bool is_charging = (state == 1 || state == 4);
                
                BatteryState battery_state = get_battery_state(percentage, is_charging);
                
                battery_level_changed(percentage, is_charging, battery_state);
            } catch (Error e) {
                warning("Error checking battery: %s", e.message);
            }
        }
        
        private BatteryState get_battery_state(double percentage, bool is_charging) {
            // Don't show warnings when charging
            if (is_charging) {
                return BatteryState.NORMAL;
            }
            
            if (percentage <= config.critical_threshold) {
                return BatteryState.CRITICAL;
            } else if (percentage <= config.low_threshold) {
                return BatteryState.LOW;
            }
            
            return BatteryState.NORMAL;
        }
        
        ~BatteryMonitor() {
            if (timeout_id != 0) {
                Source.remove(timeout_id);
            }
        }
    }
}
