namespace DmgOsd {
    public class Config : Object {
        // Battery thresholds (only 2 states now)
        public double critical_threshold { get; set; default = 15.0; }
        public double low_threshold { get; set; default = 30.0; }
        
        // Visual settings
        public double max_opacity { get; set; default = 0.4; }
        public double min_opacity { get; set; default = 0.0; }
        
        // Animation settings - different pulse durations for each state
        public uint critical_pulse_duration_ms { get; set; default = 600; }  // Faster pulse for critical
        public uint low_pulse_duration_ms { get; set; default = 1200; }      // Slower pulse for low
        public uint update_interval_ms { get; set; default = 5000; }
        
        // Vignette settings
        public double vignette_size { get; set; default = 0.4; }  // How far the vignette extends (0-1, where 1 is full screen)
        
        // Color settings - hexadecimal RGB format (e.g., #FF0000 for red)
        public string color { get; set; default = "#FF0000"; }
        
        // Temporary storage for backward compatibility with old RGB format
        private double temp_red = -1.0;
        private double temp_green = -1.0;
        private double temp_blue = -1.0;
        
        public Config() {
            load_config();
        }
        
        public void reload() {
            // Reset to defaults first
            critical_threshold = 15.0;
            low_threshold = 30.0;
            max_opacity = 0.4;
            min_opacity = 0.0;
            critical_pulse_duration_ms = 600;
            low_pulse_duration_ms = 1200;
            update_interval_ms = 5000;
            vignette_size = 0.4;
            color = "#FF0000"; // Reset color to default
            
            // Load config again
            load_config();
        }
        
        private void load_config() {
            string? config_path = find_config_file();
            
            if (config_path != null) {
                print("Loading config from: %s\n", config_path);
                parse_config_file(config_path);
            } else {
                print("No config file found, using defaults\n");
            }
        }
        
        private string? find_config_file() {
            // Priority 2: ~/.config/dmg-osd/dmg-osd.config
            string home_config = Path.build_filename(
                Environment.get_user_config_dir(),
                "dmg-osd",
                "dmg-osd.config"
            );
            
            if (FileUtils.test(home_config, FileTest.EXISTS)) {
                return home_config;
            }
            
            // Priority 1: ./dmg-osd.config (current directory)
            string local_config = "dmg-osd.config";
            if (FileUtils.test(local_config, FileTest.EXISTS)) {
                return local_config;
            }
            
            return null;
        }
        
        private void parse_config_file(string path) {
            try {
                string contents;
                FileUtils.get_contents(path, out contents);
                
                string[] lines = contents.split("\n");
                
                foreach (string line in lines) {
                    // Skip empty lines and comments
                    string trimmed = line.strip();
                    if (trimmed.length == 0 || trimmed.has_prefix("#")) {
                        continue;
                    }
                    
                    // Parse key=value
                    string[] parts = trimmed.split("=", 2);
                    if (parts.length != 2) {
                        continue;
                    }
                    
                    string key = parts[0].strip();
                    string value = parts[1].strip();
                    
                    apply_config_value(key, value);
                }
            } catch (Error e) {
                warning("Error reading config file: %s", e.message);
            }
        }
        
        private void apply_config_value(string key, string value) {
            switch (key) {
                case "critical_threshold":
                    critical_threshold = double.parse(value);
                    break;
                case "low_threshold":
                    low_threshold = double.parse(value);
                    break;
                case "max_opacity":
                    max_opacity = double.parse(value);
                    break;
                case "min_opacity":
                    min_opacity = double.parse(value);
                    break;
                case "critical_pulse_duration_ms":
                    critical_pulse_duration_ms = (uint)int.parse(value);
                    break;
                case "low_pulse_duration_ms":
                    low_pulse_duration_ms = (uint)int.parse(value);
                    break;
                case "update_interval_ms":
                    update_interval_ms = (uint)int.parse(value);
                    break;
                case "vignette_size":
                    vignette_size = double.parse(value);
                    break;
                case "color":
                    color = value;
                    break;
                // Backward compatibility for old RGB format
                case "red":
                    temp_red = double.parse(value);
                    convert_rgb_to_hex();
                    break;
                case "green":
                    temp_green = double.parse(value);
                    convert_rgb_to_hex();
                    break;
                case "blue":
                    temp_blue = double.parse(value);
                    convert_rgb_to_hex();
                    break;
                default:
                    warning("Unknown config key: %s", key);
                    break;
            }
        }
        
        private void convert_rgb_to_hex() {
            // Only convert if all three values are set (all >= 0)
            if (temp_red >= 0.0 && temp_green >= 0.0 && temp_blue >= 0.0) {
                uint r = (uint)(temp_red * 255.0);
                uint g = (uint)(temp_green * 255.0);
                uint b = (uint)(temp_blue * 255.0);
                color = "#%02X%02X%02X".printf(r, g, b);
                print("Converted old RGB config to hex: %s\n", color);
                // Reset temps so we don't convert again
                temp_red = -1.0;
                temp_green = -1.0;
                temp_blue = -1.0;
            }
        }
        
        public void get_color_for_level(double percentage, out double r, out double g, out double b) {
            // Parse hex color format: #RRGGBB (skip the # and take pairs)
            if (color.length >= 7) {
                r = hex_to_uint(color.substring(1, 2)) / 255.0;
                g = hex_to_uint(color.substring(3, 2)) / 255.0;
                b = hex_to_uint(color.substring(5, 2)) / 255.0;
            } else {
                // Fallback to red if parsing fails
                r = 1.0;
                g = 0.0;
                b = 0.0;
            }
        }
        
        private uint hex_to_uint(string hex_str) {
            uint result = 0;
            for (int i = 0; i < hex_str.length; i++) {
                unichar c = hex_str[i];
                result = result * 16;
                if (c >= '0' && c <= '9') {
                    result += (c - '0');
                } else if (c >= 'A' && c <= 'F') {
                    result += (c - 'A' + 10);
                } else if (c >= 'a' && c <= 'f') {
                    result += (c - 'a' + 10);
                }
            }
            return result;
        }
        
        public double get_max_opacity_for_level(double percentage) {
            if (percentage <= critical_threshold) {
                return max_opacity;
            } else if (percentage <= low_threshold) {
                return max_opacity * 0.7;
            }
            return 0.0;
        }
        
        public uint get_pulse_duration_for_level(double percentage) {
            if (percentage <= critical_threshold) {
                return critical_pulse_duration_ms;
            } else if (percentage <= low_threshold) {
                return low_pulse_duration_ms;
            }
            return low_pulse_duration_ms;
        }
        
        public bool save_to_file() {
            // Ensure config directory exists
            string config_dir = Path.build_filename(
                Environment.get_user_config_dir(),
                "dmg-osd"
            );
            
            try {
                DirUtils.create_with_parents(config_dir, 0755);
            } catch (Error e) {
                warning("Failed to create config directory: %s", e.message);
                return false;
            }
            
            // Build config file path
            string config_path = Path.build_filename(config_dir, "dmg-osd.config");
            
            // Generate config file content
            string content = """# dmg-osd configuration file
# This file was automatically generated by dmg-osd settings GUI

# Battery thresholds (percentage)
critical_threshold=%.1f
low_threshold=%.1f

# Visual settings
max_opacity=%.2f
min_opacity=%.2f

# Animation settings (milliseconds)
critical_pulse_duration_ms=%u
low_pulse_duration_ms=%u
update_interval_ms=%u

# Vignette settings
vignette_size=%.2f

# Color settings (RGB values 0.0-1.0)
color=%s
""".printf(
                critical_threshold,
                low_threshold,
                max_opacity,
                min_opacity,
                critical_pulse_duration_ms,
                low_pulse_duration_ms,
                update_interval_ms,
                vignette_size,
                color
            );
            
            // Write to file
            try {
                FileUtils.set_contents(config_path, content);
                print("Config saved to: %s\n", config_path);
                return true;
            } catch (Error e) {
                warning("Failed to save config: %s", e.message);
                return false;
            }
        }
    }
}
