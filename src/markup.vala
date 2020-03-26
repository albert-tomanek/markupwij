using Gee;
using Gdk;

[Compact]
private struct Coord
{
	double x;
	double y;

	public Coord(double x, double y)
	{
		this.x = x;
		this.y = y;
	}
}

private class Stroke
{
	ArrayList<Coord?> coords = new ArrayList<Coord?>();
	public RGBA color;
	public double width;

	public void record(double x, double y)
	{
		coords.add(Coord(x, y));
	}

	public void draw(Cairo.Context cr)
	{
		if (!(coords.size > 0)) return;

		cr.set_line_width(width);
		cr.set_source_rgb(color.red, color.green, color.blue);

		cr.move_to(coords[0].x, coords[0].y);

		for (int i = 1; i < coords.size; i++)
		{
			cr.line_to(coords[i].x, coords[i].y);
		}

		cr.stroke();
	}
}

public class Markup : Gtk.Overlay
{
	ArrayList<Stroke> strokes = new ArrayList<Stroke>();
	Stroke?  current = null;

	Gtk.DrawingArea canvas;
	Gtk.Revealer    tray;
	Gtk.ColorButton color_selector;

	public RGBA color {
		get { return color_selector.get_rgba(); }
		set { color_selector.set_rgba(value); }
	}

	public double width {
		get { return 8; }
	}

	protected Markup()
	{
		this.canvas = new Gtk.DrawingArea();
		this.add(this.canvas);

		this.canvas.draw.connect((cr) => { return this.draw_canvas(cr); });
		this.canvas.button_press_event.connect  ((evt) => { return this.canvas_button_press(evt); });
		this.canvas.button_release_event.connect((evt) => { return this.canvas_button_release(evt); });
		this.canvas.motion_notify_event.connect ((evt) => { return this.canvas_motion_notify(evt); });

		this.tray = new Gtk.Revealer();
		this.tray.halign = Gtk.Align.CENTER;
		this.tray.valign = Gtk.Align.END;
		this.add_overlay(this.tray);
		this.set_overlay_pass_through(this.tray, true);
		this.tray.set_reveal_child(true);

		{
			var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			box.halign = Gtk.Align.CENTER;
			box.valign = Gtk.Align.END;
			box.margin = 12;
			box.get_style_context().add_class("linked");
//			box.get_style_context().add_class("osd");
			this.tray.add(box);

			this.color_selector = new Gtk.ColorButton.with_rgba(parse_rgba("#ff0000"));
			this.color_selector.get_style_context().add_class("osd");
			box.add(this.color_selector);
		}

		this.show_all();
	}

	public Markup.with_image(Gdk.Pixbuf img)
	{
		this();
		// this.pixbuf = img;
	}

    public Markup.with_size(int width, int height)
	{
		this();

        // Set favored widget size
        this.canvas.set_size_request (width, height);
    }

	public override void realize()
	{
		base.realize();

		this.canvas.add_events (
			Gdk.EventMask.BUTTON_PRESS_MASK |
			Gdk.EventMask.BUTTON_RELEASE_MASK |
			Gdk.EventMask.POINTER_MOTION_MASK
		);
	}

	/* Canvas control */

    protected bool draw_canvas (Cairo.Context cr)	// Draws the DrawingArea inside us.
	{
        int w = this.canvas.get_allocated_width ();
        int h = this.canvas.get_allocated_height ();

		cr.set_line_join(Cairo.LineJoin.ROUND);
		cr.set_line_cap(Cairo.LineCap.ROUND);

		foreach (Stroke stroke in this.strokes)
		{
			stroke.draw(cr);
		}

        return true;
    }

    protected bool canvas_button_press (Gdk.EventButton event)
	{
		if (event.button == 1)
		{
			this.current = new Stroke();
			this.current.color = this.color;
			this.current.width = this.width;
			this.strokes.add(this.current);
		}

        return false;
    }

    protected bool canvas_button_release (Gdk.EventButton event)
	{
		this.current = null;	// This stroke has finished.

        return false;
    }

    protected bool canvas_motion_notify (Gdk.EventMotion event)
	{
		if (this.current != null)
		{
			this.current.record(event.x, event.y);
			this.queue_draw();
		}

        return false;
    }
}

RGBA parse_rgba(string text)
{
	var color = RGBA();
	color.parse(text);
	return color;
}
