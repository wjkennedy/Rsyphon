#
# "Rsyphon"
#


DESTDIR = 
PREFIX = /usr
USR = $(DESTDIR)$(PREFIX)

SYSTEMIMAGER_VERSION = $(shell cat ../../VERSION)

MANPAGES = $(SERVER_MAN) $(SERVER_POD_MAN) $(CLIENT_MAN) $(COMMON_MAN)

SERVER_MAN = rs_addclients.8 				\
			rs_getimage.8					\
			rs_mkautoinstallcd.8			\
			rs_mkautoinstallscript.8		\
			rs_mkdhcpserver.8				\
			rs_mkdhcpstatic.8				\
			rs_cpimage.8					\
			rs_mvimage.8					\
			rs_rmimage.8					\
			rs_mkbootserver.8				\
			rs_yphon.conf.5			\
			rs_yphon-rs_yncd.conf.5	\
			rs_mkrs_yncd_conf.8				\
			rs_mkclientnetboot.8				\
			rs_mkbootpackage.8		\
			rs_installbtimage.8		\
			rs_monitor.8			\
			rs_monitortk.8			\
			rs_pcp.8			\
			rs_psh.8			\
			rs_pushinstall.8		\
			rs_pushoverrides.8		\
			rs_mkautoinstalldisk.8		\
			rs_netbootmond.8		\
			rs_clusterconfig.8		\
			rs_pushupdate.8

CLIENT_MAN = rs_prepareclient.8 rs_updateclient.8

COMMON_MAN = autoinstallscript.conf.5 rs_lsimage.8

.SUFFIXES: .5 .8 .8.gz .5.gz .pod .sgml

all:	compress

%.gz:	%
	gzip -9 < $< > $@

rs_yphon.conf.5:	rs_yphon.conf.pod
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 5 -c "Rsyphon" $< $@

rs_yphon-rs_yncd.conf.5:	rs_yphon-rs_yncd.conf.pod
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 5 -c "Rsyphon" $< $@

rs_installbtimage.8: $(TOPDIR)/sbin/rs_installbtimage
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rs_monitor.8: $(TOPDIR)/sbin/rs_monitor
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rs_monitortk.8: $(TOPDIR)/sbin/rs_monitortk
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rs_pcp.8: $(TOPDIR)/sbin/rs_pcp
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rs_psh.8: $(TOPDIR)/sbin/rs_psh
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rs_pushinstall.8: $(TOPDIR)/sbin/rs_pushinstall
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rs_pushoverrides.8: $(TOPDIR)/sbin/rs_pushoverrides
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rs_mkautoinstalldisk.8: $(TOPDIR)/sbin/rs_mkautoinstalldisk
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rs_netbootmond.8: $(TOPDIR)/sbin/rs_netbootmond
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rs_clusterconfig.8: $(TOPDIR)/sbin/rs_clusterconfig
	pod2man --release=$(SYSTEMIMAGER_VERSION) -s 8 -c "Rsyphon" $< $@

rs_pushupdate.8: $(TOPDIR)/sbin/rs_pushupdate
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
