using AppIndicator;

namespace DmgOsd {
    public class SystemTray : Object {
        private Indicator indicator;
        private Gtk.Menu menu;
        
        public signal void show_settings_clicked();
        public signal void quit_clicked();
        
        public SystemTray() {
            // Create the indicator
            indicator = new Indicator(
                "dmg-osd",
                "battery-caution",
                IndicatorCategory.APPLICATION_STATUS
            );
            
            indicator.set_status(IndicatorStatus.ACTIVE);
            indicator.set_title("dmg-osd");
            
            // Create menu
            menu = new Gtk.Menu();
            
            // Settings menu item
            var settings_item = new Gtk.MenuItem.with_label("Settings");
            settings_item.activate.connect(() => {
                show_settings_clicked();
            });
            menu.append(settings_item);
            
            // Separator
            menu.append(new Gtk.SeparatorMenuItem());
            
            // About menu item
            var about_item = new Gtk.MenuItem.with_label("About");
            about_item.activate.connect(show_about);
            menu.append(about_item);
            
            // Separator
            menu.append(new Gtk.SeparatorMenuItem());
            
            // Quit menu item
            var quit_item = new Gtk.MenuItem.with_label("Quit");
            quit_item.activate.connect(() => {
                quit_clicked();
            });
            menu.append(quit_item);
            
            menu.show_all();
            indicator.set_menu(menu);
        }
        
        private void show_about() {
            var dialog = new Gtk.MessageDialog(
                null,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.INFO,
                Gtk.ButtonsType.OK,
                "dmg-osd"
            );
            dialog.secondary_text = "Battery Damage Overlay for Wayland\n\nA visual battery warning system inspired by video game health indicators.";
            dialog.response.connect(() => dialog.close());
            dialog.present();
        }
        
        public void set_icon(string icon_name) {
            indicator.set_icon(icon_name);
        }
        
        public void set_label(string label) {
            indicator.set_label(label, "");
        }
    }
}
