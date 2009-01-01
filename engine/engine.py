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

import ibus
import m17n
from ibus import keysyms
from ibus import modifier

_ = lambda a: a

class Engine(ibus.EngineBase):
    def __init__(self, ic, bus, object_path):
        super(Engine, self).__init__(bus, object_path)
        self.__ic = ic
        self.__prop_list = ibus.PropList()

        # init input mode properties
        self.__status_prop = ibus.Property(name = u"status",
                            type = ibus.PROP_TYPE_NORMAL,
                            label = u"",
                            tooltip = _(u"m17n status"),
                            visible = False)

        self.__prop_list.append(self.__status_prop)

        # setup preedit callbacks
        self.__ic.set_callback(m17n.Minput_preedit_start,
                    self.__input_preedit_start_cb)
        self.__ic.set_callback(m17n.Minput_preedit_done,
                    self.__input_preedit_done_cb)
        self.__ic.set_callback(m17n.Minput_preedit_draw,
                    self.__input_preedit_draw_cb)

        # setup status callbacks
        self.__ic.set_callback(m17n.Minput_status_start,
                    self.__input_states_start_cb)
        self.__ic.set_callback(m17n.Minput_status_done,
                    self.__input_states_done_cb)
        self.__ic.set_callback(m17n.Minput_status_draw,
                    self.__input_states_draw_cb)

        # setup candidates callbacks
        self.__ic.set_callback(m17n.Minput_candidates_start,
                    self.__input_candidates_start_cb)
        self.__ic.set_callback(m17n.Minput_candidates_done,
                    self.__input_candidates_done_cb)
        self.__ic.set_callback(m17n.Minput_candidates_draw,
                    self.__input_candidates_draw_cb)

        # setup other callbacks
        self.__ic.set_callback(m17n.Minput_set_spot,
                    self.__input_set_spot_cb)
        self.__ic.set_callback(m17n.Minput_toggle,
                    self.__input_toggle_cb)
        self.__ic.set_callback(m17n.Minput_reset,
                    self.__input_reset_cb)

        # setup surrounding text callbacks
        self.__ic.set_callback(m17n.Minput_get_surrounding_text,
                    self.__input_get_surrounding_text_cb)
        self.__ic.set_callback(m17n.Minput_delete_surrounding_text,
                    self.__input_delete_surrounding_text_cb)

        self.__lookup_table = ibus.LookupTable(page_size = 10)

    def process_key_event(self, keyval, is_press, state):
        if not is_press:
            return False
        key = self.__keyval_to_symbol(keyval, state)

        if key == None:
            return False
        return self.__m17n_process_key(key)

    def property_activate(self, prop_name, state):
        pass

    def reset(self):
        print "Reset"

    def focus_in(self):
        self.register_properties(self.__prop_list)
        return self.__m17n_process_key("input-focus-in")

    def focus_out(self):
        return self.__m17n_process_key("input-focus-out")

    def page_up(self):
        return self.__m17n_process_key("Up")

    def page_down(self):
        return self.__m17n_process_key("Down")

    def cursor_up(self):
        return self.__m17n_process_key("Left")

    def cursor_down(self):
        return self.__m17n_process_key("Right")


    def __input_preedit_start_cb(self, command):
        print command

    def __input_preedit_done_cb(self, command):
        print command

    def __input_preedit_draw_cb(self, command):
        attrs = ibus.AttrList()
        preedit_len = len(self.__ic.preedit)
        attrs.append(ibus.AttributeBackground(ibus.RGB(0, 0, 0), 0, preedit_len))
        attrs.append(ibus.AttributeForeground(ibus.RGB(255, 255, 255), 0, preedit_len))
        self.update_preedit(self.__ic.preedit,
                attrs,
                self.__ic.cursor_pos,
                preedit_len > 0)

    def __input_states_start_cb(self, command):
        print command, self.__ic.status
    def __input_states_done_cb(self, command):
        print command, self.__ic.status
    def __input_states_draw_cb(self, command):
        self.__status_prop.label = self.__ic.status
        if self.__ic.status:
            self.__status_prop.visible = True
        else:
            self.__status_prop.visible = False
        self.update_property(self.__status_prop)

    def __input_candidates_start_cb(self, command):
        self.__lookup_table.clean()
        self.hide_lookup_table()
        self.hide_aux_string()

    def __input_candidates_done_cb(self, command):
        self.__lookup_table.clean()
        self.hide_lookup_table()
        self.hide_aux_string()

    def __input_candidates_draw_cb(self, command):
        self.__lookup_table.clean()

        m17n_candidates = self.__ic.candidates
        if not m17n_candidates:
            self.hide_lookup_table()
            self.hide_aux_string()
            return

        for group in m17n_candidates:
            for c in group:
                self.__lookup_table.append_candidate(c)

        self.__lookup_table.set_cursor_pos(self.__ic.candidate_index)

        aux_string = "(%d / %d)" % (self.__ic.candidate_index + 1,
                len(self.__lookup_table))
        self.update_lookup_table(self.__lookup_table,
                self.__ic.candidates_show)

        self.update_aux_string(aux_string,
                ibus.AttrList(),
                self.__ic.candidates_show)

    def __input_set_spot_cb(self, command):
        print command
    def __input_toggle_cb(self, command):
        print command
    def __input_reset_cb(self, command):
        print command

    def __input_get_surrounding_text_cb(self, command):
        print command
    def __input_delete_surrounding_text_cb(self, command):
        print command


    def __m17n_process_key(self, key):
        ret = self.__ic.filter(key)

        if ret:
            return True

        ret, text = self.__ic.lookup(key)

        if text:
            self.commit_string(text)

        return ret == 0

    def __keyval_to_symbol(self, keyval, state):
        mask = 0
        if keyval >= keysyms.space and keyval <= keysyms.asciitilde:
            if keyval == keysyms.space and state & modifier.SHIFT_MASK:
                mask |= modifier.SHIFT_MASK
            if state & modifier.CONTROL_MASK:
                if keyval >= ord('a') and keyval <= ord('z'):
                    keyval += ord('A') - ord('a')
                mask |= modifier.CONTROL_MASK
            key = chr(keyval)
        elif keyval >= keysyms.Shift_L and keyval <= keysyms.Hyper_R:
            return None
        else:
            key = keysyms.keycode_to_name(keyval)

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



