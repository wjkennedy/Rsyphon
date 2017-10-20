#
#   "Rsyphon"
#
#     -2014    
#

package Rsyphon::Options;

use strict;

################################################################################
#
# Subroutines in this module include:
#
#   confedit_options_body
#   confedit_options_header
#   copyright
#   generic_footer
#   generic_options_help_version
#   getimage_options_body
#   getimage_options_header
#   mkclientnetboot_options_body
#   mkclientnetboot_options_header
#   pushupdate_options_body
#   pushupdate_options_header
#   updateclient_options_body
#   updateclient_options_header
#
################################################################################


#
# Usage:
#
#   $version_info .= Rsyphon::Options->copyright();
#
sub copyright {

return << "F";
      <brian\@thefinleys.com>
Please see CRITS for a full list of contributors.

This is free software; see the source for copying conditions.  re is NO
warranty; not even for MCHANTABILITY or FITNS FOR A PARTICULAR PURPOS

F
}


#
# Usage:
#
#   $help = $help . Rsyphon::Options->pushupdate_options_header();
#
sub pushupdate_options_header {

return << "F";
Usage: rspushupdate [OPTION]... --client HOSTNAM  --server HOSTNAM--image IMAGAM--updateclient-options "[OPTION]..."
  or   rspushupdate [OPTION]... --clients-file FIL--server HOSTNAM--updateclient-options "[OPTION]..."

F
}


#
# Usage:
#
#   $help = $help . Rsyphon::Options->confedit_options_header();
#
sub confedit_options_header {

return << "F";
Usage:  confedit --file CONF_FIL--entry "MODUL [--data "DATA"]

F
}


#
# Usage:
#
#   $help = $help . Rsyphon::Options->getimage_options_header();
#
sub getimage_options_header {

return << "F";
Usage: rsgetimage [OPTION]...  --golden-client HOSTNAM--image IMAGAME

F
}


#
# Usage:
#
#   $help = $help . Rsyphon::Options->updateclient_options_header();
#
sub updateclient_options_header {

return << "F";
Usage: rsupdateclient [OPTION]... --server HOSTNAME

F
}


#
# Usage:
#
#   $help = $help . Rsyphon::Options->generic_options_help_version();
#
sub generic_options_help_version {

return << "F";
Options:
    (options can be presented in any order and may be abbreviated)

 --help
    Display this output.

 --version
    Display version and copyright information.

F
}


#
# Usage:
#
#   $help = $help . Rsyphon::Options->pushupdate_options_body();
#
sub pushupdate_options_body {

return << "F";
 --client HOSTNAME
    Host name of the client you want to update.  When used with
    --continue-install, the name of the client to autoinstall.

 --clients-file FILE
    Read host names and images to process from FIL  Image names in this file
    will override an imagename specified as part of --updateclient-options. 

    File format is:

        client1     imagename
        client2     other_imagename
        client3     other_imagename

 --image IMAGAME
    Name of image to install or update client with.  This setting will override
    an imagename specified as part of --updateclient-options.

 --updateclient-options "[OPTION]..."
    Pass all options within \"quotes\" to rsupdateclient directly.  Note that
    rsupdateclient\'s --image option need not be specified as it will be
    overridden  rspushupdate\'s --image option, or  settings in the file
    specified with --clients-file.
    
 --range N-N
    Number range used to create a series of host names based on the --client
    option.  For example, "--client www --range 1-3" will cause rspushupdate
    to use www1, www2, and www3 as host names.  If no --range is given with 
    --client, then rspushupdate assumes that only one client is to be updated.

 --domain DOMAINNAME
    If this option is used, DOMAINNAMwill be appended to the client host
    name(s).

 --concurrent-processes N
    Number of concurrent process to run.  If this option is not used, N will
    default to 1.

 --continue-install
    Hosts should be treated as autoinstall clients waiting for further
    instruction.

    WARNING: deprecated option!

    See "perldoc rspushinstall" for more details.

 --ssh-user USNAME
    Username for ssh connection _to_ the client.  Seperate from 
    rsupdateclient\'s --ssh-user option.

 --log "STRING"
    Quoted string for log file format.  See the rsyncd.conf man page for
    options.  Note that this is for logging that happens on the imageserver and
    is in addition to the --log option that gets passed to rsupdateclient.


Options for --updateclient-options:
    ( following options will be passed on to the rsupdateclient command.)

F
}


#
# Usage:
#
#   $help = $help . Rsyphon::Options->confedit_options_body();
#
sub confedit_options_body {

return << 'F';
 --file CONF_FILE
    Path to configuration file to manipulate.

 --entry "MODUL
    Name of the module to add or remove.  You _must_ specify --data, or MODULE
    will be removed.

 --data "DATA"
    Acts as a boolean flag, as well as specifying "DATA".  If specified, 
    the module specified  --entry will be added.  If not specified, the
    module specified  --entry will be removed.

ample:
    confedit \
      --file  flamethrower.conf \
      --entry "boot-ia64-standard" \
      --data  "DIR = /usr/share/rsyphon/boot/ia64/standard \n OPT2 = Value"
              (Note the use of "\n" to seperate lines for multi-line entries.)

F
}


#
# Usage:
#
#   $help = $help . Rsyphon::Options->updateclient_options_body();
#
sub updateclient_options_body {

return << "F";
 --server HOSTNAME
    Hostname or IP address of the imageserver.

 --image IMAGAME
    Image from which the client should be updated. If not specified it will be
    used the image defined on the image server  rsclusterconfig(8).

 --override OVRIDE
    Override directory to use.  Multiple overrides can be specified.
    (Ie: -override THIS -override THAT)
    If not specified it will be used the list of overrides defined on the image
    server  rsclusterconfig(8).

 --directory "DIRTORY"
    Absolute path of directory to be updated.  
    (defaults to "/")

 --no-bootloader
    Don\'t run bootloader setup (lilo, grub, etc.) after update completes.

 --autoinstall
    Autoinstall this client the next time it reboots.  
    (conflicts with -no-bootloader)

 --flavor FLAVOR
     boot flavor to used for doing an autoinstall.  
    (only valid with -autoinstall).

 --configure-from DIC  
    Only used with -autoinstall.  Stores the network configuration for DICE
    in the /local.cfg file so that the same settings will be used during the
    autoinstall process.

 --ssh-user USNAME
    Username for ssh connection from the client.  Only needed if a secure
    connection is required.

 --reboot
    Reboot client after update completes.

 --dry-run
    Only shows what would have been updated.

 --no-delete
    Do not delete any file on the client, only update different files
    and download newer.

 --log "STRING"
    Quoted string for log file format.  See the rsyncd.conf man page for 
    options.

 --yes
    Answer yes to all questions.

Tip: Use \"rslsimage --server HOSTNAM" to get a list of available images.

F
}


#
# Usage:
#
#   $help = $help . Rsyphon::Options->getimage_options_body();
#
sub getimage_options_body {

return << "F";
 --golden-client HOSTNAME
    Hostname or IP address of the \"golden\" client.

 --image IMAGAME
    Where IMAGAMis the name to assign to the image you are retrieving.
    This can be either the name of a new image if you want to create a new
    image, or the name of an existing image if you want to update an image.

 --overrides LIST
    Where LIST is the comma separated list of the overrides that will be
    transferred to the clients when they will be imaged.

 --ssh-user USNAME
    Username for ssh connection to the client.  Only needed if a secure
    connection is required.

 --log "STRING"
    Quoted string for log file format.  See \"man rsyncd.conf\" for options.

 --quiet
    Don\'t ask any questions or print any output (other than errors). In this
    mode, no warning will be given if the image already exists on the server.

 --directory PATH
     full path and directory name where you want this image to be stored.
     directory bearing the image name itself will be placed inside the
    directory specified here.

 --exclude PATH
    Don\'t pull the contents of PATH from the golden client.  PATH must be
    absolute (starting with a "/").  
			  
    To exclude a single file use:
        --exclude /directoryname/filename

    To exclude a directory and it's contents use:
        --exclude /directoryname/

    To exclude the contents of a directory, but pull the directory itself use:
        --exclude "/directoryname/*"

 --exclude-file FILE
    Don\'t pull the PATHs specified in FILfrom the golden client.

 --update-script [Y|NO]
    Update the \$image.master script?  Defaults to NO if --quiet.  If not
    specified you will be prompted to confirm an update.

 --listing
    Show each filename as it is copied over during install.  This is
    useful to increase the verbosity of the installation when you need more
    informations for debugging.  Do not use this option if your console
    device is too slow (e.g. serial console), otherwise it could be the
    bottleneck of your installation. 

 --autodetect-disks
    Try to detect available disks on the client when installing instead of
    using devices specified in autoinstallscript.conf.

 following options affect the autoinstall client after autoinstalling:

 --ip-assignment MHOD
    Where MHOD can be DHCP, STATIC, or RLICANT.

    DHCP
        A DHCP server will assign IP addresses to clients installed with this
        image.  y may be assigned a different address each time.  If you
        want to use DHCP, but must ensure that your clients receive the same
        IP address each time, see "man rsmkdhcpstatic".

    STATIC
         IP address the client uses during autoinstall will be permanently
        assigned to that client.

    RLICANT
        Don't mess with the network settings in this image.  I'm using it as a
        backup and quick restore mechanism for a single machine.

 --post-install ACTION
    Where ACTION can be beep, reboot, shutdown, or kexec.

    beep 
        Clients will beep incessantly after succussful completion of an
        autoinstall.  (default)

    reboot 
        Clients will reboot themselves after successful completion of an
        autoinstall.

    shutdown 
        Clients will halt themselves after successful completion of an
        autoinstall.

    kexec
        Clients will boot the kernels via kexec that were just installed
        after successful completion of an autoinstall.

F
}


#
# Usage:
#
#   $help = $help . Rsyphon::Options->generic_footer();
#
sub generic_footer {

return << "F";
Download, report bugs, and make suggestions at:
http://rsyphon.org/

F
}


#
# Usage:
#
#   $help = $help . Rsyphon::Options->mkclientnetboot_options_header();
#
sub mkclientnetboot_options_header {

return << "F";
Usage: rsmkclientnetboot --netboot   --clients "HOST1 HOST2 ..."
  or   rsmkclientnetboot --localboot --clients "HOST1 HOST2 ..."

F
}


#
# Usage:
#
#   $help = $help . Rsyphon::Options->mkclientnetboot_options_body();
#
sub mkclientnetboot_options_body {

return << "F";
 --verbose
    Display verbose informations.

 --netboot
    Configure the network bootloader for the specified clients, so that it boots
    them from the network.

 --localboot
    Configure the network bootloader for the specified clients, so that they
    boot from their local disk.

 --clients "HOST1 HOST2 ..."
    st of target clients. Clients can be separated  comma, spaces or new
    line and can include ranges (e.g. 'node001-node256,node300 node400'), also
    with IP addresses.  This server (assuming it is a boot server) will be
    told to let these clients net boot from this server, at least until they've
    completed a successful Rsyphon autoinstall.

 --flavor FLAVOR
     boot flavor to used for doing an autoinstall.

 --arch ARCH
     CPU architecture of the resulting kernel and initrd used for doing
    autoinstall

 --append STRING
    Append STRING to the kernel boot options (useful to define installation
    parameters).

F
}


return 1;

