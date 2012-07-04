#!/usr/bin/python3
# grace-gtk - GTK+ bindings for Grace
# Copyright (C) 2012 Michael Homer
# This is free software with ABSOLUTELY NO WARRANTY.
# See the GNU GPL 3 for details.

import sys
import re
import itertools
import os.path

class func(object):
    def __init__(self, name, returns, params):
        self.name = name
        self.returns = returns
        params = params.replace('\t', ' ')
        self.params = list(filter(lambda x: x != '',
                                  map(str.strip, params.split(','))))

methods = {}
enums = []
classes = {}
constructors = []
usedconstructors = []
classallocators = set()

if len(sys.argv) < 2:
    sys.stderr.write("Usage: " + sys.argv[0] + ' <path-to-gtk.h>\n')
    sys.stderr.write("Generates a glue module for GTK+ and Grace.\n")
    sys.stderr.write("Copyright (C) 2012 Michael Homer\n")
    sys.stderr.write("This is free software with ABSOLUTELY NO WARRANTY.\n")
    exit(0)

basedir = os.path.dirname(os.path.dirname(sys.argv[1])) + '/'

kinds = set([
    'void', 'GtkWidget*', 'const gchar *', 'const gchar*', 'gboolean',
    'GtkWidget *'
])

included = set(['gtk/gtkaccelmap.h', 'gtk/gtkaboutdialog.h',
                'gtk/gtkscalebutton.h', 'gtk/gtktreeitem.h',
                'gtk/gtktext.h', 'gtk/gtktree.h'])

def stripcomments(s):
    return re.sub(r'/\*.+?\*/', '', s, 0, re.DOTALL)

def include_file(path):
    if path not in included:
        included.add(path)
        if os.path.exists(basedir + path):
            process_file(basedir + path)

def process_file(fn):
    logical_lines = []
    with open(fn) as fp:
        data = fp.read()
    data = stripcomments(data)
    logical_lines = data.split(";")
    for inc in re.findall('#include <(.+?)>', data):
        include_file(inc)
    for enm in re.findall(r'typedef enum.+?;', data, re.DOTALL):
        m = re.match('[^{]*\\{([^}]+)\\}', stripcomments(enm))
        if m is not None:
            enums.extend(list(map(str.strip,
                            map(lambda x: x.partition('=')[0],
                                map(stripcomments,
                                        re.sub('#.*', '',m.group(1)).split(
                                            ','))))))
    for line in logical_lines:
        line = line.replace('\n', '')
        for k in kinds:
            if line.startswith(k) and '(' in line:
                name = line[len(k):].strip().split(' ', 1)[0]
                if '\t' in name:
                    name = name.partition('\t')[0]
                if not name:
                    continue
                if name.startswith('gdk_') or name.startswith('_'):
                    continue
                if (name == 'gtk_widget_destroyed'
                    or name == 'gtk_rc_set_default_files'
                    or name == 'gtk_icon_theme_set_search_path'):
                    continue
                methods[name] = func(name, k,
                                     line.split('(', 1)[1].split(')', 1)[0])

process_file(sys.argv[1])

class FailedCoerce(Exception):
    pass

def coerce2gtk(dest, src):
    if '*' in dest:
        dest = dest.replace('\t', ' ')
        dest = re.sub(' +', ' ', dest.partition('*')[0].strip()) + ' *'
    else:
        dest = dest.rpartition(' ')[0].strip()
    if dest == 'const gchar *' or dest == 'const gchar*':
        return '(const gchar *)grcstring(' + src + ')'
    elif dest == 'gboolean':
        return '(gboolean)istrue(' + src + ')'
    elif dest.endswith('Type'):
        return 'integerfromAny(' + src + ')'
    elif dest == 'GtkWidget *' or dest == 'GtkWidget*':
        return '((struct GraceGtkWidget*)' + src + ')->widget'
    elif dest == 'gint':
        return 'integerfromAny(' + src + ')'
    else:
        raise FailedCoerce(dest)
        return '/*unknown: ' + dest + '*/ NULL'

def doconstructor(k, m):
    cls = k[4:-4]
    if 'GTK' + cls not in classallocators:
        return
    casts = []
    try:
        casts = list(map(lambda x: coerce2gtk(x[0], 'argv[' + str(x[1]) + ']'), 
                    zip(m.params, itertools.count())))
    except FailedCoerce as e:
        if m.params[0] != 'void':
            print("// Failed constructor " + k + ": could not coerce "
                  + e.args[0])
            return
    print("Object grace_" + k + "(Object self, int argc, int *argcv,")
    print("    Object *argv, int flags) {")
    if casts:
        print('    if (argc < 1 || argcv[0] < ' + str(len(casts)) + ')')
        print('        die("' + k[4:-4] + ' requires ' + str(len(casts))
              + ' arguments, got %i. Signature: ' + k[4:-4] + '('
              + ', '.join(m.params) + ').", argcv[0]);')
        print("    GtkWidget *w = " + k + "(" + ','.join(casts) + ');')
    else:
        print("    GtkWidget *w = " + k + "();")
    print("""
    Object o = alloc_obj(sizeof(struct GraceGtkWidget) - sizeof(struct Object),
         alloc_class_GTK""" + cls + """());
    struct GraceGtkWidget *ggw = (struct GraceGtkWidget *)o;
    ggw->widget = w;
    return o;""")
    print("}")
    usedconstructors.append(k)

print("""
// This file is generated by the grace-gtk wrapper. Modifications
// should be made to the wrapper script, not this file.
// grace-gtk was written by Michael Homer and is available from
// <https://github.com/mwh/grace-gtk>.
// This is free software with ABSOLUTELY NO WARRANTY.
""")
print("#include \"gracelib.h\"")
print("#include <gtk/gtk.h>")
print("#include <gdk/gdk.h>")
print("""
Object none;

struct GraceGtkWidget {
    int32_t flags;
    ClassData class;
    GtkWidget *widget;
};

Object Object_asString(Object, int nparts, int *argcv,
        Object*, int flags);
Object Object_Equals(Object, int, int*,
        Object*, int flags);
Object Object_NotEquals(Object, int, int*,
        Object*, int);

void grace_gtk_callback_block(GtkWidget *widget, gpointer block) {
    callmethod((Object)block, "apply", 0, NULL, NULL);
}
Object grace_g_signal_connect(Object self, int argc, int *argcv,
      Object *argv, int flags) {
    struct GraceGtkWidget *w = (struct GraceGtkWidget *)self;
    g_signal_connect(w->widget, grcstring(argv[0]),
      G_CALLBACK(grace_gtk_callback_block), argv[1]);
    return self;
}
""")

def coercereturn(m, s):
    if m.returns == 'const gchar *' or m.returns == 'const gchar*':
        print("    return alloc_String(" + s + ");")
    else:
        print("    " + s + ";")
        print("    return none;")

def classof(k):
    cls = ''
    if k.startswith('gtk_accel_group_'):
        cls = 'accel_group'
    elif k.startswith('gtk_drawing_area_'):
        cls = 'drawing_area'
    else:
        cls = k.split('_')[1]
    if cls not in classes:
        classes[cls] = []
    return cls

for k, m in methods.items():
    selftype = ''.join(m.params[0].partition('*')[0:2])
    if k.endswith('_new'):
        constructors.append(k)
        classof(k)
        continue
    elif selftype != 'void' and not selftype.endswith('*'):
        continue
    try:
        casts = list(map(lambda x: coerce2gtk(x[0], 'argv[' + str(x[1]) + ']'), 
                    zip(m.params[1:], itertools.count())))
    except FailedCoerce as e:
        print("// Failed " + k + ": could not coerce " + e.args[0])
        print("// " + str(m.params))
        continue
    print("Object grace_" + k + "(Object self, int argc, int *argcv, "
          + "Object *argv, int flags) {")
    if selftype == 'void':
        print("  " + k + "(" + ','.join(casts) + ');')
        print("  return none;")
    else:
        print("  {} s = ({})(((struct GraceGtkWidget *)self)->widget);".format(selftype, selftype))
        if casts:
            print('    if (argc < 1 || argcv[0] < ' + str(len(casts)) + ')')
            print('        die("GTK method requires ' + str(len(casts))
                  + ' arguments, got %i. Signature: ' + k + '('
                  + ', '.join(m.params[1:]) + ').", argcv[0]);')
            coercereturn(m, "  " + k + "(s, " + ','.join(casts) + ')')
        else:
            coercereturn(m, "  " + k + "(s)")
    print("}")
    cls = classof(k)
    classes[cls].append(k)

for cls in classes:
    if cls != 'widget' and cls != 'container':
        if 'widget' in classes:
            classes[cls].extend(classes['widget'])
        if 'container' in classes:
            classes[cls].extend(classes['container'])

for cls in classes:
    classallocators.add('GTK' + cls)
    print("ClassData GTK" + cls + ";")
    print("ClassData alloc_class_GTK" + cls + "() {")
    print("  if (GTK" + cls + ") return GTK" + cls + ";")
    print("  GTK{} = alloc_class(\"{}\", {});".format(cls, cls,
                                                      5+len(classes[cls])))
    print("  gc_root((Object)GTK" + cls + ");")
    print("""add_Method(GTK""" + cls + """, "==", &Object_Equals);
    add_Method(GTK""" + cls + """, "!=", &Object_NotEquals);
    add_Method(GTK""" + cls + """, "asString", &Object_asString);
    add_Method(GTK""" + cls + """, "on()do", &grace_g_signal_connect);
    add_Method(GTK""" + cls + """, "connect", &grace_g_signal_connect);""")
    for k in classes[cls]:
        gnm = k.split('_', 2)[-1]
        if gnm.startswith('get_') and len(methods[k].params) == 1:
            gnm = gnm[4:]
        elif gnm.startswith('set_') and len(methods[k].params) == 2:
            gnm = gnm[4:] + ":="
        print("  add_Method(GTK{}, \"{}\", &grace_{});".format(cls, 
            gnm, k))
    print("  return GTK" + cls + ";")
    print("}")

for con in constructors:
    doconstructor(con, methods[con])

for x in enums:
    print("Object grace_gtk_" + x + "(Object self, int argc, int *argcv,")
    print("    Object *args, int flags) {")
    print("    return alloc_Float64(" + x + ");")
    print("}")

gtk_size = len(classes) + len(enums) + 3
print("""
Object gtkmodule;
Object module_gtk_init() {
    if (gtkmodule)
        return gtkmodule;
    int n = 0;
    gtk_init(&n, NULL);
    ClassData c = alloc_class("Module<gtk>", """ + str(gtk_size) + ");")
for x in enums:
    print("    add_Method(c, \"" + x + "\", &grace_gtk_" + x + ");")
for x in usedconstructors:
    cls = x[4:-4]
    print("    add_Method(c, \"" + cls + "\", &grace_" + x + ");")
print("    add_Method(c, \"main\", &grace_gtk_main);")
print("    add_Method(c, \"main_quit\", &grace_gtk_main_quit);")
print("    add_Method(c, \"connect\", &grace_g_signal_connect);")
print("    gtkmodule = alloc_obj(sizeof(Object), c);")
print("    return gtkmodule;")
print("}")
