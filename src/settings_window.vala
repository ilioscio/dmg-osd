using Gtk;

namespace DmgOsd {
    public class SettingsWindow : Gtk.ApplicationWindow {
        private Config config;
        
        // UI widgets
        private Gtk.Scale critical_threshold_scale;
        private Gtk.SpinButton critical_threshold_spin;
        private Gtk.Scale low_threshold_scale;
        private Gtk.SpinButton low_threshold_spin;
        private Gtk.Scale max_opacity_scale;
        private Gtk.SpinButton max_opacity_spin;
        private Gtk.Scale vignette_size_scale;
        private Gtk.SpinButton vignette_size_spin;
        private Gtk.SpinButton critical_pulse_spin;
        private Gtk.SpinButton low_pulse_spin;
        private Gtk.SpinButton update_interval_spin;
        private Gtk.Scale color_red_scale;
        private Gtk.SpinButton color_red_spin;
        private Gtk.Scale color_green_scale;
        private Gtk.SpinButton color_green_spin;
        private Gtk.Scale color_blue_scale;
        private Gtk.SpinButton color_blue_spin;
        private Gtk.DrawingArea color_preview;
        
        public signal void config_saved();
        
        public SettingsWindow(Gtk.Application app, Config config) {
            Object(application: app);
            this.config = config;
            
            title = "dmg-osd Settings";
            default_width = 600;
            default_height = 700;
            
            // Add a CSS class to this window specifically
            add_css_class("settings-window");
            
            // Apply CSS only to settings windows
            var css_provider = new Gtk.CssProvider();
            css_provider.load_from_data("""
                .settings-window {
                    background-color: @theme_bg_color;
                }
            """.data);
            
            var display = Gdk.Display.get_default();
            if (display != null) {
                Gtk.StyleContext.add_provider_for_display(
                    display,
                    css_provider,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
                );
            }
            
            setup_ui();
            refresh_from_config();
        }
        
        private void setup_ui() {
            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            
            // Header bar
            var header = new Gtk.HeaderBar();
            header.show_title_buttons = true;
            set_titlebar(header);
            
            // Scrolled window for settings
            var scrolled = new Gtk.ScrolledWindow();
            scrolled.vexpand = true;
            
            var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 24);
            content_box.margin_top = 24;
            content_box.margin_bottom = 24;
            content_box.margin_start = 24;
            content_box.margin_end = 24;
            
            // Battery Thresholds Section
            content_box.append(create_section_header("Battery Thresholds"));
            content_box.append(create_threshold_controls());
            
            // Visual Settings Section
            content_box.append(create_section_header("Visual Settings"));
            content_box.append(create_visual_controls());
            
            // Color Settings Section
            content_box.append(create_section_header("Color Settings"));
            content_box.append(create_color_controls());
            
            // Animation Settings Section
            content_box.append(create_section_header("Animation Settings"));
            content_box.append(create_animation_controls());
            
            scrolled.set_child(content_box);
            main_box.append(scrolled);
            
            // Action buttons
            var button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            button_box.margin_top = 12;
            button_box.margin_bottom = 12;
            button_box.margin_start = 24;
            button_box.margin_end = 24;
            button_box.halign = Gtk.Align.END;
            
            var reset_button = new Gtk.Button.with_label("Reset to Defaults");
            reset_button.clicked.connect(on_reset_clicked);
            
            var save_button = new Gtk.Button.with_label("Save");
            save_button.add_css_class("suggested-action");
            save_button.clicked.connect(on_save_clicked);
            
            button_box.append(reset_button);
            button_box.append(save_button);
            
            main_box.append(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
            main_box.append(button_box);
            
            set_child(main_box);
        }
        
        private Gtk.Widget create_section_header(string title) {
            var label = new Gtk.Label(title);
            label.add_css_class("title-3");
            label.halign = Gtk.Align.START;
            label.margin_top = 12;
            return label;
        }
        
        private Gtk.Widget create_threshold_controls() {
            var grid = new Gtk.Grid();
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            
            // Low threshold (now first)
            var low_label = new Gtk.Label("Low Threshold (%)");
            low_label.halign = Gtk.Align.START;
            
            low_threshold_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 1, 100, 1);
            low_threshold_scale.hexpand = true;
            low_threshold_scale.draw_value = false;
            
            low_threshold_spin = new Gtk.SpinButton.with_range(1, 100, 1);
            
            bind_scale_spin(low_threshold_scale, low_threshold_spin);
            
            grid.attach(low_label, 0, 0, 1, 1);
            grid.attach(low_threshold_scale, 1, 0, 1, 1);
            grid.attach(low_threshold_spin, 2, 0, 1, 1);
            
            // Critical threshold (now second)
            var critical_label = new Gtk.Label("Critical Threshold (%)");
            critical_label.halign = Gtk.Align.START;
            
            critical_threshold_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 1, 100, 1);
            critical_threshold_scale.hexpand = true;
            critical_threshold_scale.draw_value = false;
            
            critical_threshold_spin = new Gtk.SpinButton.with_range(1, 100, 1);
            
            bind_scale_spin(critical_threshold_scale, critical_threshold_spin);
            
            grid.attach(critical_label, 0, 1, 1, 1);
            grid.attach(critical_threshold_scale, 1, 1, 1, 1);
            grid.attach(critical_threshold_spin, 2, 1, 1, 1);
            
            // Help text
            var help_label = new Gtk.Label("Note: Critical threshold should be lower than low threshold");
            help_label.add_css_class("dim-label");
            help_label.add_css_class("caption");
            help_label.halign = Gtk.Align.START;
            help_label.wrap = true;
            
            grid.attach(help_label, 0, 2, 3, 1);
            
            return grid;
        }
        
        private Gtk.Widget create_visual_controls() {
            var grid = new Gtk.Grid();
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            
            // Max opacity
            var opacity_label = new Gtk.Label("Maximum Opacity");
            opacity_label.halign = Gtk.Align.START;
            
            max_opacity_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0.1, 1.0, 0.01);
            max_opacity_scale.hexpand = true;
            max_opacity_scale.draw_value = false;
            
            max_opacity_spin = new Gtk.SpinButton.with_range(0.1, 1.0, 0.01);
            max_opacity_spin.digits = 2;
            
            bind_scale_spin(max_opacity_scale, max_opacity_spin);
            
            grid.attach(opacity_label, 0, 0, 1, 1);
            grid.attach(max_opacity_scale, 1, 0, 1, 1);
            grid.attach(max_opacity_spin, 2, 0, 1, 1);
            
            // Vignette size
            var vignette_label = new Gtk.Label("Vignette Size");
            vignette_label.halign = Gtk.Align.START;
            
            vignette_size_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0.1, 1.0, 0.01);
            vignette_size_scale.hexpand = true;
            vignette_size_scale.draw_value = false;
            
            vignette_size_spin = new Gtk.SpinButton.with_range(0.1, 1.0, 0.01);
            vignette_size_spin.digits = 2;
            
            bind_scale_spin(vignette_size_scale, vignette_size_spin);
            
            grid.attach(vignette_label, 0, 1, 1, 1);
            grid.attach(vignette_size_scale, 1, 1, 1, 1);
            grid.attach(vignette_size_spin, 2, 1, 1, 1);
            
            return grid;
        }
        
        private Gtk.Widget create_animation_controls() {
            var grid = new Gtk.Grid();
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            
            // Critical pulse duration
            var critical_pulse_label = new Gtk.Label("Critical Pulse Duration (ms)");
            critical_pulse_label.halign = Gtk.Align.START;
            
            critical_pulse_spin = new Gtk.SpinButton.with_range(200, 2000, 50);
            
            grid.attach(critical_pulse_label, 0, 0, 1, 1);
            grid.attach(critical_pulse_spin, 1, 0, 1, 1);
            
            // Low pulse duration
            var low_pulse_label = new Gtk.Label("Low Pulse Duration (ms)");
            low_pulse_label.halign = Gtk.Align.START;
            
            low_pulse_spin = new Gtk.SpinButton.with_range(400, 3000, 50);
            
            grid.attach(low_pulse_label, 0, 1, 1, 1);
            grid.attach(low_pulse_spin, 1, 1, 1, 1);
            
            // Update interval
            var update_label = new Gtk.Label("Battery Check Interval (ms)");
            update_label.halign = Gtk.Align.START;
            
            update_interval_spin = new Gtk.SpinButton.with_range(1000, 30000, 1000);
            
            grid.attach(update_label, 0, 2, 1, 1);
            grid.attach(update_interval_spin, 1, 2, 1, 1);
            
            return grid;
        }
        
        private Gtk.Widget create_color_controls() {
            var grid = new Gtk.Grid();
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            
            // Color preview
            var preview_label = new Gtk.Label("Preview");
            preview_label.halign = Gtk.Align.START;
            
            color_preview = new Gtk.DrawingArea();
            color_preview.set_content_width(100);
            color_preview.set_content_height(60);
            color_preview.set_draw_func(draw_color_preview);
            
            grid.attach(preview_label, 0, 0, 1, 1);
            grid.attach(color_preview, 1, 0, 2, 1);
            
            // Red channel
            var red_label = new Gtk.Label("Red");
            red_label.halign = Gtk.Align.START;
            
            color_red_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0.0, 255.0, 1.0);
            color_red_scale.hexpand = true;
            color_red_scale.draw_value = false;
            color_red_scale.value_changed.connect(() => color_preview.queue_draw());
            
            color_red_spin = new Gtk.SpinButton.with_range(0.0, 255.0, 1.0);
            color_red_spin.digits = 0;
            
            bind_scale_spin(color_red_scale, color_red_spin);
            
            grid.attach(red_label, 0, 1, 1, 1);
            grid.attach(color_red_scale, 1, 1, 1, 1);
            grid.attach(color_red_spin, 2, 1, 1, 1);
            
            // Green channel
            var green_label = new Gtk.Label("Green");
            green_label.halign = Gtk.Align.START;
            
            color_green_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0.0, 255.0, 1.0);
            color_green_scale.hexpand = true;
            color_green_scale.draw_value = false;
            color_green_scale.value_changed.connect(() => color_preview.queue_draw());
            
            color_green_spin = new Gtk.SpinButton.with_range(0.0, 255.0, 1.0);
            color_green_spin.digits = 0;
            
            bind_scale_spin(color_green_scale, color_green_spin);
            
            grid.attach(green_label, 0, 2, 1, 1);
            grid.attach(color_green_scale, 1, 2, 1, 1);
            grid.attach(color_green_spin, 2, 2, 1, 1);
            
            // Blue channel
            var blue_label = new Gtk.Label("Blue");
            blue_label.halign = Gtk.Align.START;
            
            color_blue_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0.0, 255.0, 1.0);
            color_blue_scale.hexpand = true;
            color_blue_scale.draw_value = false;
            color_blue_scale.value_changed.connect(() => color_preview.queue_draw());
            
            color_blue_spin = new Gtk.SpinButton.with_range(0.0, 255.0, 1.0);
            color_blue_spin.digits = 0;
            
            bind_scale_spin(color_blue_scale, color_blue_spin);
            
            grid.attach(blue_label, 0, 3, 1, 1);
            grid.attach(color_blue_scale, 1, 3, 1, 1);
            grid.attach(color_blue_spin, 2, 3, 1, 1);
            
            return grid;
        }
        
        private void draw_color_preview(Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
            // Get current color values (convert from 0-255 to 0-1)
            double r = color_red_scale.get_value() / 255.0;
            double g = color_green_scale.get_value() / 255.0;
            double b = color_blue_scale.get_value() / 255.0;
            
            // Draw border
            cr.set_source_rgb(0.5, 0.5, 0.5);
            cr.rectangle(0, 0, width, height);
            cr.stroke();
            
            // Fill with color
            cr.set_source_rgb(r, g, b);
            cr.rectangle(2, 2, width - 4, height - 4);
            cr.fill();
        }
        
        private void bind_scale_spin(Gtk.Scale scale, Gtk.SpinButton spin) {
            scale.value_changed.connect(() => {
                spin.value = scale.get_value();
            });
            
            spin.value_changed.connect(() => {
                scale.set_value(spin.value);
            });
        }
        
        public void refresh_from_config() {
            critical_threshold_spin.value = config.critical_threshold;
            low_threshold_spin.value = config.low_threshold;
            max_opacity_spin.value = config.max_opacity;
            vignette_size_spin.value = config.vignette_size;
            critical_pulse_spin.value = config.critical_pulse_duration_ms;
            low_pulse_spin.value = config.low_pulse_duration_ms;
            update_interval_spin.value = config.update_interval_ms;
            
            // Set color sliders (convert from 0-1 to 0-255)
            color_red_spin.value = config.red * 255.0;
            color_green_spin.value = config.green * 255.0;
            color_blue_spin.value = config.blue * 255.0;
        }
        
        private void on_reset_clicked() {
            config.critical_threshold = 15.0;
            config.low_threshold = 30.0;
            config.max_opacity = 0.4;
            config.min_opacity = 0.0;
            config.vignette_size = 0.4;
            config.critical_pulse_duration_ms = 600;
            config.low_pulse_duration_ms = 1200;
            config.update_interval_ms = 5000;
            config.red = 1.0;
            config.green = 0.0;
            config.blue = 0.0;
            
            refresh_from_config();
        }
        
        private void on_save_clicked() {
            // Update config from UI
            config.critical_threshold = critical_threshold_spin.value;
            config.low_threshold = low_threshold_spin.value;
            config.max_opacity = max_opacity_spin.value;
            config.vignette_size = vignette_size_spin.value;
            config.critical_pulse_duration_ms = (uint)critical_pulse_spin.value;
            config.low_pulse_duration_ms = (uint)low_pulse_spin.value;
            config.update_interval_ms = (uint)update_interval_spin.value;
            
            // Get color from sliders (convert from 0-255 to 0-1)
            config.red = color_red_spin.value / 255.0;
            config.green = color_green_spin.value / 255.0;
            config.blue = color_blue_spin.value / 255.0;
            
            // Save to file
            if (config.save_to_file()) {
                print("Configuration saved\n");
                // Config already updated above, just signal that it was saved
                // The application will force battery check with new thresholds
                config_saved();
                
                // Show success message
                show_save_success();
            } else {
                show_save_error();
            }
        }
        
        private void show_save_success() {
            var dialog = new Gtk.Window();
            dialog.set_transient_for(this);
            dialog.set_modal(true);
            dialog.title = "Configuration Saved";
            dialog.default_width = 300;
            dialog.default_height = 120;
            dialog.resizable = false;
            
            // Add solid background CSS
            var css = new Gtk.CssProvider();
            css.load_from_data("window { background-color: @theme_bg_color; }".data);
            dialog.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            box.margin_top = 20;
            box.margin_bottom = 20;
            box.margin_start = 20;
            box.margin_end = 20;
            box.halign = Gtk.Align.CENTER;
            box.valign = Gtk.Align.CENTER;
            
            var label = new Gtk.Label("Settings saved and applied");
            label.halign = Gtk.Align.CENTER;
            label.valign = Gtk.Align.CENTER;
            
            var button = new Gtk.Button.with_label("OK");
            button.add_css_class("suggested-action");
            button.halign = Gtk.Align.CENTER;
            button.valign = Gtk.Align.CENTER;
            button.clicked.connect(() => dialog.close());
            
            box.append(label);
            box.append(button);
            dialog.set_child(box);
            
            dialog.present();
        }
        
        private void show_save_error() {
            var dialog = new Gtk.Window();
            dialog.set_transient_for(this);
            dialog.set_modal(true);
            dialog.title = "Save Failed";
            dialog.default_width = 300;
            dialog.default_height = 120;
            dialog.resizable = false;
            
            // Add solid background CSS
            var css = new Gtk.CssProvider();
            css.load_from_data("window { background-color: @theme_bg_color; }".data);
            dialog.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            box.margin_top = 20;
            box.margin_bottom = 20;
            box.margin_start = 20;
            box.margin_end = 20;
            box.halign = Gtk.Align.CENTER;
            box.valign = Gtk.Align.CENTER;
            
            var label = new Gtk.Label("Could not save configuration file");
            label.halign = Gtk.Align.CENTER;
            label.valign = Gtk.Align.CENTER;
            
            var button = new Gtk.Button.with_label("OK");
            button.add_css_class("destructive-action");
            button.halign = Gtk.Align.CENTER;
            button.valign = Gtk.Align.CENTER;
            button.clicked.connect(() => dialog.close());
            
            box.append(label);
            box.append(button);
            dialog.set_child(box);
            
            dialog.present();
        }
    }
}
