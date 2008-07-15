# vim:set et sts=4 sw=4:
# -*- coding: utf-8 -*-
#
# ibus-anthy - The Anthy engine for IBus
#
# Copyright (c) 2007-2008 Huang Peng <shawn.p.huang@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

class Application:
    def __init__ (self, methods):
        self._loop = gobject.MainLoop ()
        self._dbusconn = dbus.connection.Connection (ibus.IBUS_ADDR)
        self._dbusconn.add_signal_receiver (self._disconnected_cb, 
                            "Disconnected", 
                            dbus_interface = dbus.LOCAL_IFACE)
        self._ibus = self._dbusconn.get_object (ibus.IBUS_NAME, ibus.IBUS_PATH)

        self._methods = []
        self._factories = []
        for lang, name in methods:
            try:
                f = factory.EngineFactory (lang, name, self._dbusconn)
                self._factories.append (f)
            except Exception, e:
                print e
        if self._factories:
            self._ibus.RegisterFactories (map (lambda f: f.get_object_path (), self._factories), **ibus.DEFAULT_ASYNC_HANDLERS)

    def run (self):
        self._loop.run ()

    def _disconnected_cb (self):
        print "disconnected"
        self._loop.quit ()


def launch_engine (methods):
    dbus.mainloop.glib.DBusGMainLoop (set_as_default=True)
    IMApp (methods).run ()

def print_help (out, v = 0):
    print >> out, "-h, --help             show this message."
    print >> out, "-d, --daemonize        daemonize ibus"
    print >> out, "-l, --list             list all m17n input methods"
    sys.exit (v)

def list_m17n_ims ():
    print "list all m17n input methods:"
    print "\tlang\tname -- title"
    for name, lang in m17n.minput_list_ims ():
        print "\t%s\t%s -- %s" % (lang, name, m17n.minput_get_title (lang, name))
    sys.exit (0)

def main ():
    daemonize = False
    shortopt = "hdla"
    longopt = ["help", "daemonize", "list", "all"]
    all_methods = False
    methods = []

    try:
        opts, args = getopt.getopt (sys.argv[1:], shortopt, longopt)
    except getopt.GetoptError, err:
        print_help (sys.stderr, 1)

    for o, a in opts:
        if o in ("-h", "--help"):
            print_help (sys.stdout)
        elif o in ("-d", "--daemonize"):
            daemonize = True
        elif o in ("-l", "--list"):
            list_m17n_ims ()
        elif o in ("-a", "--all"):
            all_methods = True
        else:
            print >> sys.stderr, "Unknown argument: %s" % o
            print_help (sys.stderr, 1)

    if daemonize:
        if os.fork ():
            sys.exit ()
    if all_methods:
        methods = map (lambda im: (im[1], im[0]), m17n.minput_list_ims ())
    else:
        for m in args:
            lang, names = m.split (":")
            for name in names.split (","):
                methods.append ((lang, name))

    launch_engine (methods)

if __name__ == "__main__":
    main ()
