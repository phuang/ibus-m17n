import sys
import m17n

class Engine:
	def __init__ (self):
		self._im = m17n.MInputMethod ("zh", "pinyin")
		self._ic = self._im.create_ic ()

		self._ic.set_callback (m17n.Minput_preedit_start.name (), self._input_preedit_start_cb)
		self._ic.set_callback (m17n.Minput_preedit_done.name (), self._input_preedit_done_cb)
		self._ic.set_callback (m17n.Minput_preedit_draw.name (), self._input_preedit_draw_cb)
		
		self._ic.set_callback (m17n.Minput_status_start.name (), self._input_states_start_cb)
		self._ic.set_callback (m17n.Minput_status_done.name (), self._input_states_done_cb)
		self._ic.set_callback (m17n.Minput_status_draw.name (), self._input_states_draw_cb)
		
		self._ic.set_callback (m17n.Minput_candidates_start.name (), self._input_candidates_start_cb)
		self._ic.set_callback (m17n.Minput_candidates_done.name (), self._input_candidates_done_cb)
		self._ic.set_callback (m17n.Minput_candidates_draw.name (), self._input_candidates_draw_cb)
		
		self._ic.set_callback (m17n.Minput_set_spot.name (), self._input_set_spot_cb)
		self._ic.set_callback (m17n.Minput_toggle.name (), self._input_toggle_cb)
		self._ic.set_callback (m17n.Minput_reset.name (), self._input_reset_cb)

		self._ic.set_callback (m17n.Minput_get_surrounding_text.name (), self._input_get_surrounding_text_cb)
		self._ic.set_callback (m17n.Minput_delete_surrounding_text.name (), self._input_delete_surrounding_text_cb)


	def _input_preedit_start_cb (self, command):
		print >> sys.stderr, command
	def _input_preedit_done_cb (self, command):
		print >> sys.stderr, command
	def _input_preedit_draw_cb (self, command):
		print >> sys.stderr, command, self._ic.preedit
	
	def _input_states_start_cb (self, command):
		print >> sys.stderr, command
	def _input_states_done_cb (self, command):
		print >> sys.stderr, command
	def _input_states_draw_cb (self, command):
		print >> sys.stderr, command, self._ic.status
	
	def _input_candidates_start_cb (self, command):
		print >> sys.stderr, command
	def _input_candidates_done_cb (self, command):
		print >> sys.stderr, command
	def _input_candidates_draw_cb (self, command):
		print >> sys.stderr, command, self._ic.candidates_show
		for x in self._ic.candidates:
			print >> sys.stderr, " ===="
			for c in x:
				print >> sys.stderr, c

	def _input_set_spot_cb (self, command):
		print >> sys.stderr, command
	def _input_toggle_cb (self, command):
		print >> sys.stderr, command
	def _input_reset_cb (self, command):
		print >> sys.stderr, command

	def _input_get_surrounding_text_cb (self, command):
		print >> sys.stderr, command
	def _input_delete_surrounding_text_cb (self, command):
		print >> sys.stderr, command

	def _page_up (self):
		pass

	def _page_down (self):
		pass

	def _cursor_up (self):
		pass

	def _cursor_down (self):
		pass

	def _process_key_event (self, keyval, is_press, state):
		if not is_press:
			return False
		symbol = chr (keyval)
		if keyval == ord (' '):
			symbol = "space"
		self._ic.filter (symbol)
		lookup = self._ic.lookup (symbol)
		print >> sys.stderr, "lookup = \"%s|%s\"" % (lookup, type (lookup))
		# ignore key release events

		return True

	def _property_activate (self, prop_name, state):
		pass

	def _update_property (self, prop):
		self.UpdateProperty (prop.to_dbus_value ())

eng = Engine ()
eng._process_key_event (ord('z'), 1, 0)
eng._process_key_event (ord('h'), 1, 0)
eng._process_key_event (ord('o'), 1, 0)
eng._process_key_event (ord('n'), 1, 0)
eng._process_key_event (ord('g'), 1, 0)
eng._process_key_event (ord(' '), 1, 0)


