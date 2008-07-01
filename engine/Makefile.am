# vim:set noet ts=4:
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

engine_m17n_PYTHON = \
	engine.py \
	factory.py \
	main.py \
	test.py \
	$(NULL)

engine_m17ndir = $(datadir)/ibus/engine/m17n

m17n_DATA = \
	m17n.py \
	$(NULL)

m17n_LTLIBRARIES = _m17n.la

m17ndir = @pyexecdir@

_m17n_la_SOURCES = \
	$(NULL)

nodist__m17n_la_SOURCES = \
	m17n_wrap.c \
	$(NULL)

_m17n_la_CFLAGS = \
	@M17N_CFLAGS@ \
	@PYTHON_CFLAGS@ \
	$(NULL)

_m17n_la_LDFLAGS = \
	@M17N_LIBS@ \
	-rpath $(m17ndir) \
	-avoid-version \
	-module \
	$(NULL)

libexec_SCRIPTS = ibus-engine-m17n

m17n.py m17n_wrap.c: m17n.i
	$(SWIG) -python -I/usr/include -o m17n_wrap.c $(srcdir)/m17n.i

test: all
	$(ENV) PYTHONPATH=$(builddir)/.libs $(PYTHON) $(srcdir)/main.py $(TEST_ARGS)

EXTRA_DIST = \
	m17n.i \
	ibus-engine-m17n.in \
	$(NULL)

CLEANFILES = \
	m17n.py \
	m17n_wrap.* \
	*.pyc \
	$(MULL)

DISTCLEANFILES = \
	$(MULL)
