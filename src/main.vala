public class MarkupExample : Gtk.Application {
	public MarkupExample () {
		Object(application_id: "testing.my.application",
				flags: ApplicationFlags.FLAGS_NONE);
	}

	protected override void activate () {
		// Create the window of this application and show it
		Gtk.ApplicationWindow window = new Gtk.ApplicationWindow (this);
		window.title = "My Gtk.ApplicationWindow";
		window.set_default_size (400, 400);

		var mkup = new Markup.with_size(400, 400);
		mkup.show();
		window.add (mkup);
		window.show_all ();
	}

	public static int main (string[] args) {
		var app = new MarkupExample ();
		return app.run (args);
	}
}
