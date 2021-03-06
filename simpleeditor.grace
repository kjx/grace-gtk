import "gtk" as gtk
import "io" as io
import "sys" as sys

var vbox
if (gtk.GTK_MAJOR_VERSION == 3) then {
    vbox := gtk.box(gtk.GTK_ORIENTATION_VERTICAL, 0)
} else {
    vbox := gtk.vbox(false, 0)
}

def window = gtk.window(gtk.GTK_WINDOW_TOPLEVEL)
window.title := "Simple Grace Editor"

var filename := "testfile.grace"
def textView = gtk.text_view
textView.set_size_request(400,400)
if (sys.argv.size > 1) then {
    def fp = io.open(sys.argv.at(2), "r")
    def s = fp.read
    textView.buffer.set_text(s, -1)
    fp.close
    filename := sys.argv.at(2)
}
textView.buffer.on "changed" do {
    window.title := "Simple Grace Editor (unsaved changes)"
}
def scrolledWindow = gtk.scrolled_window
scrolledWindow.set_size_request(400, 400)
scrolledWindow.add(textView)
def button = gtk.button
button.label := "Run"

button.on "clicked" do {
    // These have to be created first, then populated by
    // passing them in. There are several get_iter methods
    // on the buffer.
    def st = gtk.text_iter
    def en = gtk.text_iter
    textView.buffer.get_iter_at_offset(st, 0)
    // -1 for the offset means after the last character
    textView.buffer.get_iter_at_offset(en, -1)
    // Between start and end, including hidden characters.
    def s = textView.buffer.get_text(st, en, true)
    def fp = io.open(filename, "w")
    fp.write(s)
    fp.close
    window.title := "Simple Grace Editor"
    io.system("../minigrace/minigrace \"{filename}\" > .graceedit-tmp 2> .graceedit-errors")
    def op = io.open(".graceedit-tmp", "r")
    def output = op.read
    op.close
    def ep = io.open(".graceedit-errors", "r")
    def errors = ep.read
    ep.close
    io.system("rm -f .graceedit-tmp .graceedit-errors")
    if (errors.size > 0) then {
        def errorswindow = gtk.window(gtk.GTK_WINDOW_TOPLEVEL)
        errorswindow.title := "Errors"
        def errorsTextView = gtk.text_view
        errorswindow.add(errorsTextView)
        errorsTextView.set_size_request(200, 200)
        errorsTextView.buffer.set_text(errors, -1)
        def ost = gtk.text_iter
        def oen = gtk.text_iter
        errorsTextView.buffer.get_iter_at_offset(ost, 0)
        errorsTextView.buffer.get_iter_at_offset(oen, -1)
        def tag = errorsTextView.buffer.create_tag("fixed", "foreground", "red")
        errorsTextView.buffer.apply_tag(tag, ost, oen)
        errorsTextView.editable := false
        errorswindow.show_all
    }
    if (output.size > 0) then {
        def outputwindow = gtk.window(gtk.GTK_WINDOW_TOPLEVEL)
        outputwindow.title := "Output"
        def outputTextView = gtk.text_view
        outputwindow.add(outputTextView)
        outputTextView.set_size_request(200, 200)
        outputTextView.buffer.set_text(output, -1)
        outputTextView.editable := false
        outputwindow.show_all
    }
}
vbox.pack_start(scrolledWindow, true, true, 0)
vbox.add(button)

window.add(vbox)

window.connect("destroy", { gtk.main_quit })

window.show_all

gtk.main
