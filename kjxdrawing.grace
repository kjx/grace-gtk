// GTK+ 3 drawing example (not compatible with GTK+ 2)
import "gtk" as gtk
import "gdk" as gdk
import "sys" as sys

if (gtk.GTK_MAJOR_VERSION != 3) then {
    print "Error: This example is only compatible with GTK+ 3."
    print "drawing2.grace is the GTK+ 2 version of the drawing sample."
    // sys.exit(1)
}

def window = gtk.window(gtk.GTK_WINDOW_TOPLEVEL)
window.title := "Simple drawing demo"

window.set_default_size(400, 300)
window.add_events(gdk.GDK_BUTTON_PRESS_MASK)
window.add_events(gdk.GDK_BUTTON1_MOTION_MASK)
def button = gtk.button
button.label := "Change colour"

def vbox = gtk.box(gtk.GTK_ORIENTATION_VERTICAL, 6)

def da = gtk.drawing_area
da.set_size_request(400, 300)
vbox.add(da)
vbox.add(button)
window.add(vbox)
window.on "destroy" do { gtk.main_quit }
def accelgroup = gtk.accel_group
accelgroup.accel_connect(gdk.GDK_KEY_Escape, { gtk.main_quit })
window.add_accel_group(accelgroup)

da.app_paintable := true

// Helper to simplify the code below
method rectangleAt(x', y')sized(w', h')coloured(r', g', b') {
    object {
        def x is public, readable = x'
        def y is public, readable = y'
        def w is public, readable = w'
        def h is public, readable = h'
        def r is public, readable = r'
        def g is public, readable = g'
        def b is public, readable = b'
    }
}
def rectangles = [rectangleAt(20, 20)sized(50, 50)coloured(1, 0, 0)]

var curR := 1
var curG := 0
var curB := 0
button.on "clicked" do {
    def tmp = curR
    curR := curB
    curB := curG
    curG := tmp

    print "making dialog"
    def dialog = gtk.file_chooser_dialog ("Open File",
                                      0,
                                      gtk.GTK_FILE_CHOOSER_ACTION_OPEN,
                                      "gtk-cancel", gtk.GTK_RESPONSE_CANCEL,
                                      "gtk-open", gtk.GTK_RESPONSE_ACCEPT)

    print "running dialog!"
    print (dialog.run)
    print "done dialog!"
    dialog.destroy
}

da.on "draw" do { c->
    print "draw: {rectangles.size}"
    c.set_source_rgb(0,0,0)
    c.rectangle(0,0,1000,1000)
    c.fill
    for (rectangles) do {rect->
        c.set_source_rgb(rect.r, rect.g, rect.b)
        c.rectangle(rect.x, rect.y, rect.w, rect.h)
        c.fill
    }
    c.select_font_face("Blox brk",0,0)
    c.font_size:=100
    c.move_to(100,100)
    c.set_source_rgb(1,1,1)
    c.show_text("Hello World")
    
    def tx = c.text_extents("Hello World")

    print "x_bearing {tx.x_bearing}"
    print "y_bearing {tx.y_bearing}"
    print "witdh {tx.width}"
    print "height {tx.height}"

    c.rectangle(100 - tx.x_bearing,
                100 + tx.y_bearing,
                tx.width,
                tx.height)
    c.stroke
}

window.on "motion-notify-event" do {e->
    print "motion notify ({e.x}@{e.y})"
    rectangles.push(rectangleAt(e.x, e.y)sized(10, 10)coloured(curR, curG, curB))
    da.queue_draw
}

window.show_all

gtk.main
