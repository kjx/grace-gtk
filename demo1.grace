// GTK+ 3 drawing example (not compatible with GTK+ 2)
import "gtk" as gtk
import "gdk" as gdk
import "sys" as sys
import "mgcollections" as col

if (gtk.GTK_MAJOR_VERSION != 3) then {
    print "Error: This example is only compatible with GTK+ 3."
    print "drawing2.grace is the GTK+ 2 version of the drawing sample."
    // sys.exit(1)
}

def window = gtk.window(gtk.GTK_WINDOW_TOPLEVEL)
window.title := "-P-W-E-I-"

//window.fullscreen
window.add_events(gdk.GDK_BUTTON_PRESS_MASK)
window.add_events(gdk.GDK_BUTTON_RELEASE_MASK)
window.add_events(gdk.GDK_BUTTON1_MOTION_MASK)

def WINDOW_WIDTH =  640
def WINDOW_HEIGHT = 480

var mouseGrab := 0

window.on "destroy" do { gtk.main_quit }

window.on "button-press-event"  do {e->
          processButtonPressEvent(e)
}


method processButtonPressEvent(e) {
    transcript "button-press"
    for (displayList) do {morf->
        transcript "button-press morf {morf}"
        if (morf.handlePress(e)) then {
                transcript "have the button"        
                mouseGrab := morf 
                transcript "returning..."                        
                return
                }
    }
    mouseGrab:= 0
}

window.on "button-release-event"  do {e->
          transcript "button-release!"
          if (mouseGrab != 0) then {mouseGrab.handleRelease(e)}
          mouseGrab := 0
}

window.on "motion-notify-event" do {e->
    transcript "Motion {e.x}@{e.y}"
    da.queue_draw
}


def da = gtk.drawing_area
da.set_size_request(WINDOW_WIDTH, WINDOW_HEIGHT)
da.app_paintable := true
window.add(da)

def displayList = col.list.new

da.on "draw" do { c->
    transcript "draw"
    c.set_source_rgb(0,0,0)
    c.rectangle(0,0,WINDOW_WIDTH,WINDOW_HEIGHT)
    c.fill

    for (displayList) do {morf->
        morf.draw(c)
    }
}

def accelgroup = gtk.accel_group
accelgroup.accel_connect(gdk.GDK_KEY_Escape, { gtk.main_quit })
window.add_accel_group(accelgroup)






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
        method draw(c) { 
            c.set_source_rgb(r, g, b)
            c.rectangle(x, y, w, h)
            c.fill
        }

    }
}



class Morf.new(x',y') {
  def x is readable = x'
  def y is readable = y'
  var width is readable,writable := 0
  var height is readable,writable := 0
  var active is readable := false

  displayList.push(self)

//hook methods
  method draw(c) {
    transcript "Morf {self} draw"
  }
  method click(e) {
    transcript "Morf {self} click"
  }

//template methods
  method handlePress(e) {
    transcript "Morf {self} handlePress"
    if ((e.x >= x) && (e.x <= (x+width)) && (e.y >= y) && (e.y <= (y+height))) 
      then { 
         transcript "Morf {self} accepting the press"
         active := true
         da.queue_draw
         return true
      }
    return false
  }

  method handleRelease(e) { // sent only to the mouseGrabed widget!
    transcript "Morf {self} handleRelease"
    if ((e.x >= x) && (e.x <= (x+width)) && (e.y >= y) && (e.y <= (y+height)))
      then { 
           if (!active) then {return 0}   // indicates a bug?
           click(e)
           }
    active := false  // should end up unwind-protected
    da.queue_draw
    }
}



class Button.new(x'',y'',text',action') {
  inherits Morf.new(x'',y'') 
  var text is readable := text'    
  var action := action'

  method draw(c) {
    transcript "Button {text} draw"
    c.select_font_face("Blox brk",0,0)
    c.font_size:=25

    def tx = c.text_extents(text)
    width := tx.width
    height := tx.height

    c.move_to(x + tx.x_bearing, y - tx.y_bearing)

    if (active) then {c.set_source_rgb(1,0,0)} else {c.set_source_rgb(1,1,1)}
    c.show_text(text)
    c.rectangle(x,
                y,
                tx.width,,
                tx.height)
    c.stroke
  }
  method click(e) {
    transcript "DOIT DOIT DOIT {text}"
    action.apply
  }
}



def transcriptList = col.list.new
def transcriptSize = 30
for (1..transcriptSize) do {n->transcriptList.push("")}
var transcriptRingIndex:= transcriptSize

method transcript (s : String) {
       transcriptRingIndex:=(transcriptRingIndex % transcriptSize) + 1
       transcriptList[transcriptRingIndex]:=s
//     da.queue_draw
}

class Transcript.new(xx,yy) {
  inherits Morf.new(xx,yy)

  method draw(c) {
    c.select_font_face("fixed",0,0)
    c.font_size:=20

    def tx = c.text_extents("XXXXXXXXXXXXXXXXXXXX")
    def twidth = tx.width
    def theight = tx.height * 1.2
    def alpha_min = 0.3
    def alpha_scale = 1.0 - alpha_min

    for (1..transcriptSize) do { ycursor ->
       c.move_to(x, (ycursor*theight) + y - tx.y_bearing)
       c.set_source_rgba(0,0,1, (alpha_min + (alpha_scale * ycursor / transcriptSize ) ))
       c.show_text(transcriptList[((ycursor + transcriptRingIndex) %transcriptSize) + 1])
    }

  }
}



class Bars.new(xx,yy,width',height',collection) {
  inherits Morf.new(xx,yy)
  // assumes collection of size numbers from 1..size 
  width := width'
  height := height'  

  method scale(x) from (left) to (right) {left + x * right}

  method draw(c) {
    def size = collection.size
    
    c.select_font_face("fixed",0,0)
    c.font_size:=20

    def width_per_pixel = width / size
    def height_per_bar  = height / size 

    def rmin = 0.25
    def rmax = 1
    def bmin = 1
    def bmax = 0.25
    def gmin = 0.5
    def gmax = 0.5

    for (1..size) do { ycursor ->
       def scale = collection[ycursor] / size 
       def r = scale(scale) from(rmin) to(rmax)
       def b = scale(scale) from(bmin) to(bmax)
       def g = scale(scale) from(gmin) to(gmax)
       c.set_source_rgb(r,g,b)
       c.rectangle(x, (ycursor*height_per_bar) + y,
                   width_per_pixel * collection[ycursor], height_per_bar)
       c.fill
    }

  }
}

Transcript.new(400,-10)

Button.new(10,100,"pUSH mE",{transcript "push"})
Button.new(10,200,"Launch or Lunch",{transcript "lunch"})
Button.new(10,400,"amadeus",{transcript "mozart"})

method fill (collection,size) {
  for (1..size) do {n->collection.push(n)}
}

def sortme = col.list.new
fill(sortme,100)


Bars.new(100,100,500,500, sortme)

window.show_all

gtk.main
