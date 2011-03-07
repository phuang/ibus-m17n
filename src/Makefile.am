# vim:set noet ts=4:
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

AM_CFLAGS = \
	@IBUS_CFLAGS@ \
	@M17N_CFLAGS@ \
	-DPKGDATADIR=\"$(pkgdatadir)\" \
	-DLIBEXECDIR=\"$(libexecdir)\" \
	-DSETUPDIR=\"$(setupdir)\" \
	$(NULL)
AM_LDADD = \
	@IBUS_LIBS@ \
	@M17N_LIBS@ \
	$(NULL)

check_PROGRAMS = \
	test-m17n \
	$(NULL)

TESTS = \
	$(check_PROGRAMS) \
	$(NULL)


test_m17n_SOURCES = \
	m17nutil.c \
	$(NULL)
test_m17n_CFLAGS = \
	$(AM_CFLAGS) \
	-DDEBUG \
	$(NULL)
test_m17n_LDADD = \
	libm17ncommon.a	\
	$(AM_LDADD) \
	$(NULL)

libexec_PROGRAMS = ibus-engine-m17n

noinst_LIBRARIES = libm17ncommon.a

libm17ncommon_a_SOURCES = \
	m17nutil.c \
	m17nutil.h \
	$(NULL)
libm17ncommon_a_LIBADD = $(LIBOBJS)

ibus_engine_m17n_SOURCES = \
	main.c \
	engine.c \
	engine.h \
	$(NULL)
ibus_engine_m17n_LDADD = \
	libm17ncommon.a \
	@IBUS_LIBS@ \
	@M17N_LIBS@ \
	$(NULL)

if HAVE_GTK
libexec_PROGRAMS += ibus-setup-m17n

ibus_setup_m17n_SOURCES = \
	setup.c \
	$(NULL)
ibus_setup_m17n_CFLAGS = \
	@GTK_CFLAGS@ \
	$(AM_CFLAGS) \
	$(NULL)
ibus_setup_m17n_LDADD = \
	libm17ncommon.a \
	@IBUS_LIBS@ \
	@M17N_LIBS@ \
	@GTK_LIBS@ \
	$(NULL)
dist_setup_DATA = \
	ibus-m17n-preferences.ui \
	$(NULL)
endif

setup_DATA = \
	default.xml \
	$(NULL)
setupdir = $(pkgdatadir)/setup

component_DATA = \
	m17n.xml \
	$(NULL)
componentdir = @datadir@/ibus/component

EXTRA_DIST = \
	m17n.xml.in.in \
	default.xml.in \
	$(NULL)

DISTCLEANFILES = \
	m17n.xml.in \
	default.xml.in \
	$(NULL)

CLEANFILES = \
	m17n.xml \
	default.xml \
	$(NULL)

m17n.xml: m17n.xml.in
default.xml: default.xml.in

SUFFIXES = .xml.in .xml
.xml.in.xml:
	$(AM_V_GEN) \
	( \
		libexecdir=${libexecdir}; \
		pkgdatadir=${pkgdatadir}; \
		setupdir=${setupdir}; \
		s=`cat $<`; \
		eval "echo \"$${s}\""; \
	) > $@

test: ibus-engine-m17n
	$(builddir)/ibus-engine-m17n
