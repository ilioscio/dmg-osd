using Gtk;

namespace DmgOsd {
    public class OverlayWindow : Gtk.Window {
        private Gtk.DrawingArea drawing_area;
        private Config config;
        private double current_opacity = 0.0;
        private double target_opacity = 0.0;
        private double current_red = 1.0;
        private double current_green = 0.0;
        private double current_blue = 0.0;
        private bool is_pulsing = false;
        private uint animation_id = 0;
        private uint current_pulse_duration = 1000;
        
        public OverlayWindow(Gtk.Application app, Config config) {
            Object(application: app);
            this.config = config;
            setup_layer_shell();
            setup_ui();
            setup_input_passthrough();
        }
        
        private void setup_layer_shell() {
            // Initialize layer shell
            GtkLayerShell.init_for_window(this);
            
            // Set layer to overlay (top layer)
            GtkLayerShell.set_layer(this, GtkLayerShell.Layer.OVERLAY);
            
            // Anchor to all edges to cover entire screen
            GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.LEFT, true);
            GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.RIGHT, true);
            GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.TOP, true);
            GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, true);
            
            // Set margins to 0 to ensure full coverage
            GtkLayerShell.set_margin(this, GtkLayerShell.Edge.LEFT, 0);
            GtkLayerShell.set_margin(this, GtkLayerShell.Edge.RIGHT, 0);
            GtkLayerShell.set_margin(this, GtkLayerShell.Edge.TOP, 0);
            GtkLayerShell.set_margin(this, GtkLayerShell.Edge.BOTTOM, 0);
            
            // CRITICAL: Ignore exclusive zones from bars/panels
            GtkLayerShell.auto_exclusive_zone_enable(this);
            GtkLayerShell.set_exclusive_zone(this, -1);
            
            // Set keyboard interactivity to none so it doesn't intercept input
            GtkLayerShell.set_keyboard_mode(this, GtkLayerShell.KeyboardMode.NONE);
            
            // Set namespace
            GtkLayerShell.set_namespace(this, "dmg-osd");
        }
        
        private void setup_input_passthrough() {
            // Wait for the window to be mapped, then set input region
            this.map.connect(() => {
                var surface = this.get_surface();
                if (surface != null) {
                    var empty_region = new Cairo.Region();
                    surface.set_input_region(empty_region);
                }
            });
        }
        
        private void setup_ui() {
            // Create drawing area for the overlay
            drawing_area = new Gtk.DrawingArea();
            drawing_area.set_draw_func(on_draw);
            
            // Make window click-through by not accepting any input
            set_child(drawing_area);
            
            // Add CSS for transparency
            var css_provider = new Gtk.CssProvider();
            css_provider.load_from_data("""
                window {
                    background-color: transparent;
                }
            """.data);
            
            Gtk.StyleContext.add_provider_for_display(
                Gdk.Display.get_default(),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
            
            // Start with invisible
            current_opacity = 0.0;
        }
        
        public void update_damage_effect(double percentage, bool is_charging, BatteryState state) {
            // Don't show overlay when charging or battery is good
            if (is_charging || state == BatteryState.NORMAL) {
                target_opacity = 0.0;
                stop_pulsing();
                return;
            }
            
            // Update color based on battery level
            config.get_color_for_level(percentage, out current_red, out current_green, out current_blue);
            
            // Update target opacity based on severity
            target_opacity = config.get_max_opacity_for_level(percentage);
            
            // Update pulse duration based on severity
            current_pulse_duration = config.get_pulse_duration_for_level(percentage);
            
            // Start pulsing effect
            if (!is_pulsing && target_opacity > 0.0) {
                start_pulsing();
            }
        }
        
        private void start_pulsing() {
            if (is_pulsing) {
                return;
            }
            
            is_pulsing = true;
            
            // Animation loop
            animation_id = Timeout.add(16, () => { // ~60 FPS
                pulse_step();
                drawing_area.queue_draw();
                return Source.CONTINUE;
            });
        }
        
        private void stop_pulsing() {
            if (!is_pulsing) {
                return;
            }
            
            is_pulsing = false;
            
            if (animation_id != 0) {
                Source.remove(animation_id);
                animation_id = 0;
            }
            
            // Fade out smoothly
            fade_out();
        }
        
        private void pulse_step() {
            // Calculate pulse using sine wave with current pulse duration
            int64 now = get_monotonic_time();
            double time_sec = (now % (current_pulse_duration * 1000)) / 1000000.0;
            double phase = (time_sec / (current_pulse_duration / 1000.0)) * Math.PI * 2.0;
            
            // Sine wave from 0 to 1
            double pulse = (Math.sin(phase) + 1.0) / 2.0;
            
            // Scale to target opacity range
            current_opacity = config.min_opacity + (target_opacity - config.min_opacity) * pulse;
        }
        
        private void fade_out() {
            // Smooth fade out animation
            Timeout.add(16, () => {
                current_opacity *= 0.9;
                drawing_area.queue_draw();
                
                if (current_opacity < 0.01) {
                    current_opacity = 0.0;
                    return Source.REMOVE;
                }
                
                return Source.CONTINUE;
            });
        }
        
        private void on_draw(Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
            // Clear to fully transparent first
            cr.set_operator(Cairo.Operator.CLEAR);
            cr.paint();
            
            // Create vignette effect - radial gradient from edges
            cr.set_operator(Cairo.Operator.OVER);
            
            // Calculate center point
            double cx = width / 2.0;
            double cy = height / 2.0;
            
            // Calculate the maximum radius (from center to corner)
            double max_radius = Math.sqrt(cx * cx + cy * cy);
            
            // Create radial gradient
            // Inner radius: where the vignette starts to fade in (transparent in center)
            double inner_radius = max_radius * (1.0 - config.vignette_size);
            // Outer radius: edge of screen (full opacity at edges)
            double outer_radius = max_radius;
            
            var pattern = new Cairo.Pattern.radial(cx, cy, inner_radius, cx, cy, outer_radius);
            
            // Center is transparent
            pattern.add_color_stop_rgba(0.0, current_red, current_green, current_blue, 0.0);
            // Edges have full opacity
            pattern.add_color_stop_rgba(1.0, current_red, current_green, current_blue, current_opacity);
            
            cr.set_source(pattern);
            cr.paint();
        }
        
        ~OverlayWindow() {
            if (animation_id != 0) {
                Source.remove(animation_id);
            }
        }
    }
}
