PYTHON_VERSION=3
GTK_VERSION=3.0
INCLUDE_DIR=/usr/local/include/
HEADER_LOCATION=$(INCLUDE_DIR)/gtk-$(GTK_VERSION)
MINIGRACE_HEADERS=../minigrace
CAIRO_INCLUDE_DIR=$(INCLUDE_DIR)

PIXMAN_LDFLAGS=-L/usr/local/opt/pixman/lib
PIXMAN_CPPFLAGS=-I/usr/local/opt/pixman/include

PYTHON=python$(PYTHON_VERSION)

#On Jamess Mac
#PKG_CONFIG_PATH=/usr/local/opt/pixman/lib/pkgconfig:/usr/local/opt/cairo/lib/pkgconfig:/opt/X11/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/X11/lib/pkgconfig

include $(MINIGRACE_HEADERS)/Makefile.conf

all: gtk.gso gdk.gso cairo.gso
gtk.c: gwrap.py
	$(PYTHON) gwrap.py $(HEADER_LOCATION)/gtk/gtk.h > gtk.c

gtk.gso: gtk.c
	gcc -Wall -o gtk.gso -I$(MINIGRACE_HEADERS) $(PIXMAN_CPPFLAGS) `pkg-config --cflags gtk+-$(GTK_VERSION)` $(UNICODE_LDFLAGS) -fPIC -shared gtk.c `pkg-config --libs gtk+-$(GTK_VERSION)`  $(PIXMAN_LDFLAGS)

gdk.c: gwrap.py
	$(PYTHON) gwrap.py $(HEADER_LOCATION)/gdk/gdk.h $(HEADER_LOCATION)/gdk/gdkkeysyms.h > gdk.c

gdk.gso: gdk.c
	gcc -Wall -o gdk.gso -I$(MINIGRACE_HEADERS)  $(PIXMAN_CPPFLAGS) `pkg-config --cflags gtk+-$(GTK_VERSION)` $(UNICODE_LDFLAGS) -fPIC -shared gdk.c `pkg-config --libs gtk+-$(GTK_VERSION)` $(PIXMAN_LDFLAGS)

cairo.c: gwrap.py
	$(PYTHON) gwrap.py $(CAIRO_INCLUDE_DIR)/cairo/cairo.h > cairo.c

cairo.gso: cairo.c
	gcc -Wall -o cairo.gso -I$(MINIGRACE_HEADERS)  $(PIXMAN_CPPFLAGS) `pkg-config --cflags gtk+-$(GTK_VERSION)` $(UNICODE_LDFLAGS) -fPIC -shared cairo.c `pkg-config --libs gtk+-$(GTK_VERSION)` $(PIXMAN_LDFLAGS)

clean:
	rm -f gtk.gso gtk.c
	rm -f gdk.gso gdk.c
	rm -f cairo.gso cairo.c
	rm -f helloworld helloworld.c helloworld.gcn helloworld.gct
	rm -f drawing drawing.c drawing.gcn drawing.gct
	rm -f drawing2 drawing2.c drawing2.gcn drawing2.gct
	rm -f greet greet.c greet.gcn greet.gct
	rm -f simpleeditor simpleeditor.c simpleeditor.gcn simpleeditor.gct
	rm -f pngviewer pngviewer.c pngviewer.gcn pngviewer.gct

.PHONY: clean all
