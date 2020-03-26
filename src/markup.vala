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

public class Stroke
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

	int undo_index = 0;	// 0 or negative

	[GtkChild]
	Gtk.DrawingArea canvas;

	[GtkChild]
	Gtk.Revealer tray;

	[GtkChild]
	Gtk.ColorButton color_selector;

	[GtkChild]
	Gtk.Button width_button;

	public RGBA color {
		get { return color_selector.get_rgba(); }
		set { color_selector.set_rgba(value); }
	}

	public double width { get; set; default = 12; }

	protected Markup()
	{
		this.setup_width_button(this.width_button);
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

	public void add_stroke(Stroke stroke)
	{
		this.strokes = (ArrayList<Stroke>) strokes[0:strokes.size+undo_index];
		this.strokes.add(stroke);

		this.undo_index = 0;
	}

	/* Canvas control */

    protected bool draw_canvas (Cairo.Context cr)	// Draws the DrawingArea inside us.
	{
        var w = this.canvas.get_allocated_width ();
        var h = this.canvas.get_allocated_height ();

		cr.set_line_join(Cairo.LineJoin.ROUND);
		cr.set_line_cap(Cairo.LineCap.ROUND);

		for (int i = 0; i < this.strokes.size + undo_index; i++)
		{
			strokes[i].draw(cr);
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
			this.add_stroke(this.current);
		}

        return false;
    }

	[GtkCallback]
    protected bool canvas_button_release (Gdk.EventButton event)
	{
		this.current = null;	// This stroke has finished.

        return false;
    }

	uint64 last_move_time;

	[GtkCallback]
    protected bool canvas_motion_notify (Gdk.EventMotion event)
	{
		if (this.current != null)
		{
			this.current.record(event.x, event.y);
			this.queue_draw();
		}
		else
		{
			this.tray.set_reveal_child(true);
			this.last_move_time = GLib.get_monotonic_time();

			wait.begin(5000, () => {
				if (GLib.get_monotonic_time() - this.last_move_time > 5000 * 1000) {
					this.tray.set_reveal_child(false);
				}
			});
		}

        return false;
    }

	/* Tray callbacks */

	[GtkCallback]
	void undo()
	{
		if (-this.undo_index < this.strokes.size)
		{
			this.undo_index--;
			this.queue_draw();
		}
	}

	[GtkCallback]
	void redo()
	{
		if (this.undo_index < 0)
		{
			this.undo_index++;
			this.queue_draw();
		}
	}

	/* Misc. */

	int? width_drag_start_y = null;
	double old_width;
	uint refresh_thread_id;

	void setup_width_button(Gtk.Button but)
	{
		but.draw.connect_after((cr) => {
			var w = this.width_button.get_allocated_width ();
			var h = this.width_button.get_allocated_height ();

			cr.set_source_rgb(1, 1, 1);
			cr.arc(w/2, h/2, this.width / 2, 0, Math.PI * 2);
			cr.fill();

			return false;
		});

		Gtk.drag_source_set(but, Gdk.ModifierType.BUTTON1_MASK, null, Gdk.DragAction.PRIVATE);

		but.drag_motion.connect((ctx, x, y) => {
			if (width_drag_start_y == null) {	// If this is the first motion event, store the start coordinate.
				width_drag_start_y = y;
				old_width = this.width;
			}

			this.width = old_width * Math.pow(1.1, (width_drag_start_y - y) / 20.0);
			this.width_button.queue_draw();
			return false;
		});

		but.drag_begin.connect((ctx) => {
			this.refresh_thread_id = GLib.Timeout.add(50, () => {	// We're not registered as a drag_dest, so we make our own trigger for the drag_motion callback that is run even when the drag is outside of the widget's bounds.
				int x; int y;
				ctx.get_device().get_position(null, out x, out y);
				but.drag_motion(ctx, x, y, 0);
				return true;
			});
		});

		but.drag_failed.connect((ctx, result) => {
			width_drag_start_y = null;
			GLib.Source.remove(refresh_thread_id);
			return true;
		});
	}
}

RGBA parse_rgba(string text)
{
	var color = RGBA();
	color.parse(text);
	return color;
}

async void wait(uint millis)
{
	GLib.Timeout.add(millis, () => {
		wait.callback();
		return false;	// Removes the source
	});
	yield;
}
