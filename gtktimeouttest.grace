import "gtk" as gtk

if (gtk.GTK_MAJOR_VERSION != 3) then {
    Error.raise "wrong GTK Version"
}

def hbox = gtk.box(gtk.GTK_ORIENTATION_HORIZONTAL, 0)

def window = gtk.window(gtk.GTK_WINDOW_TOPLEVEL)
window.title := "Timer Test"

window.connect("destroy", { gtk.main_quit })

def tickTimer = gtk.timeout_add(1000, { print "tick!"; true })
def tockTimer = gtk.timeout_add_seconds(2, { print "tock!"; true })

def tickButton = gtk.button
tickButton.label := "Stop Tick"
tickButton.on "clicked" do {
   gtk.source_remove(tickTimer)
}
hbox.add(tickButton)


def tockButton = gtk.button
tockButton.label := "Stop Tock"
tockButton.on "clicked" do {
   gtk.source_remove(tockTimer)
}
hbox.add(tockButton)
 
window.add(hbox)
window.show_all

gtk.main
