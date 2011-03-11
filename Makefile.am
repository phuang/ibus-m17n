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

SUBDIRS = \
	src \
	icons \
	m4 \
	po \
	$(NULL)

ACLOCAL_AMFLAGS = -I m4

EXTRA_DIST = \
	autogen.sh \
	@PACKAGE_NAME@.spec.in \
	$(NULL)

noinst_DIST = \
	$(NULL)


DISTCLEANFILES = \
	po/stamp-it \
	$(NULL)

rpm: dist @PACKAGE_NAME@.spec
	rpmbuild -bb \
			--define "_sourcedir `pwd`" \
			--define "_builddir `pwd`" \
			--define "_srcrpmdir `pwd`" \
			--define "_rpmdir `pwd`" \
			--define "_specdir `pwd`" \
			@PACKAGE_NAME@.spec

srpm: dist @PACKAGE_NAME@.spec
	rpmbuild -bs \
			--define "_sourcedir `pwd`" \
			--define "_builddir `pwd`" \
			--define "_srcrpmdir `pwd`" \
			--define "_rpmdir `pwd`" \
			--define "_specdir `pwd`" \
			@PACKAGE_NAME@.spec

clean-rpm:
	$(RM) -r "`uname -i`"

.PHONY: debian/changelog
debian/changelog:
	$(AM_V_GEN) \
	( \
		date=`date -R`; \
		version=@VERSION@; \
		serie=$(serie); \
		if test -z "$$serie"; then \
		  serie=maverick; \
		fi; \
		if test -z "$$release"; then \
		  release=1; \
		fi; \
		s=`cat debian/changelog.in`; \
		eval "echo \"$${s}\""; \
	) > $@

ppa: dist debian/changelog
	$(AM_V_GEN) \
	( \
		mkdir ppa; \
		cd ppa; \
		tar zxvf ../$(distdir).tar.gz ; \
		cd $(distdir); \
		cp -a ../../debian . ; \
		cd debian; \
		debuild -S -sa ; \
	)

dpkg: dist debian/changelog
	$(AM_V_GEN) \
	( \
		mkdir ppa; \
		cd ppa; \
		tar zxvf ../$(distdir).tar.gz ; \
		cd $(distdir); \
		cp -a ../../debian . ; \
		cd debian; \
		debuild -b ; \
	)

clean-local: clean-rpm
