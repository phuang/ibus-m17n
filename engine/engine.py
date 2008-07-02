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

import gobject
import pango
import dbus
import ibus
import m17n
from ibus import keysyms
from ibus import modifier
from ibus import interface

_ = lambda a: a

class Engine (interface.IEngine):
	def __init__ (self, ic, dbusconn, object_path):
		interface.IEngine.__init__ (self, dbusconn, object_path)
		self._dbusconn = dbusconn
		self._ic = ic

		# setup preedit callbacks
		self._ic.set_callback (m17n.Minput_preedit_start,
					self._input_preedit_start_cb)
		self._ic.set_callback (m17n.Minput_preedit_done,
					self._input_preedit_done_cb)
		self._ic.set_callback (m17n.Minput_preedit_draw,
					self._input_preedit_draw_cb)

		# setup status callbacks
		self._ic.set_callback (m17n.Minput_status_start,
					self._input_states_start_cb)
		self._ic.set_callback (m17n.Minput_status_done,
					self._input_states_done_cb)
		self._ic.set_callback (m17n.Minput_status_draw,
					self._input_states_draw_cb)

		# setup candidates callbacks
		self._ic.set_callback (m17n.Minput_candidates_start,
					self._input_candidates_start_cb)
		self._ic.set_callback (m17n.Minput_candidates_done,
					self._input_candidates_done_cb)
		self._ic.set_callback (m17n.Minput_candidates_draw,
					self._input_candidates_draw_cb)

		# setup other callbacks
		self._ic.set_callback (m17n.Minput_set_spot,
					self._input_set_spot_cb)
		self._ic.set_callback (m17n.Minput_toggle,
					self._input_toggle_cb)
		self._ic.set_callback (m17n.Minput_reset,
					self._input_reset_cb)

		# setup surrounding text callbacks
		self._ic.set_callback (m17n.Minput_get_surrounding_text,
					self._input_get_surrounding_text_cb)
		self._ic.set_callback (m17n.Minput_delete_surrounding_text,
					self._input_delete_surrounding_text_cb)

		self._lookup_table = ibus.LookupTable (page_size = 10)

	def _input_preedit_start_cb (self, command):
		print command

	def _input_preedit_done_cb (self, command):
		print command

	def _input_preedit_draw_cb (self, command):
		attrs = ibus.AttrList ()
		preedit_len = len (self._ic.preedit)
		attrs.append (ibus.AttributeBackground (ibus.RGB (0, 0, 0), 0, preedit_len))
		attrs.append (ibus.AttributeForeground (ibus.RGB (255, 255, 255), 0, preedit_len))
		self.UpdatePreedit (self._ic.preedit,
				attrs.to_dbus_value (),
				self._ic.cursor_pos,
				preedit_len > 0)

	def _input_states_start_cb (self, command):
		print command, self._ic.status
	def _input_states_done_cb (self, command):
		print command, self._ic.status
	def _input_states_draw_cb (self, command):
		print command, self._ic.status

	def _input_candidates_start_cb (self, command):
		self._lookup_table.clean ()
		self.UpdateLookupTable (self._lookup_table.to_dbus_value (), False)
		self.UpdateAuxString ("",
				ibus.AttrList ().to_dbus_value (),
				False)

	def _input_candidates_done_cb (self, command):
		self._lookup_table.clean ()
		self.UpdateLookupTable (self._lookup_table.to_dbus_value (), False)
		self.UpdateAuxString ("",
				ibus.AttrList ().to_dbus_value (),
				False)

	def _input_candidates_draw_cb (self, command):
		self._lookup_table.clean ()

		m17n_candidates = self._ic.candidates
		if not m17n_candidates:
			self.UpdateLookupTable (self._lookup_table.to_dbus_value (), False)
			self.UpdateAuxString ("",
					ibus.AttrList ().to_dbus_value (),
					False)
			return

		for group in m17n_candidates:
			for c in group:
				self._lookup_table.append_candidate (c)

		self._lookup_table.set_cursor_pos (self._ic.candidate_index)

		aux_string = "(%d / %d)" % (self._ic.candidate_index + 1,
				len (self._lookup_table))

		self.UpdateLookupTable (self._lookup_table.to_dbus_value (),
				self._ic.candidates_show)

		self.UpdateAuxString (aux_string,
				ibus.AttrList ().to_dbus_value (),
				self._ic.candidates_show)

	def _input_set_spot_cb (self, command):
		print command
	def _input_toggle_cb (self, command):
		print command
	def _input_reset_cb (self, command):
		print command

	def _input_get_surrounding_text_cb (self, command):
		print command
	def _input_delete_surrounding_text_cb (self, command):
		print command

	def _page_up (self):
		return self._m17n_process_key ("Up")

	def _page_down (self):
		return self._m17n_process_key ("Down")

	def _cursor_up (self):
		return self._m17n_process_key ("Left")

	def _cursor_down (self):
		return self._m17n_process_key ("Right")

	def _m17n_process_key (self, key):
		if self._ic.filter (key) != 0:
			return True

		text = self._ic.lookup (key)

		if text == None:
			return False

		if text:
			self.CommitString (text)

		return True

	def _keyval_to_symbol (self, keyval, state):
		mask = 0
		if keyval >= keysyms.space and keyval <= keysyms.asciitilde:
			if keyval == keysyms.space and state & modifier.SHIFT_MASK:
				mask |= modifier.SHIFT_MASK
			if state & modifier.CONTROL_MASK:
				if keyval >= ord ('a') and keyval <= ord ('z'):
					keyval += ord('A') - ord ('a')
				mask |= modifier.CONTROL_MASK
			key = chr(keyval)
		elif keyval >= keysyms.Shift_L and keyval <= keysyms.Hyper_R:
			return None
		else:
			key = keysyms.keycode_to_name (keyval)

		mask |= state & (modifier.ALT_MASK | modifier.META_MASK)
		if mask & modifier.SHIFT_MASK:
			key = "S-" + key
		if mask & modifier.CONTROL_MASK:
			key = "C-" + key
		if mask & modifier.META_MASK:
			key = "M-" + key
		if mask & modifier.ALT_MASK:
			key = "A-" + key

		return key


	def _process_key_event (self, keyval, is_press, state):
		if not is_press:
			return False
		key = self._keyval_to_symbol (keyval, state)

		if key == None:
			return False
		return self._m17n_process_key (key)

	def _property_activate (self, prop_name, state):
		pass

	def _update_property (self, prop):
		self.UpdateProperty (prop.to_dbus_value ())

	# methods for dbus rpc
	def ProcessKeyEvent (self, keyval, is_press, state):
		try:
			return self._process_key_event (keyval, is_press, state)
		except Exception, e:
			print e
		return False

	def FocusIn (self):
		print "FocusIn"

	def FocusOut (self):
		print "FocusOut"

	def SetCursorLocation (self, x, y, w, h):
		pass

	def Reset (self):
		print "Reset"

	def PageUp (self):
		self._page_up ()

	def PageDown (self):
		self._page_down ()

	def CursorUp (self):
		self._cursor_up ()

	def CursorDown (self):
		self._cursor_down ()

	def SetEnable (self, enable):
		self._enable = enable
		pass

	def PropertyActivate (self, prop_name, prop_state):
		self._property_activate (prop_name, prop_state)

	def Destroy (self):
		print "Destroy"
		self.remove_from_connection ()
		self._dbsuconn = None
		self._ic = None

