import "gtk" as gtk
import "timer" as timer

def hbox = gtk.box(gtk.GTK_ORIENTATION_HORIZONTAL, 0)

def window = gtk.window(gtk.GTK_WINDOW_TOPLEVEL)
window.title := "Timer Test"

window.connect("destroy", { gtk.main_quit })

def tickTimer = timer.every(1000) do { print "tick!" }
def tockTimer = timer.every(2000) do { print "tock!" }

def tickButton = gtk.button
tickButton.label := "Stop Tick"
tickButton.on "clicked" do {
   timer.stop(tickTimer)
}
hbox.add(tickButton)
 

def tockButton = gtk.button
tockButton.label := "Stop Tock"
tockButton.on "clicked" do {
   timer.stop(tockTimer)
}
hbox.add(tockButton)


window.add(hbox)
window.show_all

gtk.main
