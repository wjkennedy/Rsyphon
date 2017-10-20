# Rsyphon
**Born from SystemImager**




### Quick Start
- Do a `make get_source`.
- Modify the source code as desired.
- Modify the init script as desired:
    vi skel/etc/init.d/rcS
- Modify any other configuration files as desired.  Most of these are in the "skel" directory. (skel is short for skeleton files)
- Run "make install"

For more detailed information, please read the rsyphon manual, which
is available in the rsyphon-doc package and in this wiki. 

Get some machines together.  You will need one machine to act as your image server, one machine to act as your golden client, and one machine to act as an autoinstall client.  The image server needs to have enough disk space to hold the entire contents of the golden client's filesystems, and the golden client and autoinstall client should be as identical as possible.

On your golden client, apt-get install rsyphon-client.

On your image server, apt-get install rsyphon-server

On your golden client, run the command "rsprepareclient". rsprepareclient will ask you some questions, then leave your golden client ready to have it's image pulled.

On the image server, run the command:

    rsgetimage -golden-client <golden_client> -image <image_name>

 where <golden_client> is the ip or hostname of your golden client, and <image_name> is the name you would like to use to refer to this image, e.g. web_server, woody_2001_10_05, debian2.2r4_lp1000r, etc.  You should see filenames fly by on the screen as getimage rsyncs over the contents of your golden client.

### Assign clients to an image 
On the image server, run the 'rsaddclients' command to assign clients to your image.

### Create autoinstall media

Configure your dhcp server using the 'rs_mkdhcpserver' command.

You can also create autoinstall media for booting your autoinstall client(s).  There are currently 4 supported types of media (cd, pxe, usb drive & hard drive/usb key).

### Autoinstall

Boot your autoinstall client from the autoinstall media - your client should begin to autoinstall itself.


### Notes on customizing and building your initrd.gz
- Files in the ./skel/ directory are copied directly to the ramdisk
  you can edit the files there, or drop in your own.
- Source tarballs for a few binaries are needed during the build.  An attempt
  is made to download them w/ wget, but you can download them separately and
  drop them into the tree by hand.  See the Makefile for locations.  If the
  download attempt fails because these files no longer exist, please report
  this as a bug.  wget will pay attention to your http_proxy and ftp_proxy
  environmental variables.
- Development is done on Debian systems, therefore this is the suggested 
  platform for building.
- Dynamic libraries can hog up a lot of the space in your ramdisk.  The
  "mklibs.sh" script from Debian's boot-floppies package is used to reduce the
  overall size, but it is dependent on the existence of the associated
  pic archives.  On Debian systems, you can 'apt-get install libc6-pic' to 
  insure that these libraries are on your system.  If you ran 
  'apt-get boot-floppies' to install that package, then the pic libraries
  should have been installed along side the boot floppies package.  In the 
  case of libc6, newer versions usually mean larger libraries.  We 
  currently use libc6-2.1.3.  As a comparison:

	Debian Version   libc6 version   resultant initrd.gz size
	--------------------------------------------------------------
	2.2 (potato)     2.1.3           610761 bytes
	unstable (sid)   2.2.3           682281 bytes

- The kernel on your development machine must support loopback devices.
- /dev entries are created from the contents of the dev_ls-lR file.
  To customize, either edit this file, or:
  1) Modify the entries in /dev of an existing ramdisk to suit your needs
  2) Create a new dev_ls-lR file by cd'ing to the customized /dev directory
     and capturing the output of 'ls -lR'
- You may also need to customize the size of your ramdisk, and the number
  of inodes available on your ramdisk.  These are options in the Makefile.
- Be sure that the binaries that will be installed from your local system
  are actually *on* your local system.  Make sure you have all of the 
  "Build-Depends" packages from the ./debian/control file installed.  You 
  should also have all of the Debian build-essential packages installed 
  (stuff like make and gcc).

### Interesting Make Targets

install:    installs a compressed ramdisk to your local system

initrd.gz:  builds a compressed ramdisk

get_source: the build system checks in multiple locations for external source
            these locations are, in order of preference:
              - upstream tarballs in /usr/src/
              - upstream uncompressed source in the top level (this is 
                primarily here for the debian packaging).
              - a well-known url on the net
            the get_source target will cause all of the required third party
            source to be downloaded.  once you have downloaded this source
            once, please copy it to one of the other locations to reduce
            unnecessary load on the respective servers, and speed up your build
            process.

clean:      cleans the source tree, but leave around downloaded third party
            source

distclean:  cleans the source tree, including removal of downloaded third party
            source

## Upgrading

When upgrading, please follow the directions in the "Upgrading" chapter
of the manual.  The manual is available in the rsyphon-doc package.
Not following these instructions will usually result in failed installations.

Makefile targets you are probably most interested in:
---------------------------------------------------------------------
all
    Build everything you need for your machine's architecture.
	
install_client_all
    Install all files needed by a client.
	
install_server_all
    Install all files needed by a server.
	
install_initrd

pre_download_source
    Download source tarballs, but don't build anything.
    Useful to prep for offline builds.

source_tarball
    Make a source tarball for distribution.
	
    Includes Rsyphon source only.  Source for all
    the tools Rsyphon depends on will be found in /usr/src 
    or will be automatically downloaded at build time.
	
complete_source_tarball
    Make a source tarball for distribution.
    
    Includes all necessary source for building Rsyphon and
    all of it's supporting tools.
	
rpm
    Build all of the RPMs that can be build on your platform.

srpm
    Build yourself a source RPM.

deb
    Build all of the debs that can be build on your platform.

show_build_deps
    Shows the list of packages necessary for building on
    various distributions and releases.

show_all_targets
    Show all available targets.

----

## Diagram

                                   Image Server

+-------------------------------------------------------------------------------+
|                                                                               |
|                                                                               |
|                                                                               |
|                                                                               |
|               rs_cpimage    +-------------------+                             |
|                             |                   |                             |
|                +-------------->    image B      |                             |
|                |            +---^---------------+                             |
|     +----------+----------+     |                 +---------------------+     |
|     |                     |     |                 |                     |     |
|     |       image A       |     |                 |   +   image C       |     |
|     +---------------------+     |                 +---------------------+     |
|                                 |                     |                       |
|                                 |                     |                       |
|                                 |                     |                       |
|                                 |                     |                       |
|                                 |                     |                       |
|                                 |                     |                       |
|                                 |                     |                       |
|                                 |                     |                       |
|                                 |                     |                       |
+----------------------------+--------------------------------------------------+
                             ^    |                     |
                 rs_getimage |    |                     |
                             |    |                     |
                             |    |                     |
                             |    |                     |
                             |    |                     |
                             |    |                     |
                             |    | rs_pushupdate       | rs_pullupdate
                     +-------+----+---------------------------+
                     |                                  |     |
                     |                                  |     |
                     |                                  v     |
                     |                                        |
                     |                                        |
                     +----------------------------------------+

                                    Golden Client

