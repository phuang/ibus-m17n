# vim:set et sts=4 sw=4:
# -*- coding: utf-8 -*-
#
# ibus-m17n - The m17n engine for IBus
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

import sys
import ibus
import m17n
import engine

FACTORY_PATH = "/com/redhat/IBus/engines/m17n/%s/%s/Factory"
ENGINE_PATH = "/com/redhat/IBus/engines/m17n/%s/%s/Engine/"

class EngineFactory(ibus.EngineFactoryBase):
    AUTHORS = "Huang Peng <shawn.p.huang@gmail.com>"
    CREDITS = "GPLv2"

    def __init__(self, lang, name, bus):
        icon = m17n.minput_get_icon(lang, name)
        if not icon:
            icon = "ibus"
        self.__info = [name, lang, icon, self.AUTHORS, self.CREDITS]
        self.__im = m17n.MInputMethod(lang, name)

        factory_path = FACTORY_PATH % (lang, name.replace("-", "_"))
        engine_path = ENGINE_PATH % (lang, name.replace("-", "_"))
        engine_class = lambda *args, **kargs: engine.Engine (self.__im.create_ic(), *args, **kargs)
        super(EngineFactory,self).__init__(self.__info, engine_class, engine_path, bus, factory_path)

        self.__factory_path = factory_path

    def get_object_path(self):
        return self.__factory_path

