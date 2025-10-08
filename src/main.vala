using Gtk;

namespace DmgOsd {
    public static int main(string[] args) {
        // Initialize GTK
        Gtk.init();
        
        // Create and run the application
        var app = new DmgOsdApplication();
        return app.run(args);
    }
}
