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

[GtkTemplate (ui = "/com/github/albert-tomanek/markup/markup.ui")]
public class Markup : Gtk.Overlay
{
	ArrayList<Stroke> strokes = new ArrayList<Stroke>();
	Stroke?  current = null;

	[GtkChild]
	Gtk.DrawingArea canvas;

	[GtkChild]
	Gtk.Revealer tray;

	[GtkChild]
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
		this.canvas.draw.connect((cr) => { return this.draw_canvas(cr); });

		this.color = parse_rgba("red");
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

	[GtkCallback]
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

	[GtkCallback]
    protected bool canvas_button_release (Gdk.EventButton event)
	{
		this.current = null;	// This stroke has finished.

        return false;
    }

	[GtkCallback]
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
