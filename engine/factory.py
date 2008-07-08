# vim:set noet ts=4:
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

import sys
import m17n
from ibus import interface
import engine
import gobject

FACTORY_PATH = "/com/redhat/IBus/engines/m17n/%s/%s/Factory"
ENGINE_PATH = "/com/redhat/IBus/engines/m17n/%s/%s/Engine/%d"

class EngineFactory (interface.IEngineFactory):
	AUTHORS = "Huang Peng <shawn.p.huang@gmail.com>"
	CREDITS = "GPLv2"
	__factory_count = 0

	def __init__ (self, lang, name, dbusconn):
		self._engine_name = name
		self._lang = lang
		self._object_path = FACTORY_PATH % (lang, self._engine_name.replace ("-", "_"))
		
		interface.IEngineFactory.__init__ (self, dbusconn, object_path = self._object_path)
		self._im = m17n.MInputMethod (lang, name)
		
		self._icon = "ibus-m17n"
		self._dbusconn = dbusconn
		self._max_engine_id = 1

		EngineFactory.__factory_count += 1

	def get_object_path (self):
		return self._object_path
	
	def GetInfo (self):
		result = [
			self._engine_name,
			self._lang,
			self._icon,
			self.AUTHORS,
			self.CREDITS
			]
		return result

	def CreateEngine (self):
		engine_path = ENGINE_PATH % (self._lang, self._engine_name.replace ("-", "_"), self._max_engine_id)
		self._max_engine_id += 1
		ic = self._im.create_ic ()
		return engine.Engine (ic, self._dbusconn, engine_path)

	def Destroy (self):
		self.remove_from_connection ()
		self._im = None
		self._dbusconn = None
		EngineFactory.__factory_count -= 1
		if EngineFactory.__factory_count == 0:
			sys.exit (0)

