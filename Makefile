#
#	"Rsyphon"  
#
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
# ERRORS when running make:
#   If you encounter errors when running "make", because make couldn't find
#   certain things that it needs, and you are fortunate enough to be building
#   on a Debian system, you can issue the following command to ensure that
#   all of the proper tools are installed.
#
#   On Debian, "apt-get build-dep rsyphon ; apt-get install wget libssl-dev", will 
#   install all the right tools.  Note that you need the deb-src entries in 
#   your /etc/apt/sources.list file.
#
#
# Rsyphon file location standards:
#   o images will be stored in: /var/lib/rsyphon/images/
#   o autoinstall scripts:      /var/lib/rsyphon/scripts/
#   o tarball files for BT:     /var/lib/rsyphon/tarballs/
#   o torrent files:            /var/lib/rsyphon/torrents/
#   o override directories:     /var/lib/rsyphon/overrides/
#
#   o web gui pages:            /usr/share/rsyphon/web-gui/
#
#   o kernels:                  /usr/share/rsyphon/boot/`arch`/flavor/
#   o initrd.img:               /usr/share/rsyphon/boot/`arch`/flavor/
#   o boel_binaries.tar.gz:     /usr/share/rsyphon/boot/`arch`/flavor/
#
#   o perl libraries:           /%{perl_vendorlib}
#
#   o docs:                     Use distribution appropriate location.
#                               Defaults to /usr/share/doc/rsyphon/ 
#                               for installs from tarball or source.
#
#   o man pages:                /usr/share/man/man8/
#
#   o log files:                /var/log/rsyphon/
#
#   o configuration files:      /etc/rsyphon/
#   o rsyncd.conf:              /etc/rsyphon/rsyncd.conf
#   o rsyncd init script:       /etc/init.d/rsyphon
#   o netbootmond init script:  /etc/init.d/netbootmond
#   
#   o tftp files will be copied to the appropriate destination (as determined
#     by the local SysAdmin when running "rs_mkbootserver".
#
#   o user visible binaries:    /usr/bin
#     (rs_lsimage, rs_mkautoinstalldisk, rs_mkautoinstallcd)
#   o sysadmin binaries:        /usr/sbin
#     (all other binaries)
#
#
# Standards for pre-defined rsync modules:
#   o boot (directory that holds architecture specific directories with
#           boot files for clients)
#   o overrides
#   o scripts
#   o torrents
#
#

DESTDIR :=
VERSION := $(shell cat VERSION)

## is this an unstable release?
MINOR = $(shell echo $(VERSION) | cut -d "." -f 2)
UNSTABLE = 0
ifeq ($(shell echo "$(MINOR) % 2" | bc),1)
UNSTABLE = 1
endif

FLAVOR = $(shell cat FLAVOR)

TOPDIR  := $(CURDIR)

# RELEASE_DOCS are toplevel files that should be included with all posted
# tarballs, but aren't installed onto the destination machine by default
RELEASE_DOCS = CHANGE.LOG COPYING CREDITS README.md VERSION

ARCH = $(shell uname -m | sed -e s/i.86/i386/ -e s/sun4u/sparc64/ -e s/arm.*/arm/ -e s/sa110/arm/)

# Follows is a set of arch manipulations to distinguish between ppc types
ifeq ($(ARCH),ppc64)

# Check if machine is Playstation 3
IS_PS3 = $(shell grep -q PS3 /proc/cpuinfo && echo 1)
ifeq ($(IS_PS3),1)
        ARCH = ppc64-ps3
else
        IS_PPC64 := 1
        ifneq ($(shell ls /proc/iSeries 2>/dev/null),)
                ARCH = ppc64-iSeries
        endif
endif

endif

# is userspace 64bit
USERSPACE64 := 0
ifeq ($(ARCH),ia64)
	USERSPACE64 := 1
endif

ifeq ($(ARCH),x86_64)
        USERSPACE64 := 1
endif

ifneq ($(BUILD_ARCH),)
	ARCH := $(BUILD_ARCH)
endif

#
# To be used by "make" for rules that can take it!
NCPUS := $(shell egrep -c '^processor' /proc/cpuinfo )

MANUAL_DIR = $(TOPDIR)/doc/manual_source
MANPAGE_DIR = $(TOPDIR)/doc/man
PATCH_DIR = $(TOPDIR)/patches
LIB_SRC = $(TOPDIR)/lib
SRC_DIR = $(TOPDIR)/src
BINARY_SRC = $(TOPDIR)/sbin

# destination directories
PREFIX = /usr
ETC  = $(DESTDIR)/etc
INITD = $(ETC)/init.d
USR = $(DESTDIR)$(PREFIX)
DOC  = $(USR)/share/doc/rsyphon-doc
BIN = $(USR)/bin
SBIN = $(USR)/sbin
MAN8 = $(USR)/share/man/man8
LIBEXEC_DEST = $(USR)/lib/rsyphon
LIB_DEST = $(DESTDIR)$(shell perl -V:vendorlib | sed s/vendorlib=\'// | sed s/\'\;//)
#LIB_DEST = $(USR)/lib/rsyphon/perl
LOG_DIR = $(DESTDIR)/var/log/rsyphon
LOCK_DIR = $(DESTDIR)/var/lock/rsyphon

INITRD_DIR = $(TOPDIR)/initrd_source
INITRD_BUILD_DIR = $(INITRD_DIR)/build_dir

BOOT_BIN_DEST     = $(USR)/share/rsyphon/boot/$(ARCH)/$(FLAVOR)

PXE_CONF_SRC      = etc/pxelinux.cfg
PXE_CONF_DEST     = $(ETC)/rsyphon/pxelinux.cfg

KBOOT_CONF_SRC    = etc/kboot.cfg
KBOOT_CONF_DEST   = $(ETC)/rsyphon/kboot.cfg

BINARIES := rs_mkautoinstallcd rs_mkautoinstalldisk rs_psh rs_pcp rs_pushoverrides rs_clusterconfig
SBINARIES := rs_addclients rs_cpimage rs_getimage rs_mkdhcpserver rs_mkdhcpstatic rs_mkautoinstallscript rs_mkbootserver rs_mvimage rs_pushupdate rs_pushinstall rs_rmimage rs_mkrsyncd_conf rs_mkclientnetboot rs_netbootmond rs_mkbootpackage rs_monitor rs_monitortk rs_installbtimage
CLIENT_SBINARIES  := rs_updateclient rs_prepareclient
COMMON_BINARIES   = rs_lsimage

IMAGESRC    = $(TOPDIR)/var/lib/rsyphon/images
IMAGEDEST   = $(DESTDIR)/var/lib/rsyphon/images
WARNING_FILES = $(IMAGESRC)/README $(IMAGESRC)/CUIDADO $(IMAGESRC)/ACHTUNG
AUTOINSTALL_SCRIPT_DIR = $(DESTDIR)/var/lib/rsyphon/scripts
AUTOINSTALL_TORRENT_DIR = $(DESTDIR)/var/lib/rsyphon/torrents
AUTOINSTALL_TARBALL_DIR = $(DESTDIR)/var/lib/rsyphon/tarballs
OVERRIDES_DIR = $(DESTDIR)/var/lib/rsyphon/overrides
OVERRIDES_README = $(TOPDIR)/var/lib/rsyphon/overrides/README
FLAMETHROWER_STATE_DIR = $(DESTDIR)/var/state/rsyphon/flamethrower

RSYNC_STUB_DIR = $(ETC)/rsyphon/rsync_stubs

CHECK_FLOPPY_SIZE = expr \`du -b $(INITRD_DIR)/initrd.img | cut -f 1\` + \`du -b $(LINUX_IMAGE) | cut -f 1\`

RS_INSTALL = $(TOPDIR)/tools/rs_install --si-prefix=$(PREFIX)
GETSOURCE = $(TOPDIR)/tools/getsource

# Some root tools are probably needed to build Rsyphon packages, so
# explicitly add the right paths here. -AR-
PATH := $(PATH):/sbin:/usr/sbin:/usr/local/sbin

########################################################################
#
#  BEGIN Give friendly config and packages help. -BEF-
#
IS_CONFIGURED = $(shell test -e config.inc && echo 1 || echo 0)
ifeq ($(IS_CONFIGURED),0)

.PHONY:	all
all:	show_build_deps

else

	include config.inc
# build everything, install nothing
.PHONY:	all
all:	kernel $(INITRD_DIR)/initrd.img manpages


endif
#
#  END Give friendly config and packages help. -BEF-
#
########################################################################


binaries: $(BOEL_BINARIES_TARBALL) kernel $(INITRD_DIR)/initrd.img

# All has been modified as docs don't build on non debian platforms
#
#all:	$(BOEL_BINARIES_TARBALL) kernel $(INITRD_DIR)/initrd.img docs manpages

#
# Now include the other targets.  Some of these may have order dependencies.
# Order as appropriate. -BEF-
#
# Why does ordered dependencies matter? Make will read all these
# snippets before it evaluates the rule. If there are dependencies caused
# by setting a variable in one and using it in another, then that should be
# abstracted out. Its much more robust to include *.rul... -dannf
#
include $(TOPDIR)/make.d/kernel.rul
include $(TOPDIR)/initrd_source/initrd.rul

# a complete server install
.PHONY:	install_server_all
install_server_all:	install_server install_common install_binaries

# a complete client install
.PHONY:	install_client_all
install_client_all:	install_client install_common install_initrd_template

# install server-only architecture independent files
.PHONY:	install_server
install_server:	install_server_man 	\
				install_configs 	\
				install_server_libs \
				$(BITTORRENT_DIR).build
	$(RS_INSTALL) -d $(BIN)
	$(RS_INSTALL) -d $(SBIN)
	$(foreach binary, $(BINARIES), \
		$(RS_INSTALL) -m 755 $(BINARY_SRC)/$(binary) $(BIN);)
	$(foreach binary, $(SBINARIES), \
		$(RS_INSTALL) -m 755 $(BINARY_SRC)/$(binary) $(SBIN);)
	$(RS_INSTALL) -d -m 755 $(LOG_DIR)
	$(RS_INSTALL) -d -m 755 $(LOCK_DIR)
	$(RS_INSTALL) -d -m 755 $(BOOT_BIN_DEST)
	$(RS_INSTALL) -d -m 755 $(AUTOINSTALL_SCRIPT_DIR)

	$(RS_INSTALL) -d -m 755 $(AUTOINSTALL_TARBALL_DIR)
	$(RS_INSTALL) -d -m 755 $(AUTOINSTALL_TORRENT_DIR)

	$(RS_INSTALL) -d -m 755 $(AUTOINSTALL_SCRIPT_DIR)/pre-install
	$(RS_INSTALL) -m 644 --backup --text \
		$(TOPDIR)/var/lib/rsyphon/scripts/pre-install/99all.harmless_example_script \
		$(AUTOINSTALL_SCRIPT_DIR)/pre-install/
	$(RS_INSTALL) -m 644 --backup --text \
		$(TOPDIR)/var/lib/rsyphon/scripts/pre-install/README \
		$(AUTOINSTALL_SCRIPT_DIR)/pre-install/

	$(RS_INSTALL) -d -m 755 $(AUTOINSTALL_SCRIPT_DIR)/post-install
	$(RS_INSTALL) -m 644 --backup --text \
		$(TOPDIR)/var/lib/rsyphon/scripts/post-install/99all.harmless_example_script \
		$(TOPDIR)/var/lib/rsyphon/scripts/post-install/95all.monitord_rebooted \
		$(TOPDIR)/var/lib/rsyphon/scripts/post-install/10all.fix_swap_uuids\
                $(TOPDIR)/var/lib/rsyphon/scripts/post-install/11all.replace_byid_device\
		$(AUTOINSTALL_SCRIPT_DIR)/post-install/
	$(RS_INSTALL) -m 644 --backup --text \
		$(TOPDIR)/var/lib/rsyphon/scripts/post-install/README \
		$(AUTOINSTALL_SCRIPT_DIR)/post-install/

	$(RS_INSTALL) -d -m 755 $(OVERRIDES_DIR)
	$(RS_INSTALL) -m 644 $(OVERRIDES_README) $(OVERRIDES_DIR)

	$(RS_INSTALL) -d -m 755 $(PXE_CONF_DEST)
	$(RS_INSTALL) -m 644 --backup --text $(PXE_CONF_SRC)/message.txt \
		$(PXE_CONF_DEST)/message.txt
	$(RS_INSTALL) -m 644 --backup $(PXE_CONF_SRC)/syslinux.cfg \
		$(PXE_CONF_DEST)/syslinux.cfg
	$(RS_INSTALL) -m 644 --backup $(PXE_CONF_SRC)/syslinux.cfg.localboot \
		$(PXE_CONF_DEST)/syslinux.cfg.localboot
	$(RS_INSTALL) -m 644 --backup $(PXE_CONF_SRC)/syslinux.cfg.localboot \
		$(PXE_CONF_DEST)/default

	$(RS_INSTALL) -d -m 755 $(KBOOT_CONF_DEST)
#	$(RS_INSTALL) -m 644 --backup --text $(KBOOT_CONF_SRC)/message.txt \
#		$(KBOOT_CONF_DEST)/message.txt
	$(RS_INSTALL) -m 644 --backup $(KBOOT_CONF_SRC)/localboot \
		$(KBOOT_CONF_DEST)/
	$(RS_INSTALL) -m 644 --backup $(KBOOT_CONF_SRC)/default \
		$(KBOOT_CONF_DEST)/

	$(RS_INSTALL) -d -m 755 $(IMAGEDEST)
	$(RS_INSTALL) -m 644 $(WARNING_FILES) $(IMAGEDEST)
	cp -a $(IMAGEDEST)/README $(IMAGEDEST)/DO_NOT_TOUCH_THESE_DIRECTORIES

	$(RS_INSTALL) -d -m 755 $(FLAMETHROWER_STATE_DIR)

# install client-only files
.PHONY:	install_client
install_client: install_client_man install_client_libs
	mkdir -p $(ETC)/rsyphon
	$(RS_INSTALL) -b -m 644 etc/updateclient.local.exclude \
	  $(ETC)/rsyphon
	$(RS_INSTALL) -b -m 644 etc/client.conf \
	  $(ETC)/rsyphon
	mkdir -p $(SBIN)

	$(foreach binary, $(CLIENT_SBINARIES), \
		$(RS_INSTALL) -m 755 $(BINARY_SRC)/$(binary) $(SBIN);)

# install files common to both the server and client
.PHONY:	install_common
install_common:	install_common_man install_common_libs
	mkdir -p $(ETC)/rsyphon
	$(RS_INSTALL) -b -m 644 etc/UYOK.modules_to_exclude $(ETC)/rsyphon
	$(RS_INSTALL) -b -m 644 etc/UYOK.modules_to_include $(ETC)/rsyphon
	mkdir -p $(BIN)
	$(foreach binary, $(COMMON_BINARIES), \
		$(RS_INSTALL) -m 755 $(BINARY_SRC)/$(binary) $(BIN);)

# install server-only libraries
.PHONY:	install_server_libs
install_server_libs:
	mkdir -p $(LIB_DEST)/Rsyphon
	mkdir -p $(LIB_DEST)/BootMedia
	mkdir -p $(LIB_DEST)/BootGen/Dev
	mkdir -p $(LIB_DEST)/BootGen/InitrdFS
	$(RS_INSTALL) -m 644 $(LIB_SRC)/Rsyphon/Server.pm  $(LIB_DEST)/Rsyphon
	$(RS_INSTALL) -m 644 $(LIB_SRC)/Rsyphon/HostRange.pm  $(LIB_DEST)/Rsyphon
	$(RS_INSTALL) -m 644 $(LIB_SRC)/BootMedia/BootMedia.pm 	$(LIB_DEST)/BootMedia
	$(RS_INSTALL) -m 644 $(LIB_SRC)/BootMedia/MediaLib.pm 	$(LIB_DEST)/BootMedia
	$(RS_INSTALL) -m 644 $(LIB_SRC)/BootMedia/alpha.pm 	$(LIB_DEST)/BootMedia
	$(RS_INSTALL) -m 644 $(LIB_SRC)/BootMedia/i386.pm 	$(LIB_DEST)/BootMedia
	$(RS_INSTALL) -m 644 $(LIB_SRC)/BootGen/Dev.pm 		$(LIB_DEST)/BootGen/
	$(RS_INSTALL) -m 644 $(LIB_SRC)/BootGen/Dev/Devfs.pm 	$(LIB_DEST)/BootGen/Dev/
	$(RS_INSTALL) -m 644 $(LIB_SRC)/BootGen/Dev/Static.pm 	$(LIB_DEST)/BootGen/Dev/
	$(RS_INSTALL) -m 644 $(LIB_SRC)/BootGen/InitrdFS.pm 	$(LIB_DEST)/BootGen/
	$(RS_INSTALL) -m 644 $(LIB_SRC)/BootGen/InitrdFS/Cramfs.pm 	$(LIB_DEST)/BootGen/InitrdFS/
	$(RS_INSTALL) -m 644 $(LIB_SRC)/BootGen/InitrdFS/Ext2.pm 	$(LIB_DEST)/BootGen/InitrdFS/
	mkdir -p $(USR)/share/rsyphon/icons
	$(RS_INSTALL) -m 644 $(LIB_SRC)/icons/serverinit.gif	$(USR)/share/rsyphon/icons
	$(RS_INSTALL) -m 644 $(LIB_SRC)/icons/serverinst.gif 	$(USR)/share/rsyphon/icons
	$(RS_INSTALL) -m 644 $(LIB_SRC)/icons/serverok.gif 	$(USR)/share/rsyphon/icons
	$(RS_INSTALL) -m 644 $(LIB_SRC)/icons/servererror.gif 	$(USR)/share/rsyphon/icons

# install client-only libraries
.PHONY:	install_client_libs
install_client_libs:
	mkdir -p $(LIB_DEST)/Rsyphon
	$(RS_INSTALL) -m 644 $(LIB_SRC)/Rsyphon/Client.pm $(LIB_DEST)/Rsyphon

# install common libraries
.PHONY:	install_common_libs
install_common_libs:
	mkdir -p $(LIB_DEST)/Rsyphon
	$(RS_INSTALL) -m 644 $(LIB_SRC)/Rsyphon/Common.pm $(LIB_DEST)/Rsyphon
	$(RS_INSTALL) -m 644 $(LIB_SRC)/Rsyphon/Options.pm $(LIB_DEST)/Rsyphon
	$(RS_INSTALL) -m 644 $(LIB_SRC)/Rsyphon/Config.pm $(LIB_DEST)/Rsyphon
	$(RS_INSTALL) -m 644 $(LIB_SRC)/Rsyphon/UseYourOwnKernel.pm $(LIB_DEST)/Rsyphon
	mkdir -p $(LIBEXEC_DEST)
	$(RS_INSTALL) -m 755 $(LIB_SRC)/confedit $(LIBEXEC_DEST)

# checks the sized of the i386 kernel and initrd to make sure they'll fit 
# on an autoinstall diskette
.PHONY:	check_floppy_size
check_floppy_size:	$(LINUX_IMAGE) $(INITRD_DIR)/initrd.img
ifeq ($(ARCH), i386)
	@### see if the kernel and ramdisk are larger than the size of a 1.44MB
	@### floppy image, minus about 10k for syslinux stuff
	@echo -n "Ramdisk + Kernel == "
	@echo "`$(CHECK_FLOPPY_SIZE)`"
	@echo "                    1454080 is the max that will fit."
	@[ `$(CHECK_FLOPPY_SIZE)` -lt 1454081 ] || \
	     (echo "" && \
	      echo "************************************************" && \
	      echo "Dammit.  The kernel and ramdisk are too large.  " && \
	      echo "************************************************" && \
	      exit 1)
	@echo " - ok, that should fit on a floppy"
endif

# install the initscript & config files for the server
.PHONY:	install_configs
install_configs:
	$(RS_INSTALL) -d $(ETC)/rsyphon
	$(RS_INSTALL) -m 644 etc/rsyphon.conf $(ETC)/rsyphon/
	$(RS_INSTALL) -m 644 etc/flamethrower.conf $(ETC)/rsyphon/
	$(RS_INSTALL) -m 644 --backup etc/bittorrent.conf $(ETC)/rsyphon/
	$(RS_INSTALL) -m 644 --backup etc/cluster.xml $(ETC)/rsyphon/
	$(RS_INSTALL) -m 644 etc/autoinstallscript.template $(ETC)/rsyphon/
	$(RS_INSTALL) -m 644 etc/getimage.exclude $(ETC)/rsyphon/

	mkdir -p $(RSYNC_STUB_DIR)
	$(RS_INSTALL) -b -m 644 etc/rsync_stubs/10header $(RSYNC_STUB_DIR)
	[ -f $(RSYNC_STUB_DIR)/99local ] \
		&& $(RS_INSTALL) -b -m 644 etc/rsync_stubs/99local $(RSYNC_STUB_DIR)/99local.dist~ \
		|| $(RS_INSTALL) -b -m 644 etc/rsync_stubs/99local $(RSYNC_STUB_DIR)
	$(RS_INSTALL) -b -m 644 etc/rsync_stubs/README $(RSYNC_STUB_DIR)

	[ "$(INITD)" != "" ] || exit 1
	mkdir -p $(INITD)
	$(RS_INSTALL) -b -m 755 etc/init.d/rsyphon-server-rsyncd 			$(INITD)
	$(RS_INSTALL) -b -m 755 etc/init.d/rsyphon-server-netbootmond 		$(INITD)
	$(RS_INSTALL) -b -m 755 etc/init.d/rsyphon-server-flamethrowerd 	$(INITD)
	$(RS_INSTALL) -b -m 755 etc/init.d/rsyphon-server-bittorrent 	$(INITD)
	$(RS_INSTALL) -b -m 755 etc/init.d/rsyphon-server-monitord		$(INITD)

########## END initrd ##########


########## BEGIN dev_tarball ##########
# XXX deprecated -- no longer needed with udev. -BEF- 2011.02.15
########## END dev_tarball ##########


########## BEGIN man pages ##########
# build all of the manpages
.PHONY:	manpages install_server_man install_client_man install_common_man install_docs docs
ifeq ($(RS_BUILD_DOCS),1)
manpages:
	$(MAKE) -C $(MANPAGE_DIR) TOPDIR=$(TOPDIR)

# install the manpages for the server
install_server_man: manpages
	cd $(MANPAGE_DIR) && $(MAKE) install_server_man TOPDIR=$(TOPDIR) PREFIX=$(PREFIX) $@

# install the manpages for the client
install_client_man: manpages
	cd $(MANPAGE_DIR) && $(MAKE) install_client_man TOPDIR=$(TOPDIR) PREFIX=$(PREFIX) $@

# install manpages common to the server and client
install_common_man: manpages
	cd $(MANPAGE_DIR) && $(MAKE) install_common_man TOPDIR=$(TOPDIR) PREFIX=$(PREFIX) $@

########## END man pages ##########

# installs the manual and some examples
install_docs: docs
	mkdir -p $(DOC)
	cp -a $(MANUAL_DIR)/html $(DOC)
	cp $(MANUAL_DIR)/*.ps $(MANUAL_DIR)/*.pdf $(DOC)
	rsync -av --exclude 'CVS/' --exclude '.svn/' doc/examples/ $(DOC)/examples/
	#XXX $(RS_INSTALL) -m 644 doc/media-api.txt $(DOC)/

# builds the manual from SGML source
docs:
	$(MAKE) -C $(MANUAL_DIR) html ps pdf
endif

# pre-download the source to other packages that are needed by 
# the build system
.PHONY:	pre_download_source
pre_download_source:	$(ALL_SOURCE)

.PHONY:	get_source
get_source:	$(ALL_SOURCE)

.PHONY:	install
install:
	@echo ''
	@echo 'Try "make help", and/or read README for installation details.'
	@echo ''

.PHONY:	install_binaries
install_binaries:	install_kernel \
			install_initrd \
			install_initrd_template

.PHONY:	complete_source_tarball
complete_source_tarball:	$(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source.tar.bz2.sign
$(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source.tar.bz2.sign:	$(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source.tar.bz2
	cd $(TOPDIR)/tmp && gpg --detach-sign -a --output rsyphon-$(VERSION)-complete_source.tar.bz2.sign rsyphon-$(VERSION)-complete_source.tar.bz2
	cd $(TOPDIR)/tmp && gpg --verify rsyphon-$(VERSION)-complete_source.tar.bz2.sign 

$(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source.tar.bz2: rsyphon.spec
	rm -fr $(TOPDIR)/tmp
	if [ -d $(TOPDIR)/.svn ]; then \
		mkdir -p $(TOPDIR)/tmp; \
		svn export . $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source; \
	else \
		make distclean && mkdir -p $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source; \
		(cd $(TOPDIR) && tar --exclude=tmp -cvf - .) | (cd $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source && tar -xvf -); \
	fi
	cd $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source && ./configure
	$(MAKE) -C $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source get_source
	#
	# Make sure we've got all kernel source.  NOTE:  The egrep -v '-' bit is so that we don't include customized kernels (Ie: -ydl).
	$(foreach linux_version, $(shell grep 'LINUX_VERSION =' make.d/kernel.rul | egrep -v '(^#|-)' | sort -u | perl -pi -e 's#.*= ##'), \
		$(GETSOURCE) $(shell dirname $(LINUX_URL))/linux-$(linux_version).tar.bz2 $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source/src;)
	$(MAKE) -C $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source clean
ifeq ($(UNSTABLE), 1)
	if [ -f README.unstable ]; then \
		cd $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source && cp README README.tmp; \
		cd $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source && cp README.unstable README; \
		cd $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source && cat README.tmp >> README; \
		cd $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source && rm README.tmp; \
	fi
endif
	rm -f $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source/README.unstable
	perl -pi -e "s/^%define\s+ver\s+\d+\.\d+\.\d+.*/%define ver $(VERSION)/" \
		$(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source/rsyphon.spec
	find $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source -type f -exec chmod ug+r  {} \;
	find $(TOPDIR)/tmp/rsyphon-$(VERSION)-complete_source -type d -exec chmod ug+rx {} \;
	cd $(TOPDIR)/tmp && tar -ch rsyphon-$(VERSION)-complete_source | bzip2 > rsyphon-$(VERSION)-complete_source.tar.bz2
	@echo
	@echo "complete source tarball has been created in $(TOPDIR)/tmp"
	@echo

.PHONY:	source_tarball
source_tarball:	$(TOPDIR)/tmp/rsyphon-$(VERSION).tar.bz2.sign
$(TOPDIR)/tmp/rsyphon-$(VERSION).tar.bz2.sign:	$(TOPDIR)/tmp/rsyphon-$(VERSION).tar.bz2
	cd $(TOPDIR)/tmp && gpg --detach-sign -a --output rsyphon-$(VERSION).tar.bz2.sign rsyphon-$(VERSION).tar.bz2
	cd $(TOPDIR)/tmp && gpg --verify rsyphon-$(VERSION).tar.bz2.sign 

$(TOPDIR)/tmp/rsyphon-$(VERSION).tar.bz2: $(TOPDIR)/rsyphon.spec
	rm -fr $(TOPDIR)/tmp
	if [ -d $(TOPDIR)/.svn ]; then \
		mkdir -p $(TOPDIR)/tmp; \
		svn export . $(TOPDIR)/tmp/rsyphon-$(VERSION); \
	else \
		make distclean && mkdir -p $(TOPDIR)/tmp/rsyphon-$(VERSION); \
		(cd $(TOPDIR) && tar --exclude=tmp --exclude=.git -cvf - .) | (cd $(TOPDIR)/tmp/rsyphon-$(VERSION) && tar -xvf -); \
	fi
ifeq ($(UNSTABLE), 1)
	if [ -f README.unstable ]; then \
		cd $(TOPDIR)/tmp/rsyphon-$(VERSION) && cp README README.tmp; \
		cd $(TOPDIR)/tmp/rsyphon-$(VERSION) && cp README.unstable README; \
		cd $(TOPDIR)/tmp/rsyphon-$(VERSION) && cat README.tmp >> README; \
		cd $(TOPDIR)/tmp/rsyphon-$(VERSION) && rm README.tmp; \
	fi
endif
	rm -f $(TOPDIR)/tmp/rsyphon-$(VERSION)/README.unstable
	perl -pi -e "s/^%define\s+ver\s+\d+\.\d+\.\d+.*/%define ver $(VERSION)/" \
		$(TOPDIR)/tmp/rsyphon-$(VERSION)/rsyphon.spec
	find $(TOPDIR)/tmp/rsyphon-$(VERSION) -type f -exec chmod ug+r  {} \;
	find $(TOPDIR)/tmp/rsyphon-$(VERSION) -type d -exec chmod ug+rx {} \;
	cd $(TOPDIR)/tmp && tar -ch rsyphon-$(VERSION) | bzip2 > rsyphon-$(VERSION).tar.bz2
	@echo
	@echo "source tarball has been created in $(TOPDIR)/tmp"
	@echo

# make the srpms for rsyphon
.PHONY:	srpm
srpm: $(TOPDIR)/tmp/rsyphon-$(VERSION).tar.bz2 $(TOPDIR)/rsyphon.spec
	rpmbuild --define '%dist %{nil}' -ts $(TOPDIR)/tmp/rsyphon-$(VERSION).tar.bz2

# make the rpms for rsyphon
.PHONY:	rpm rpms
rpms: rpm
rpm: $(TOPDIR)/tmp/rsyphon-$(VERSION).tar.bz2 $(TOPDIR)/rsyphon.spec
	rpmbuild -tb $(TOPDIR)/tmp/rsyphon-$(VERSION).tar.bz2

# make the debs for rsyphon
#
# I wonder if installing libpam-dev would eliminate the need for
# "--disable-login --disable-su" in  initrd_source/make.d/util-linux.rul
# ?? -BEF-  If so, we should add libpam-dev to UBUNTU_PRECISE_BUILD_DEPS
# in initrd_source/make.d/util-linux.rul.
#
UBUNTU_PRECISE_BUILD_DEPS += dos2unix docbook-utils libncurses-dev
.PHONY: deb debs
debs: deb
deb: $(TOPDIR)/tmp/rsyphon-$(VERSION).tar.bz2
	# Check package version.
	@(if [ ! "`dpkg-parsechangelog | grep ^Version: | cut -d ' ' -f 2`" = $(VERSION) ]; then \
		echo "ERROR: versions in debian/changelog doesn't match with version specified into the file VERSION"; \
		echo "Please fix it."; \
		exit 1; \
	else \
		exit 0; \
	fi)
	@cd $(TOPDIR)/tmp && tar xvjf rsyphon-$(VERSION).tar.bz2
	@cd $(TOPDIR)/tmp/rsyphon-$(VERSION) && make -f debian/rules debian/control
	@cd $(TOPDIR)/tmp/rsyphon-$(VERSION) && dpkg-buildpackage -rfakeroot -uc -us
	@echo "=== deb packages for rsyphon ==="
	@ls -l $(TOPDIR)/tmp/*.deb
	@echo "====================================="

# removes object files, docs, editor backup files, etc.
.PHONY:	clean
clean:	$(subst .rul,_clean,$(shell cd $(TOPDIR)/make.d && ls *.rul)) initrd_clean
	-$(MAKE) -C $(MANPAGE_DIR) clean
	-$(MAKE) -C $(MANUAL_DIR) clean

	## where the tarballs are built
	-rm -rf tmp

	## editor backups
	-find . -name "*~" -exec rm -f {} \;
	-find . -name "#*#" -exec rm -f {} \;
	-find . -name ".#*" -exec rm -f {} \;

	rm -f config.inc config.log config.status

# same as clean, but also removes downloaded source, stamp files, etc.
.PHONY:	distclean
distclean:	clean initrd_distclean
	-rm -rf $(SRC_DIR) $(INITRD_SRC_DIR)

.PHONY:	help
help:  show_build_deps

#
#
# Show me a list of all targets in this entire build heirarchy
.PHONY:	show_targets
show_targets:
	@echo
	@echo Makefile targets you are probably most interested in:
	@echo ---------------------------------------------------------------------
	@echo "all"
	@echo "    Build everything you need for your machine's architecture."
	@echo "	"
	@echo "install_client_all"
	@echo "    Install all files needed by a client."
	@echo "	"
	@echo "install_server_all"
	@echo "    Install all files needed by a server."
	@echo "	"
	@echo "install_initrd"
	@echo ""
	@echo "pre_download_source"
	@echo "    Download source tarballs, but don't build anything."
	@echo "    Useful to prep for offline builds."
	@echo ""
	@echo "source_tarball"
	@echo "    Make a source tarball for distribution."
	@echo "	"
	@echo "    Includes Rsyphon source only.  Source for all"
	@echo "    the tools Rsyphon depends on will be found in /usr/src "
	@echo "    or will be automatically downloaded at build time."
	@echo "	"
	@echo "complete_source_tarball"
	@echo "    Make a source tarball for distribution."
	@echo "    "
	@echo "    Includes all necessary source for building Rsyphon and"
	@echo "    all of it's supporting tools."
	@echo "	"
	@echo "rpm"
	@echo "    Build all of the RPMs that can be build on your platform."
	@echo ""
	@echo "srpm"
	@echo "    Build yourself a source RPM."
	@echo ""
	@echo "deb"
	@echo "    Build all of the debs that can be build on your platform."
	@echo ""
	@echo "show_build_deps"
	@echo "    Shows the list of packages necessary for building on"
	@echo "    various distributions and releases."
	@echo
	@echo "show_all_targets"
	@echo "    Show all available targets."
	@echo


.PHONY: show_build_deps
show_build_deps:
	@echo "Before you can build Rsyphon, you'll need to do the following:"
	@echo
	@echo "1) Install the appropriate build dependencies for your distribution."
	@echo "   The easiest path is to cut and paste the command below that is"
	@echo "   appropriate for your distribution."
	@echo
	@echo "   Ubuntu 12.04 and newer:"
	@echo "     apt-get install build-essential rpm flex $(UBUNTU_PRECISE_BUILD_DEPS)"
	@echo
	@echo
	@echo "   RHEL, CentOS, and friends:"
	@echo "     yum install rpm-build patch wget flex bc docbook-utils dos2unix device-mapper-devel gperf pam-devel quilt lzop glib2-devel PyXML glibc-static $(RHEL6_BUILD_DEPS)"
	@echo
	@echo "   Debian Stable:"
	@echo "     apt-get install build-essential flex $(DEBIAN_STABLE_BUILD_DEPS)"
	@echo     
	@echo "   NOTE: Other distro versions may build fine, and are simply untested by"
	@echo "         the dev team."
	@echo
	@echo "2) Run './configure'"
	@echo
	@echo "3) Run 'make show_targets' to see a list of make targets from which you can"
	@echo "   choose."
	@echo

.PHONY:	show_all_targets
SHOW_TARGETS_ALL_MAKEFILES = $(shell find . make.d/ initrd_source/ initrd_source/make.d/  -maxdepth 1 -name 'Makefile' -or -name '*.rul' )
show_all_targets:
	@echo All Available Targets Include:
	@echo ---------------------------------------------------------------------
	@cat $(SHOW_TARGETS_ALL_MAKEFILES) | egrep '^[a-zA-Z0-9_]+:' | sed 's/:.*//' | sort -u
	@echo
