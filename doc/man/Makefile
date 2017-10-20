#
# "Rsyphon"
#
#  Copyright (C) 2002 Hewlett-Packard Company <dannf@fc.hp.com>
#  Copyright (C) 2002 Bald Guy Software <brian.finley@baldguysoftware.com>
#
#    $Id$
#


DESTDIR = 
PREFIX = /usr
USR = $(DESTDIR)$(PREFIX)

SYSTEMIMAGER_VERSION = $(shell cat ../../VERSION)

MANPAGES = $(SERVER_MAN) $(SERVER_POD_MAN) $(CLIENT_MAN) $(COMMON_MAN)

SERVER_MAN = rsaddclients.8 				\
			rsgetimage.8					\
			rsmkautoinstallcd.8			\
			rsmkautoinstallscript.8		\
			rsmkdhcpserver.8				\
			rsmkdhcpstatic.8				\
			rscpimage.8					\
			rsmvimage.8					\
			rsrmimage.8					\
			rsmkbootserver.8				\
			rsyphon.conf.5			\
			rsyphon-rsyncd.conf.5	\
			rsmkrsyncd_conf.8				\
			rsmkclientnetboot.8				\
			rsmkbootpackage.8		\
			\
			rsinstallbtimage.8		\
			rsmonitor.8			\
			rsmonitortk.8			\
			rspcp.8			\
			rspsh.8			\
			rspushinstall.8		\
			rspushoverrides.8		\
			rsmkautoinstalldisk.8		\
			rsnetbootmond.8		\
			rsclusterconfig.8		\
			rspushupdate.8

CLIENT_MAN = rsprepareclient.8 rsupdateclient.8

COMMON_MAN = autoinstallscript.conf.5 rslsimage.8

.SUFFIXES: .5 .8 .8.gz .5.gz .pod .sgml

all:	compress

%.gz:	%
	gzip -9 < $< > $@

rsyphon.conf.5:	rsyphon.conf.pod
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 5 -c "Rsyphon" $< $@

rsyphon-rsyncd.conf.5:	rsyphon-rsyncd.conf.pod
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 5 -c "Rsyphon" $< $@

rsinstallbtimage.8: $(TOPDIR)/sbin/rsinstallbtimage
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rsmonitor.8: $(TOPDIR)/sbin/rsmonitor
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rsmonitortk.8: $(TOPDIR)/sbin/rsmonitortk
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rspcp.8: $(TOPDIR)/sbin/rspcp
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rspsh.8: $(TOPDIR)/sbin/rspsh
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rspushinstall.8: $(TOPDIR)/sbin/rspushinstall
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rspushoverrides.8: $(TOPDIR)/sbin/rspushoverrides
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rsmkautoinstalldisk.8: $(TOPDIR)/sbin/rsmkautoinstalldisk
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rsnetbootmond.8: $(TOPDIR)/sbin/rsnetbootmond
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rsclusterconfig.8: $(TOPDIR)/sbin/rsclusterconfig
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rspushupdate.8: $(TOPDIR)/sbin/rspushupdate
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

%.5 %.8:	%.sgml %.content.sgml
	docbook2man $<
	mv $(shell echo $@ | tr '[:lower:]' '[:upper:]') $@

install_all:	install_common_man install_server_man install_client_man

manpages:	$(MANPAGES)

compress:	$(foreach file, $(MANPAGES), $(file).gz)

install_common_man:	$(foreach file, $(COMMON_MAN), $(file).gz)
	$(foreach manpage, $(COMMON_MAN), \
	  install -D -m 644 $(manpage).gz \
	    $(USR)/share/man/man`echo $(manpage) | \
	    sed 's/.*\(.\)$$/\1/'`/$(manpage).gz ;)

install_server_man:	$(foreach file, $(SERVER_MAN), $(file).gz)
	$(foreach manpage, $(SERVER_MAN), \
	  install -D -m 644 $(manpage).gz \
	    $(USR)/share/man/man`echo $(manpage) | \
	    sed 's/.*\(.\)$$/\1/'`/$(manpage).gz ;)

install_client_man:	$(foreach file, $(CLIENT_MAN), $(file).gz)
	$(foreach manpage, $(CLIENT_MAN), \
	  install -D -m 644 $(manpage).gz \
	    $(USR)/share/man/man`echo $(manpage) | \
	    sed 's/.*\(.\)$$/\1/'`/$(manpage).gz ;)

clean:
	rm -f *~ \#*\# *.8 *.5 *.gz manpage.links manpage.refs
