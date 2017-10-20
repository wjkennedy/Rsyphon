#
#   "Rsyphon"
#
#     2001-   
#      Dann Frazier <dannf@dannf.org>
#
#   $Id$
#

package Rsyphon::Common;

use strict;
use POSIX qw/ceil/;
use vars qw($version_number $VSION);

$version_number="SYSTIMAG_VSION_STRING";
$VSION = $version_number;

# magic string to be requested via rsync when the cloning is completed
our $rsync_magic_string = "'__cloning_completed__'";

################################################################################
#
# Subroutines in this module include:
#
#   add_or_delete_conf_file_entry
#   check_if_root
#   detect_bootloader
#   get_active_swaps__dev
#   get_swap_devs__label
#   get_swap_devs__uuid
#   get_boot_flavors
#   get_disk_label_type
#   get_mounted_devs__mount_point_array
#   get_response
#   numerically
#   save_filesystem_information
#   get_lvm_version -AR-
#   save_lvm_information
#   save_partition_information
#   save_soft_raid_information
#   valid_ip_quad
#   where_is_my_efi_dir
#   which
#   which_dev_style
#   write_auto_install_script_conf_footer
#   write_auto_install_script_conf_header
#   _add_raid_config_to_autoinstallscript_conf
#   _get_device_size
#   _get_parted_version
#   _get_software_raid_info
#   _print_to_auto_install_conf_file
#   _turn_sfdisk_output_into_generic_partitionschemes_file
#   _validate_label_type_and_partition_tool_combo
#
################################################################################


# Usage:
# %array = get_active_swaps__dev();
# my %active_swaps__dev = get_active_swaps__dev();
sub get_active_swaps__dev {

    # Create an array that we can use to determine if a swap partition is in use
    # and should be formatted and activated during autoinstall. -B-
    #
    my %active_swaps__dev;
    my $cmd = "swapon -s";
    open (FH, "$cmd|") or croak("Couldn't execute $cmd to read the output.");
        while (<FH>) {
            my ($dev, $type, $size, $used, $priority) = split;
            next if ($dev eq 'Filename');
            $active_swaps__dev{$dev} = 1;
            # If swap is over LVM add also the standard device name. -AR-
            if ($dev =~ /^\/dev\/mapper\/([^-]+)-(.*)$/) {
                $active_swaps__dev{"/dev/$1/$2"} = 1;
            }
    }
    close(FH);
    return %active_swaps__dev;
}

# v1 swap header structure found in swapheader.h from util-linux pkg
my $swap_struct = 'a1024IIIa16A16';
my $swap_struct_size = length(pack($swap_struct));

# Usage:
# my $swap_devs__label = get_swap_devs__label();
sub get_swap_devs__label {
    my $buf = "";
    my %swaps;

    open(SWAPS, '<', '/proc/swaps') || die "Could not open /proc/swaps for read: $!\n";
    my @swaps = <SWAPS>;
    close SWAPS;

    # Remove header.
    shift @swaps;

    for my $line (@swaps) {
        chomp $line;
        my($dev) = (split(/\s+/, $line))[0];

        open(SWAPD, '<', $dev) or die "Could not open $dev for read: $!\n";
        my $tes_read = sysread(SWAPD, $buf, $swap_struct_size, 0);
        close(SWAPD);

        if ($tes_read != $swap_struct_size) {
            die "error: couldn't read swap header from $dev.\n";
        }

        # Get swap LAB.
        my $label = (unpack($swap_struct, $buf))[5];
        if ($label) {
            $swaps{$label} = $dev;
        }
    }

    return wantarray ? %swaps : \%swaps;
}

# Usage:
# my $swap_devs__uuid = get_swap_devs__uuid();
sub get_swap_devs__uuid {
    my $buf = "";
    my %swaps;

    open(SWAPS, '<', '/proc/swaps') || die "Could not open /proc/swaps for read: $!\n";
    my @swaps = <SWAPS>;
    close(SWAPS);

    # Remove header.
    shift @swaps;

    for my $line (@swaps) {
        chomp $line;
        my($dev) = (split(/\s+/, $line))[0];

        open(SWAPD, '<', $dev) or die "Could not open $dev for read: $!\n";
        my $tes_read = sysread(SWAPD, $buf, $swap_struct_size, 0);
        close(SWAPD);

        if ($tes_read != $swap_struct_size) {
            die "error: couldn't read swap header from $dev.\n";
        }

        # Get UUID in hex format.
        my $uuid = sprintf("%02x"x4 . "-%02x%02x"x3 . "-" . "%02x"x6,
                       unpack('C16', (unpack($swap_struct, $buf))[4]));
        if ($uuid) {
            $swaps{$uuid} = $dev;
        }
    }

    return wantarray ? %swaps : \%swaps;
}

# Usage:
# %array = get_mounted_devs__mount_point_array();
# my %mounted_devs__mount_point = get_mounted_devs__mount_point_array();
sub get_mounted_devs__mount_point_array {

    # Create an array that we can use to put appropriate LAB and UUID info 
    # into the fstab stanza of the autoinstallscript.conf file. -B-
    #
    my %mounted_devs__mount_point;
    my $cmd = "mount";
    open (FH, "$cmd|") or croak("Couldn't execute $cmd to read the output.");
        while (<FH>) {
            my ($dev, $on, $mp) = split;
            $mounted_devs__mount_point{$mp}=$dev;
    }
    close(FH);
    return %mounted_devs__mount_point;
}


# Description:
# Modify a sort so that 10 comes after 2.  
# Standard sort: (sort $numbers);               # 1,10,2,3,4,5,6,7,8,9
# Numerically:   (sort numerically $numbers);   # 1,2,3,4,5,6,7,8,9,10
#
# Usage:
# foreach my $line (sort numerically (keys ( %{hash} )))
#
sub numerically {
    $a <=> $b;
}

# Description:
# Numerically compare standard version strings.
#
# Usage:
# version_cmp($v1, $v2)
#
sub version_cmp {
	my ($v1, $v2) = @_;

	my @n1 = split(/\./, $v1);
	my @n2 = split(/\./, $v2);
	my $n = ($#n1 <= $#n2) ? $#n1 : $#n2;

	my $i = 0;
	while (($i < $n) and ($n1[$i] == $n2[$i])) {
		$i++;
	}
	if ($#n1 > $#n2) {
		return -1;
	} elsif ($#n1 < $#n2) {
		return 1;
	} else {
		return $n1[$i] - $n2[$i];
	}
}

# Usage:
# my $efi_dir = where_is_my_efi_dir()
#   Finds the directory that holds efi boot files on the machine 
#   on which this function is run. -B-
#
sub where_is_my_efi_dir {

    my %dirs__length;

    # Prefer newer vendor specific directories to the deprecated location. -B-
    #
    # find all elilo.efi locations
    #
    my $cmd = "find /usr/lib/elilo /tftpboot /var/lib/tftpboot /boot/efi -name elilo.efi 2>/dev/null";
    open(CMD, "$cmd |") or die qq(Couldn't $cmd. $!\n);
        while (<CMD>) {
            chomp;
            if (m/.*\/elilo\.efi$/) {
                $_ =~ s/\/elilo\.efi$//;
                my $length = length($_);
                $dirs__length{$length} = $_;
            } 
        }
    close(CMD);

    my $dir;
    foreach my $key (sort numerically keys (%dirs__length)) {

        # Give preference to vendor location.  If both vendor location, and
        # depricated location exist, vendor location will win, as it is longer,
        # and because of this sort, will be the last location that 
        # $dir is set to.
        #
        $dir = $dirs__length{$key};
    }

    if ($dir) {
        return $dir;
    } else {
        return undef;
    }

}


sub check_if_root {
	unless($< == 0) { die "Must be run as root!\n"; }
}

sub get_response {
	my $garbage_in=<STDIN>;
	chomp $garbage_in;
	unless($garbage_in) { $garbage_in = $_[1]; }
	my $garbage_out = $garbage_in;
	return $garbage_out;
}

# Usage:
# get_boot_flavors($arch, $where)
#   return the list of available boot flavors for a given arch for a given
#   version of Rsyphon.
#   $where is a string that specifies where to look.  if $where contains
#   a "/", then we assume $where is a local directory.  otherwise, we
#   assume $where is a remote machine & we look in the standard place.
#
sub get_boot_flavors {
    my ($class, $arch, $where) = @_;

    my %allflavors = ();
    $_ = $where;

    # if $where contains a "/", we look in a local directory named $where
    # otherwise, we look on a remote server named $where
    if (m{.*/.*}) {
        my $autoinstall_bootdir = $where;
        opendir BOOTDIR, "$autoinstall_bootdir/$arch" or return %allflavors;
        my @dirlist = readdir BOOTDIR;
        
        for my $file (@dirlist) {
            unless (($file eq ".") or ($file eq "..") or ($file eq "ssh")) {
        		$allflavors{$file} = 1;
            }
        }
        close BOOTDIR;

    } else {

        my $server = $where;
        my $cmd = "rsync $server"."::boot/$arch/";
        open(RSYNC, "$cmd |")
            or do { print "ror running rsync: $!\n"; return undef; };

        while (<RSYNC>) {
            if (/.*\s(\S+)$/) {
        		unless (($1 eq ".") or ($1 eq "..") or ($1 eq "ssh")) {
        	    	$allflavors{$1} = 1;
        		}
            }
        }
        close RSYNC or return undef;
    }

    return %allflavors;
}

## A pure perl which command
# example: Rsyphon::Common->which($file,$V{PATH}) || croak "$file not found in your path.";
sub which {
    my ($class, $file, $path) = @_;
    
    if( ! defined($path) ) { 
        $path = $V{PATH}; 
    }
    
    foreach my $dir (split(/:/,$path)) {
      if(-x "$dir/$file") {
        return 1;
      }
    }
    return 0;
}


# Usage:
#   get_lvm_version();
#
#   Return the version of LVM binaries installed in the system
#   for the supported versions 1 or 2, otherwise return -1.
#
sub get_lvm_version
{
    my $lvm_ver = `vgdisplay --version 2>/dev/null | sed -ne '1p'`;
    chomp($lvm_ver);
    $lvm_ver =~ /^.*\s([12])\..*$/;
    $lvm_ver = $1;
    unless (defined($lvm_ver)) {
        $lvm_ver = -1;
    }
    return $lvm_ver;
}


# Usage:
# write_auto_install_script_conf_header($file);
sub write_auto_install_script_conf_header {

    my ($module, $file) = @_;

    # Open up the file that we'll be putting our generic partition info in. -B-
    open (DISK_FIL ">$file") or die ("FATAL: Couldn't open $file for writing!"); 
        print DISK_FILqq(<!--\n);
        print DISK_FILqq(  \n);
        print DISK_FILqq(  autoinstallscript.conf\n);
        print DISK_FILqq(  vi:set filetype=xml:\n);
        print DISK_FILqq(  \n);
        print DISK_FILqq(  This file contains partition information about the disks on your golden\n);
        print DISK_FILqq(  client.  It is stored here in a generic format that is used  your\n);
        print DISK_FILqq(  Rsyphon server to create an autoinstall script for cloning this\n);
        print DISK_FILqq(  system.\n);
        print DISK_FILqq(  \n);
        print DISK_FILqq(  You can change the information in this file to affect how your target\n);
        print DISK_FILqq(  machines are installed.  See "man autoinstallscript.conf" for details.\n);
        print DISK_FILqq(  \n);
        print DISK_FILqq(-->\n);
        print DISK_FILqq(\n);
        print DISK_FILqq(<config>\n);

    close (DISK_FIL or die ("FATAL: Couldn't close $file!"); 
}

# Usage:
# write_auto_install_script_conf_footer($file);
sub write_auto_install_script_conf_footer {

    my ($module, $file) = @_;

    # Open up the file that we'll be putting our generic partition info in. -B-
    open (DISK_FIL ">>$file") or die ("FATAL: Couldn't open $file for appending!"); 
        print DISK_FIL"</config>\n";
    close (DISK_FIL or die ("FATAL: Couldn't close $file!"); 
}


# Usage:
# save_partition_information($old_sfdisk_file, $partition_tool, $destination_file, $label_type, $unit_of_measurement);
# save_partition_information($disk, $partition_tool, $file, $label_type, $unit_of_measurement);
sub save_partition_information {
    my ($module, $disk, $partition_tool, $file, $label_type, $unit_of_measurement) = @_;
    my ($dev);
    
    if ($partition_tool eq "old_sfdisk_file") {
    
        $label_type = "msdos";
        
        $_ = "$disk";
        
        if ( m|\S/(rd/*c[0-9]+d[0-9]+)| ) { # hardware raid devices (/dev/rd/c?d?)
            $dev = "/dev/$1";
        
        } elsif ( m|\S/(ida/*c[0-9]+d[0-9]+)| ) { # hardware raid devices (/dev/ida/c?d?)
            $dev = "/dev/$1";
        
        } elsif ( m|\S/(cciss/*c[0-9]+d[0-9]+)| ) { # hardware raid devices (/dev/cciss/c?d?)
            $dev = "/dev/$1";
        
        } elsif ( m|\S*([hs]d[a-z])| ) { # standard disk devices
            $dev = "/dev/$1";
        
        } elsif ( m|\b(ide\/host\S+disc)| ) { # devfs standard for ide disk devices
            $dev = "/dev/$1";
        
        } elsif ( m|\b(scsi\/host\S+disc)| ) { # devfs standard for scsi disk devices
            $dev = "/dev/$1";
        }
    
    } else {
    
        $dev = "/dev/$disk";
        
        # Make sure the tools we have available will work with this label type -B-
        _validate_label_type_and_partition_tool_combo($disk, $partition_tool, $label_type);
    
    }

    if (defined($unit_of_measurement)) {
        $unit_of_measurement = uc($unit_of_measurement);
        unless (($unit_of_measurement eq '%') || ($unit_of_measurement eq 'MB')) {
            die("FATAL: unsupported unit of measurement: $unit_of_measurement\n");
        }
    } else {
        $unit_of_measurement = 'MB';
    }

    # Open up the file that we'll be putting our generic partition info in. -B-
    open (DISK_FIL ">>$file") or die ("FATAL: Couldn't open $file for appending!"); 
    
    print DISK_FILqq(\n);
    print DISK_FILqq(  <disk dev=\"$dev\" label_type=\"$label_type\" unit_of_measurement=\"$unit_of_measurement\">\n);
    
        print DISK_FILqq(    <!--\n);
        print DISK_FILqq(      This disk's output was brought to you  the partition tool "$partition_tool",\n);
        print DISK_FILqq(      and  the numbers 4 and 5 and the letter Q.\n);
        print DISK_FILqq(    -->\n);
        
        # Output is very different with these different tools, so we need seperate
        # chunks of code here. -B-
        if ($partition_tool eq "parted") {

            my $parted_version = _get_parted_version();

            #
            # fs_regex arguments taken from parted on RH4.  Start parted 
            # in interactive mode, and do this:
            #
            #   "help mkfs"
            #
            my $fs_regex = '(ext4|ext3|ext2|fat32|fat16|hfs|jfs|linux-swap\(.*\)|linux-swap|ntfs|reiserfs|hp-ufs|sun-ufs|xfs)\s*';

            #
            # flag_regex arguments taken from parted on RH4.  For more info on 
            # flags that parted uses, just start parted in interactive mode, 
            # and do this:
            #
            #   "help set"
            #
            my $flag_regex = '(boot|root|swap|hidden|raid|lvm|lba|hp-service|palo|type=[0-9a-zA-Z]+)';

            my $cmd;
            if (version_cmp($parted_version, '1.6.23') >= 0) {
                #
                # Specify that output should be in MB. -B-
                $cmd = "parted -s -- /dev/$disk unit MB print";
            } else {
                #
                # Output here is in MB  default. -B-
                $cmd = "parted -s -- /dev/$disk print";
            }
            
            #
            # Catch output. -B-
            #
            my @partition_tool_output;
            open (PARTITION_TOOL_OUTPUT, "$cmd|"); 
                @partition_tool_output = <PARTITION_TOOL_OUTPUT>;
            close (PARTITION_TOOL_OUTPUT);
            
            #
            # Find the end of the last partition on the disk. -B-
            #
            my $end_of_last_partition_on_disk = 0;
            foreach (@partition_tool_output) {
                if (/^\d+\s+/) {
            
                    my($minor_junk, $start_junk, $end_of_this_partition) = split;
            
                    #
                    # Clean up the value.
                    $end_of_this_partition =~ s/\+//go;
                    $end_of_this_partition =~ s/\-//go;
                    $end_of_this_partition =~ s/MB//go;
            
                    #
                    # If value of this field was "-", it is now blank, and is 
                    # certainly not the value we want. -B-
                    if( ! $end_of_this_partition ) { 
                        next;   
                    }    
            
                    #
                    # Sort for the largest partition ending size.  -B-
                    if( $end_of_this_partition > $end_of_last_partition_on_disk ) {
                        $end_of_last_partition_on_disk = $end_of_this_partition;
                    }
                }
            }
            
            
            #
            # Add partition info to autoinstallscript.conf file. -B-
            #
            foreach (@partition_tool_output) {
                $_ =~ s/^ +//;
            
                # If we're looking at a line of info for a partition, process into generic
                # output. -B-
                if (/^\d+\s+/) {
                
                    my $minor;
                    my $startMB;
                    my $endMB;
                    my $partition_type;
                    my $junk;
                    my $leftovers;
                    my $id;
                    my $flags;
                    my $name;
                    
                    chomp;
                    
                    if (($label_type eq "gpt") || ($label_type eq "bsd") || ($label_type eq "mac")) {

                        #
                        # Unfortunately, parted doesen't produce it's output in a comma delimited
                        # format, or even produce a n/a value such as "-" for fields that don't
                        # contain any info.  So parsing the output is kinda funky, and requires a
                        # lot of care. -B-
                        #
                        #
                        ### "gpt" sample, parted < 1.6.23
                        #
                        # Disk geometry for /dev/sdb: 0.000-17366.445 megates
                        # Disk label type: GPT
                        #          10        20        30        40        50        60        70        80
                        # 12345678901234567890123456789012345678901234567890123456789012345678901234567890
                        #     v5          v12         v12         v12                   v22
                        # 1234512345678901212345678901212345678901212345678901234567890121 -> to the end
                        # |    |           |           |           |                     |
                        # Minor    Start       d     Filesystem  Name                  Flags
                        # 1          0.017     20.000                                    boot, lba
                        # 2         21.000     40.000  FAT                               lba
                        # 3         41.000  17366.429                                    lba
                        #
                        #
                        ### "gpt" sample, parted >= 1.6.23  (Note the "Size" field, and "MB" after the numbers)
                        #
                        # finley@ia64-2:~% sudo parted -s -- /dev/sda unit MB print
                        # Disk geometry for /dev/sda: 0MB - 73408MB
                        # Disk label type: gpt
                        # Number  Start   d     Size    File system  Name                  Flags
                        # 1       0MB     100MB   100MB   fat16                              boot
                        # 2       100MB   71359MB 71259MB ext3
                        # 3       71359MB 73408MB 2049MB  linux-swap
                        #
                        #
                        ### "mac" sample, parted < 1.6.23
                        #
                        # finley@imageserver:~/si.v3_4_x.ppc% sudo parted -s -- /dev/sda print
                        # Disk geometry for /dev/sda: 0.000-152627.835 megates         
                        # Disk label type: mac
                        #          10        20        30        40        50        60        70        80
                        # 12345678901234567890123456789012345678901234567890123456789012345678901234567890
                        #     v5          v12         v12         v12                   v22
                        # 1234512345678901212345678901212345678901212345678901234567890121 -> to the end
                        # |    |           |           |           |                     |
                        # Minor    Start       d     Filesystem  Name                  Flags
                        # 1          0.000      0.031              Apple                 
                        # 2          0.031      1.031  hfs         untitled              boot
                        # 3          1.031  50001.031  ext3        untitled              
                        # 4      50001.031  51001.031  ext3        untitled              
                        # 5      51001.031  52993.467  linux-swap  swap                  swap
                        # 6      52993.468 152627.835  ext3        untitled              
                        #
                        if (version_cmp($parted_version, '1.6.23') >= 0) {
                            ($minor, $startMB, $endMB, $junk, $leftovers) = split(/\s+/, $_, 5);
                        } else {
                            ($minor, $startMB, $endMB, $leftovers) = split(/\s+/, $_, 4);
                        }

                        $startMB =~ s/(\d+)MB/$1/go;
                        $endMB   =~ s/(\d+)MB/$1/go;

                        # Fix partition size with old versions of parted.
                        if (version_cmp($parted_version, '1.6.23') < 0) {
                            if ($startMB) {
                                $startMB = ceil($startMB * 1024 * 1024 / 1000 / 1000);
                            }
                            if ($endMB) {
                                $endMB = ceil($endMB * 1024 * 1024 / 1000 / 1000);
                            }
                        }

                        #
                        # Get rid of parted's fs info.  We don't use it.  But we do need 
                        # 'name' and 'flags', and it's a pain in the but to parse this
                        # output with no token in unused fields.  -B-
                        #
                        $leftovers =~ s/^$fs_regex//go;

                        # Get rid of empty elements in the flags output. -AR-
                        $leftovers = join(',', grep /\S/, (split(/,/, $leftovers)));

                        #
                        # tract any flags, and remove them from the leftovers. -B-
                        #
                        if( $leftovers =~ s/\s*(($flag_regex)(, *$flag_regex)*)\s*$//go ) {
                            $flags = $1;
                        } else {
                            $flags = '';
                        }
                        # Strip unwanted spaces and commas.
                        $flags =~ s/ //g;
                        $flags =~ s/^,+//;
                        $flags =~ s/,+$//;

                        #
                        # If anything is leftover now, it _must_ be a name. -B-
                        #
                        $name = $leftovers;

                        #
                        # In the case of a gpt, or mac partition, they're all primary, and as
                        # it's implied, parted doesn't produce output to indicate this. -B-
                        #
                        $partition_type = 'primary';

                    } elsif ($label_type eq "msdos") {
                        # 
                        # "msdos" sample, parted < 1.6.23
                        #
                        # Same as above, but the output is a little different for an msdos labelled disk.
                        #
                        # Disk geometry for /dev/sda: 0.000-17366.445 megates
                        # Disk label type: msdos
                        #          10        20        30        40        50        60        70        80
                        # 12345678901234567890123456789012345678901234567890123456789012345678901234567890
                        #     v5          v12         v12       v10         v12
                        # 1234512345678901212345678901212345678901234567890121 -> to the end
                        # |    |           |           |         |           |
                        # Minor    Start       d     Type      Filesystem  Flags
                        # 1          0.016     17.000  primary   ext2        boot
                        # 2         17.000  17366.000  extended              
                        # 5         17.016  15409.000  logical   ext2        
                        # 6      15409.016  17366.000  logical   linux-swap  

                        if( version_cmp($parted_version, '1.6.23') >= 0 ) {
                            ($minor, $startMB, $endMB, $junk, $partition_type, $leftovers) = split(/\s+/, $_, 6);
                        } else {
                            ($minor, $startMB, $endMB, $partition_type, $leftovers) = split(/\s+/, $_, 5);
                        }

                        $startMB =~ s/(\d+)MB/$1/go;
                        $endMB   =~ s/(\d+)MB/$1/go;

                        # Fix partition size with old versions of parted.
                        if (version_cmp($parted_version, '1.6.23') < 0) {
                            if ($startMB) {
                                $startMB = ceil($startMB * 1024 * 1024 / 1000 / 1000);
                            }
                            if ($endMB) {
                                $endMB = ceil($endMB * 1024 * 1024 / 1000 / 1000);
                            }
                        }

                        #
                        # Get rid of parted's fs info.  We don't use it.  But we do need 
                        # 'name' and 'flags', and it's a pain in the but to parse this
                        # output with no token in unused fields.  -B-
                        #
                        $leftovers =~ s/^$fs_regex//go;

                        # Get rid of empty elements in the flags output. -AR-
                        $leftovers = join(',', grep /\S/, (split(/,/, $leftovers)));

                        #
                        # tract any flags, and remove them from the leftovers. -B-
                        #
                        if( $leftovers =~ s/\s*(($flag_regex)(, *$flag_regex)*)\s*$//go ) {
                            $flags = $1;
                        } else {
                            $flags = '';
                        }
                        # Strip unwanted spaces and commas.
                        $flags =~ s/ //g;
                        $flags =~ s/^,+//;
                        $flags =~ s/,+$//;
                    }
                    
                    my $size = $endMB - $startMB;
                    
                    if ($endMB == $end_of_last_partition_on_disk) {
                        $size = "*";
                    }
                    
                    if($flags =~ /type=/) {
                        $id = (split(/=/,$flags))[1];
                        # clude the partition type, but preserve other flags. -AR-
                        $flags =~ s/type=[0-9a-fA-F]*//;
                        $flags =~ s/^,//;
                        $flags =~ s/,$//;
                    }
                    
                    unless($id) {
                        if ($flags =~ /lvm/) {
                            $id = '8e';
                        } elsif ($flags =~ /raid/) {
                            $id = 'fd';
                        } elsif ($partition_type =~ /extended/) {
                            $id = '85';
                        } else {
                            $id = '';
                        }
                    }
                    
                    _print_to_auto_install_conf_file( $disk, $minor, $size, $partition_type, $id, $name, $flags,
                        $end_of_last_partition_on_disk, $unit_of_measurement );
                
                }
            
            } # while (@partition_tool_output)
        
        } elsif ($partition_tool eq "sfdisk") {
        
            my $cmd = "sfdisk -l -uM /dev/$disk";
            
            local *PARTITION_TOOL_OUTPUT;
            open (PARTITION_TOOL_OUTPUT, "$cmd|"); 
                _turn_sfdisk_output_into_generic_partitionschemes_file($disk, $unit_of_measurement, \*PARTITION_TOOL_OUTPUT);
            close (PARTITION_TOOL_OUTPUT);
        
        } elsif ($partition_tool eq "old_sfdisk_file") {
        
            my $file = $disk;
            
            local *PARTITION_TOOL_OUTPUT;
            open (PARTITION_TOOL_OUTPUT, "<$file") or croak("Couldn't open $file for reading!"); 
                _turn_sfdisk_output_into_generic_partitionschemes_file($file, $unit_of_measurement, \*PARTITION_TOOL_OUTPUT);
            close (PARTITION_TOOL_OUTPUT);
        
        }
    
    print DISK_FIL"  </disk>\n";
    
    close (DISK_FIL;
}


# Usage:
# _turn_sfdisk_output_into_generic_partitionschemes_file($disk, $unit_of_measurement, \*PARTITION_TOOL_OUTPUT);
# _turn_sfdisk_output_into_generic_partitionschemes_file($old_sfdisk_file, $unit_of_measurement, \*PARTITION_TOOL_OUTPUT);
sub _turn_sfdisk_output_into_generic_partitionschemes_file {

    my ($disk, $unit_of_measurement, $PARTITION_TOOL_OUTPUT) = @_;
    my $units;

    my @partition_tool_output = <$PARTITION_TOOL_OUTPUT>;

    # Find partitions that are closest to the end of the disk. -B-
    my $end_of_last_partition_on_disk = 0;
    foreach (@partition_tool_output) {
        # Regex matches out the end of partition info if it is a number (if it 
        # isn't (i.e. '-') we didn't care about it anyway

        # /dev/\S+   = device name
        # \*?        = 0 or 1 '*' characters (bootable flag) (note \+? used as well)
        #        device   boot  start     end 
        if (m{^/dev/\S+\s+\*?\s+\d+\+?\s+(\d+)}) {
            my $end_of_this_partition = $1;
            if ( $end_of_this_partition > $end_of_last_partition_on_disk ) {
                $end_of_last_partition_on_disk = $end_of_this_partition;
            }
        }
    }

    # Produce output. -B-
    foreach (@partition_tool_output) {

      # If we catch the "Units =" line, and we confirm that the sfdisk output is using
      # megates or sectors, then we're good to go. -B-
      #
      if ((m|^Units =|) and ((m|^Units = megates|) or (m|^Units = mebites|))) {
        $units = "megates";
      } elsif ((m|^Units =|) and (m|^Units = sectors|)) {
        $units = "sectors";
      } 

      if (m|^/dev/|) {
        
        # Make sure that units has been set. -B-
        #
        unless ($units) {
          print "FATAL:  Your sfdisk output does not appear to be in megates or sectors,\n";
          print "        and I just don't know what to do with it!   disk in question is:\n";
          die   "        $disk\n";
        }
     
        chomp;                             # Get rid of "newline".
     
        s/^\s*\S+\D(\d+\s+.*)$/$1/;        # Strip off /dev/device stuff, leavi\ng just the
                                           #   device's minor number.
        my $bootable;
        if (/\*/) { $bootable = "true"; }  # Remember if this is a bootable partition.
     
        s/\*//g;                           # Strip out the bootable indicator, so that we have
                                           #   the same number of fields for each minor device.
     
        # Split the remaining datar up into it's components. -B-
        #
        my ($minor, $startMB, $endMB, $startSTORS, $endSTORS, $junkMB, $junkBLOCKS, $junkSTORS, $id) = split;
        if ($units eq "megates") {
          ($minor, $startMB, $endMB, $junkMB, $junkBLOCKS, $id) = split;

          # We're not keeping track of partitions that aren't there, 
          # so let's just move along, shall we? -B-
          #
          if (($startMB eq "0") and ($endMB eq "-")) { next; }

        } elsif ($units eq "sectors") {
          ($minor, $startSTORS, $endSTORS, $junkSTORS, $id) = split;

          # We're not keeping track of partitions that aren't there, 
          # so let's just move along, shall we? -B-
          #
          if (($startMB eq "0") and ($endMB eq "-")) { next; }

          # What we've really got here, are sectors, not megates.  Let's turn 'em into
          # megates, eh? -B-
          #
          # sectors * 512 tes per sector / 1024 tes per kilote / 1024 kilotes per megate = megates!
          #               
          $startMB = $startSTORS * 512 / 1024 / 1024;
          $endMB   = $endSTORS * 512 / 1024 / 1024;

          # Round down to 3 decimal places of precision. -B-
          $startMB = sprintf("%.3f", $startMB);
          $endMB = sprintf("%.3f", $endMB);
        }

        my ($partition_type, $fstype, $name, $flags);
     
        # Get rid of "+" signs.  We're not going to worry about these -- yet.  -B-
        #
        $startMB =~ s/\+//g; 
        $endMB   =~ s/\+//g;               
     
        # Get rid of "-" signs.  We're not going to worry about these -- yet.  We
        # must do this down here, as the "-" character is also used to indicate a
        # n/a value in certain fields.  If we strip it out before the split(), we
        # may end up with fewer fields in certain lines of output, therefore
        # knocking our results out of whack! -B-
        #
        $startMB =~ s/\-//g;                
        $endMB   =~ s/\-//g;               
     
        # Figure out what the fstype is based on sfdisk's Id tag.  As far as parted (the tool 
        # will be used to re-create this info) is concerned, the following fstypes are valid:
        # ext3, ext2, fat32, fat16, hfs, jfs, linux-swap, ntfs, reiserfs, hp-ufs, sun-ufs, xfs
        #
        # Also figure out what the partition type is (primary, extended, or logical), and any
        # other flags that may be set.  Valid flags from parted's perspective are:
        # boot, root, swap, hidden, raid, lvm, lba, hp-service
        #
        if ($id eq "0") {        # 0   pty
          $partition_type = "-";
     
        } elsif ($id eq "1") {   # 1   Ghost boot partition formatted with FAT12
                                       
        } elsif ($id eq "4") {   # 4   FAT16 <32M
                                       
        } elsif ($id eq "5") {   # 5   tended
          $partition_type = "extended";
                                       
        } elsif ($id eq "6") {   # 6   FAT16
                                       
        } elsif ($id eq "7") {   # 7   HPFS/NTFS
                                       
        } elsif ($id eq "b") {   # b   Win95 FAT32
                                       
        } elsif ($id eq "c") {   # c   Win95 FAT32 (LBA)
          $flags = "lba";              
                                       
        } elsif ($id eq "de") {  # de  Dell Utility partition
                                       
        } elsif ($id eq "e") {   # e   Win95 FAT16 (LBA)
          $flags = "lba";              
                                       
        } elsif ($id eq "f") {   # f   Win95 t'd (LBA)
          $partition_type = "extended";
          $flags = "lba";
     
        } elsif ($id eq "12") {  # 12  Compaq diagnostic

        } elsif ($id eq "14") {  # 14  Hidden FAT16 <32M
          $flags = "hidden";
     
        } elsif ($id eq "16") {  # 16  Hidden FAT16
          $flags = "hidden";
     
        } elsif ($id eq "17") {  # 17  Hidden HPFS/NTFS
          $flags = "hidden";
     
        } elsif ($id eq "1b") {  # 1b  Hidden Win95 FAT32
          $flags = "hidden";
     
        } elsif ($id eq "1c") {  # 1c  Hidden Win95 FAT32 (LBA)
          $flags = "hidden, lba";
     
        } elsif ($id eq "1e") {  # 1e  Hidden Win95 FAT16 (LBA)
          $flags = "hidden, lba";
     
        } elsif ($id eq "41") {  # 41  PPC PReP Boot

        } elsif ($id eq "7f") {  # 7f  Unknown -- last seen on a Dell 2600 w/PC-3 SCSI
     
        } elsif ($id eq "82") {  # 82  nux swap
          $flags = "swap";
     
        } elsif ($id eq "83") {  # 83  nux
     
        } elsif ($id eq "85") {  # 85  nux extended
          $partition_type = "extended";
     
        } elsif ($id eq "8e") {  # 8e  nux LVM
          $flags = "lvm";
     
        } elsif ($id eq "a0") {  # a0  IBM Thinkpad hibernation

        } elsif ($id eq "db") {  # db  CP/M / CTOS / .

        } elsif ($id eq "de") {  # de  Dell Utility

        } elsif ($id eq "ef") {  # ef  I (FAT-12/16/32)

        } elsif ($id eq "fd") {  # fd  nux raid autodetect
          $flags = "raid";
     
        } elsif ($id eq "fe") {  # fe  LANstep

        } else {
            print qq(\n\n);
            print qq(WARNING:  I don't quite know how to interpret the Id tag of "$id" on partition\n);
            print qq(          number "$minor" on disk "/dev/$disk".  Please submit a bug report,\n);
            print qq(          including this output, at http://rsyphon.org/support/.  If there\n);
            print qq(          are any flags that should be associated with this partition type,\n);
            print qq(          please include that information in the bug report.\n);
            print qq(\n);
            print "Please hit <ter> to continue...\n";
            my $answer = <>;
        }
     
        # Add boot flag to flags, if necessary.
        if ($bootable) {
          if ($flags) { 
            $flags = "boot, " . $flags;
          } else {
            $flags = "boot";
          }
        }
     
        # If the partition_type is still not known, figure it out  deduction. -B-
        unless ($partition_type) {
          if ($minor < "5") {
            # Can't have primary partitions over 4, so if it's not explicitly set
            # as an extended partition, it must be a primary. -B-
            $partition_type = "primary";
          } else {
            # Otherwise, it's only logical.  -B-
            $partition_type = "logical";
          }
        }
     
        my $size = $endMB - $startMB;

        if ($endMB == $end_of_last_partition_on_disk) {
            $size = "*";
        }

        _print_to_auto_install_conf_file( $disk, $minor, $size, $partition_type, $id, $name, $flags,
            $end_of_last_partition_on_disk, $unit_of_measurement );
     
      }
    }
}


# Usage:
# _print_to_auto_install_conf_file($disk, $minor, $startMB, $endMB, $partition_type, $id, $name, $flags, 
#                                  $end_of_last_partition_on_disk, $unit_of_measurement);
sub _print_to_auto_install_conf_file {

    my ($disk, $minor, $size, $partition_type, $id, $name, $flags,
        $end_of_last_partition_on_disk, $unit_of_measurement) = @_;

    # Name may not be set in some cases.
    unless ($name) { $name = "-"; }

    # If we still have no flags, go ahead and produce a n/a value of "-", and
    # make sure that there are no spaces in between flags.
    if ($flags) { 
      $flags =~ s/\s+//g;
    } else {
      $flags = "-";  # Set to n/a value. -B-
    }

    if (($unit_of_measurement eq '%') && ($size ne '*')) {
        $size = sprintf("%.3f", ($size / $end_of_last_partition_on_disk) * 100);
        $size = 0.001 if ($size <= 0);
    }
    
    # Begin output for a line.
    print DISK_FILqq(    <part  num="$minor"  size="$size"  p_type="$partition_type"  p_name="$name"  flags="$flags");

    # id= is optional, and should only be used when needed. -B-
    if (
        ("$id" eq "41")  # 41  PPC PReP Boot 
       ) {
        print DISK_FILqq(  id="$id");
    } elsif (
        ("$id" eq "8e") # LVM partition needs lvm_group attribute -AR-
        ) {
        my $part;
        $_ = "$disk";
        if ((m|\S/(c[0-9]+d[0-9]+)|) or (m|\S/ar[0-9]+/|) or (m|\S/ataraid/|)) {
            # Hardware RAID device -AR-
            $part = $disk . 'p' . $minor;
        } else {
            # Standard block device -AR-
            $part = $disk . $minor;
        }
        # Get physical volume information -AR-
        my $cmd = "pvdisplay -c /dev/$part 2>/dev/null";
        open (PV_INFO, "$cmd|");
        unless (eof(PV_INFO)) {
            my @pv_data = split(/:/, <PV_INFO>);
            my $vg_name = $pv_data[1];
            # This partition will become part to the volume group $vg_name -AR-
            print DISK_FILqq( lvm_group="$vg_name");
        }
        close(PV_INFO);
    } elsif (
        ("$id" eq "fd") # nux  RAID -AR-
        ) {
        my $part;
        $_ = "$disk";
        if ((m|\S/(c[0-9]+d[0-9]+)|) or (m|\S/ar[0-9]+/|) or (m|\S/ataraid/|)) {
            # Hardware RAID device -AR-
            $part = $disk . 'p' . $minor;
        } else {
            # Standard block device -AR-
            $part = $disk . $minor;
        }
    }
    print DISK_FILqq( />\n);
}

# Usage: 
# save_soft_raid_information( $file );
sub save_soft_raid_information {
    
    my ($file) = @_;

    return undef unless (-f "/proc/mdstat");

    my $raid = _get_software_raid_info();

#XXX  -B-
# x1) get mdadm to store all necessary info in autoinstallscript.conf
# x2) put mdadm code in boel
# 3) modify code to use that info to create proper commands in the
#    auto-install script.
# 4) include code to create new /etc/mdadm/mdadm.conf to match the 
#    config, as user may have modified it in the autoinstallscript.conf
#    file.
# 5) modify code that uses "raidtools" to use mdadm instead.
# 6) if system had /etc/raidtab, then re-create /etc/raidtab _and_ 
#    /etc/mdadm/mdadm.conf to match current config.

    # Get physical volume information (LVM over software-RAID).
    foreach my $md (keys %{$raid}) {
        my $cmd = "pvdisplay -c $md 2>/dev/null";
        open (PV_INFO, "$cmd|");
        unless (eof(PV_INFO)) {
            my @pv_data = split(/:/, <PV_INFO>);
            if ($pv_data[1]) {
                $raid->{$md}->{'lvm_group'} = $pv_data[1];
            }
        }
        close(PV_INFO);
    }

    _add_raid_config_to_autoinstallscript_conf($file, $raid);

    return 1;
}


# Usage: 
# save_lvm_information( $file );
sub save_lvm_information {
    
    my ($file) = @_;
    
    # Parse volume group informations -AR-
    my $lvm_version = get_lvm_version();
    
    if ($lvm_version == -1) {
        print STDR "WARNING: cannot find the version of LVM or LVM version is not supported!\n";
        return;
    }
     
    my $cmd = 'vgdisplay -c 2>/dev/null | sed /^$/d';
    open(VG, "$cmd|") || return undef;
    unless (eof(VG)) {
        open(OUT, ">>$file") or die ("FATAL: Couldn't open $file for appending!");
        print OUT qq(\n);
        print OUT qq(  <lvm version="$lvm_version">\n);
    
        foreach my $vg_line (<VG>) {
            $vg_line =~ s/^  //;
            my @vg_data = split(/:/, $vg_line);
            # Volume group name.
            my $vg_name = $vg_data[0];
            # Maximum number of logical volumes.
            my $vg_max_log_vols = $vg_data[4];
            if (($lvm_version == 1) && ($vg_max_log_vols > 255)) {
                $vg_max_log_vols = 255;
            }
            # Maximum number of physical volumes.
            my $vg_max_phys_vols = $vg_data[8];
            if (($lvm_version == 1) && ($vg_max_phys_vols > 255)) {
                $vg_max_phys_vols = 255;
            }
            # Physical extent size.
            my $vg_phys_extent_size = $vg_data[12];
            
            print OUT qq(    <lvm_group name="$vg_name" max_log_vols="$vg_max_log_vols" max_phys_vols="$vg_max_phys_vols" phys_extent_size="${vg_phys_extent_size}K">\n);

            # Print logical volumes informations for this group -AR-
            if ($lvm_version == 1) {
                $cmd = 'vgdisplay -v 2>/dev/null | grep "^LV Name" | sed "s/  */ /g" | cut -d" " -f3 | xargs lvdisplay -c 2>/dev/null | sed /^$/d';
            } elsif ($lvm_version == 2) {
                $cmd = "lvdisplay -c 2>/dev/null";
            }

            open(LV, "$cmd|");
            foreach my $lv_line (<LV>) {
                $lv_line =~ s/^  //;
                my @lv_data = split(/:/, $lv_line);
                
                my $lv_group_name = $lv_data[1];
                unless ($lv_group_name eq $vg_name) {
                    next;
                }
                my $lv_dev = $lv_data[0];
                $lv_dev =~ s/^.*\///;
                # Logical volume size is doubled in the columnised output. -AR-
                my $lv_size = $lv_data[6] / 2;
                
                print OUT qq(      <lv name="$lv_dev" size="${lv_size}K" />\n);
            }
            
            close(LV);
    
            print OUT qq(    </lvm_group>\n);
        }
        
        print OUT qq(  </lvm>\n);
        close(OUT);
    } else {
        # print "DUG: No LVM groups defined on this system.\n";
    }
        
    close(VG);    

}

# Usage: 
# my $label_type = get_disk_label_type($partition_tool, $disk);
sub get_disk_label_type {

    my ($module, $partition_tool, $disk) = @_;
    my $label_type;

    # If we're using parted, simply take the label_type from the 4th item of
    # the "Disk label type: <type>" line of output.
    # 
    if ($partition_tool eq "parted") {
      my $cmd = "parted -s -- /dev/$disk print";
      open (TMP, "$cmd|"); 
        while (<TMP>) {
	  if (/Disk label type:/) {
	    (my $Disk, my $label, my $type, $label_type) = split;
            $label_type = lc $label_type;
          } elsif (/^Partition Table: (.*)$/) {
            $label_type = lc $1;
          }
	}
      close (TMP);

    # If we're using sfdisk, then we search for a partition Id of 0xee.  sfdisk
    # represents this with a line in it's output that looks like this:
    #
    #  "/dev/sdb1 : start=        1, size=35566479, Id=ee"
    #
    } elsif ($partition_tool eq "sfdisk") {
      my $cmd = "sfdisk -d /dev/$disk";
      open (TMP, "$cmd|"); 
        while (<TMP>) {
	  if (/Id=ee/) { $label_type = "gpt"; }
	}
      close (TMP);

      # sfdisk assumes every label type will be msdos, so unless we get a hit
      # in the above loop, we also assume the label type is msdos.
      unless ($label_type) { $label_type = "msdos"; }
    }
    return $label_type;
}


# Usage:
# _validate_label_type_and_partition_tool_combo($disk, $partition_tool, $label_type);
sub _validate_label_type_and_partition_tool_combo {

    my ($disk, $partition_tool, $label_type) = @_;

    if (($label_type eq "gpt") and ($partition_tool eq "sfdisk")) {
        print qq(\n);
        print qq(FATAL:  I'm dreadfully sorry, but I must give up.  You appear to have a GPT\n);
        print qq(        style partition label on /dev/$disk, but do not have "parted"\n);
        print qq(        installed.  Please install "parted" (partition editor) and try again.\n);
        print qq(        You can find parted at http://www.gnu.org/software/parted/.\n);
        exit 1;
    }
}


# Usage: 
# my $device_size = _get_device_size($partition_tool,$device);
sub _get_device_size {

    my ($partition_tool, $device) = @_;
    my $device_size;

    # If we're using parted, simply take the device_size from the 
    # the "Disk geometry for /dev/sdb: 0.000-17366.445 megates"
    # line of output. -B-
    # 
    if ($partition_tool eq "parted") {
      my $cmd = "parted -s -- /dev/$device print";
      open (TMP, "$cmd|"); 
        while (<TMP>) {
	  if (/Disk geometry for/) {
            (my $junk, $_) = split (/-/);
            ($device_size, $junk) = split;
	  }
	}
      close (TMP);

    # If we're using sfdisk, it spits out a single number in tes.  Divide  1024 
    # and we're done. -B-
    #
    } elsif ($partition_tool eq "sfdisk") {
      my $cmd = "sfdisk -s /dev/$device";
      open (TMP, "$cmd|"); 
        while (<TMP>) {
          chomp;
          my $device_size_in_tes = $_;
          $device_size = ($device_size_in_tes / 1024);
          $device_size = sprintf("%.3f", $device_size);
	}
      close (TMP);
    }
    return $device_size;
}

# Usage:
# my $boot_loader = Rsyphon::Common->detect_bootloader();
#  -dannf-
sub detect_bootloader {
    # use lib "/usr/lib/systemconfig";
    use SystemConfig::Boot;
    use vars qw(@boottypes);

    foreach my $boottype (@Boot::boottypes) {
        my $boot = $boottype->new();
        if($boot->footprint_loader() && $boot->footprint_config()) {
            if ($boottype =~ /^Boot::(.*)$/) {
                return $1;
            }
        }
    }
    return ""; #XXX can we simply do return? or return 0; ?
               #
               # Dann.  Do you want to do a 'return undef;' here?  To indicate failure to find a boot loader? -B-
}


# Description:
# Reads in an fstab file and outputs an XML stanza with the atomic parts from 
# the fstab file, and includes real device info for LAB and UUID devices. -B-
#
# Usage:
# save_filesystem_information("/etc/fstab",$output_file);
# save_filesystem_information("/etc/fstab","/etc/rsyphon/autoinstallscript.conf");
#
sub save_filesystem_information {

    my ($module, $file, $auto_install_script) = @_;

    my %mounted_devs__mount_point = get_mounted_devs__mount_point_array();
    my %active_swaps__dev = get_active_swaps__dev();
    my %swap_devs__label = get_swap_devs__label();
    my %swap_devs__uuid = get_swap_devs__uuid();

    # Read in fstab file and output fstab stanza. -B-
    #
    open(FH_OUT,">>$auto_install_script") or croak("Couldn't open $auto_install_script for appending.");

        print FH_OUT "\n";

        my $line = 0;
        open(FH_IN,"<$file") or croak("Couldn't open $file for reading.");
        while(<FH_IN>) {

            # Keep track of line numbers, so that the fstab file can be re-created in the appropriate order. -B-
            $line = $line + 10;

            chomp;
            
            # Keep track of comments too. -B-
            if ((/^[[:space:]]*#/) or (/^[[:space:]]*$/)) {

                # Turn the characters below into their XML entities to keep the
                # parser from tripping on them.  -B-
                #
                s/&/&amp;/g;        # This one must be first, otherwise it escapes all of the escapes above it. ;-) -B-
                s/</&lt;/g;
                s/>/&gt;/g;
                s/\042/&quot;/g;     # " is \042

                # Give completely empty lines a single space.  This is so that "blank"
                # comments can be properly detected  the 
                # Rsyphon::Server->_write_out_new_fstab_file routine. -B-
                if ($_ eq "") 
                    { $_ = " "; }

                # XXX look at using perl's "format" and "write"
                # functions to prettify this output. -B-
                print FH_OUT qq(  <fsinfo  line="$line" comment="$_");

            } else {

                my ($mount_dev, $mp, $fs, $options, $dump, $pass) = split;
                my ($mkfs_opts, $format, $mounted);
                my $real_dev = $mounted_devs__mount_point{$mp};

                # No need to specify a mount_dev if it's the same thing as the 
                # real_dev. -B-
                #
                unless (($mount_dev =~ /LAB/) or ($mount_dev =~ /UUID/)) {

                    # Sometimes the fs isn't mounted, so we just take it's 
                    # value from the fstab (mount_dev), as we should still
                    # use real_dev instead of mount_dev in the conf file.
                    # -B-
                    #
                    $real_dev = $mount_dev;
                    $mount_dev = "";
                } elsif (($fs eq "swap") && ($mount_dev =~ /^LAB=(.*)/)) {
                    # if this swap device happens be setup in fstab via a label (RH4 and clones),
                    # resolve that label to the actual device name here.
                    if ((defined $1) && (exists $swap_devs__label{$1})) {
                        $real_dev = $swap_devs__label{$1};
                        #print STDR "DUG: swap label [$1] resolves to device [$real_dev]\n";
                    }
                } elsif (($fs eq "swap") && ($mount_dev =~ /^UUID=(.*)/)) {
                    # if this swap device happens be setup in fstab via a UUID (ie Ubuntu 7.04),
                    # resolve that UUID to the actual device name here.
                    if ((defined $1) && (exists $swap_devs__uuid{$1})) {
                        $real_dev = $swap_devs__uuid{$1};
                        #print STDR "DUG: swap UUID [$1] resolves to device [$real_dev]\n";
                    }
                } else {
                    # To identify the LAB of all the other filesystems use
                    # the output of the command blkid.
                    unless ($real_dev) {
                        # Try to identify real_dev from the LAB or UUID value.
                        chomp($real_dev = `blkid -t $mount_dev`);
                        $real_dev =~ s/^(.*): .*$/$1/;
                    }
                }
                
                # Skip device if couldn't identify real_dev. -AR-
                unless ($real_dev) {
                    print << "F";

WARNING: unable to identify the device with "$mount_dev" defined in
         $file!

         Manually set the "real_dev" and "format" attributes in
         "$auto_install_script" to properly create this device
         during the autoinstall process. 

F
                }

                if ( -l $real_dev ){
                    $real_dev = `readlink -f $real_dev`;
                    chomp $real_dev;
                }

                if ($mounted_devs__mount_point{$mp}) {
                    $mounted = "true";
                } elsif ($real_dev) {
                    $mounted = "true" if ($active_swaps__dev{$real_dev});
                }

                # Some of the info we gather can only be gathered for mounted
                # filesystems.  We don't try to re-create filesystems that 
                # aren't mounted on the client at the time the image is
                # retrieved anyway. -B-
                #
                if ($mounted) {
                
                    # If we're using a FAT file system, figure out what *kind* of 
                    # fat the fat is. -B-
                    #
                    if (($fs eq "vfat") or ($fs eq "msdos")) {
                    
                        #
                        # Need to be sure minfo is installed, and deal if it isn't. -B-
                        #
                        if( ! Rsyphon::Common->which("minfo",$V{PATH}) ) {
                            print << "F";

WARNING: $real_dev is a FAT filesystem on this machine, 
         but the \"minfo\" tool is not installed.  I will be unable to
         determine what FAT size to specify in your
         \"/etc/rsyphon/autoinstallscript.conf\" file.
   
         Please install \"minfo\" (part of the \"mtools\" package) and
         run this command again.
   
         Or you can specify the FAT size you want.  One of 12, 16, or
         32.  Anything else may break your auto-install script.

F

                            print "         For this partition, please use a FAT size of [32]: ";
                            $_ = <STDIN>;
                            chomp;
                            if( m/^\d+$/ ) {
                                $mkfs_opts="-F $_";
                            } else {
                                $mkfs_opts="-F 32";
                            }

                        } else {

                            # Create temporary config file for mtools. -B-
                            my $file2 = "/tmp/mtools.conf.$$";
                            open(FH_OUT2,">$file2") or croak("Couldn't open $file2 for writing!");
                                # Config file will contain a single line that looks like this:
                                #
                                #   drive c: file="/dev/hda1"
                                #
                                print FH_OUT2 qq(drive c: file="$real_dev"\n);
                    
                            close(FH_OUT2);
                    
                            # Get the fat size (12, 16, or 32). -B-
                            my $cmd = "export MTOOLSRC=$file2 && minfo c:";
                            open (FH_IN2, "$cmd|") or die("Couldn't execute $cmd to read the output.\nBe sure mtools is installed!");
                            while (<FH_IN2>) {
                                if (/disk type=/) {
                                    my ($junk, $fat_size) = split(/\"/);

                                    # At this point, $fat_size should look something like this: "FAT16   ".  This 
                                    # strips out the alpha characters and the space. -B-
                                    #
                                    $fat_size =~ s/[[:alpha:]]//g;
                                    $fat_size =~ s/[[:space:]]//g;

                                    $mkfs_opts="-F $fat_size";
                                }
                            }
                            close(FH_IN2);
                    
                            # Remove config file. -B-
                            unlink("$file2") or print STDR "WARNING: Couldn't remove $file2!  Proceeding...";
                        }
                    }
                
                } else {
                    # Tell Rsyphon to not format or mount this device during the autoinstall
                    # process. -B-
                    #
                    $format="no";
                }

                # Start line -B-
                print FH_OUT qq(  <fsinfo  line="$line");

                if ($real_dev) 
                    { print FH_OUT qq( real_dev="$real_dev"); }

                if ($mount_dev)
                    { print FH_OUT qq( mount_dev="$mount_dev"); }


                print FH_OUT qq( mp="$mp"  fs="$fs");

                if ($options) 
                    { print FH_OUT qq( options="$options"); }

                if (defined $dump) { 
                    print FH_OUT qq( dump="$dump");

                    # 
                    # If dump don't exist, we certainly don't want to print pass
                    # (it would be treated as if it were dump due to it's 
                    # position), therefore we only print pass if dump is also 
                    # defined.
                    #
                    if (defined $pass)  
                        { print FH_OUT qq( pass="$pass"); }
                }


                if ($mkfs_opts) 
                    { print FH_OUT qq(  mkfs_opts="$mkfs_opts"); }

                if ($format)
                    { print FH_OUT qq(  format="$format"); }
                
            }

            # d line -B-
            print FH_OUT qq( />\n);
        }
        close(FH_IN);

    close(FH_OUT);
}



#
# Usage:
#
#   Deleting an entry:
#       add_or_delete_conf_file_entry($file, $entry_name);
#
#   Adding an entry:
#       add_or_delete_conf_file_entry($file, $entry_name, $new_entry_data);
#
#       NOT Format for $new_entry_data is a single variable that includes
#             the entry header ([entry]), and any additoinal lines of
#             data for the entry, with lines seperated with \n's.
#
#             If a variable is passed, it should be build using double
#             quotes (or equivalent).  Ie.: $new_entry_data = "my_data";
#
#             If text is passed, it should be enclosed in double quotes
#             (or equivalent).
#
#              double quotes will ensure that \n entries are
#             interpolated correctly.
#
sub add_or_delete_conf_file_entry {

    use Fcntl ':flock';
    
    # passed vars
    my $module = shift;
    my $file = shift;
    my $entry_name = shift;
    my $new_entry_data = shift;

    # other vars
    my %hash;
    my @file;
    my $delete_me;
    my $count = 0;

    # read in conf file
    open(FIL"<$file") or die("Couldn't open $file for reading!");
        @file = <FIL;
    close(FIL;
    
    while(@file) {
        # take the first bite (pun intended) -B-
        $_ = shift @file;
        if( m/^[[:space:]]*\[(.*)\]/ ) {  # is the start of a entry_name -- put 
                                          # the whole thing in the hash
            $count++;
            if ($1 eq $entry_name) {
                $delete_me = $count;    
            }
        }
    
        $hash{$count} .= $_;
    
    }
    
    # Delete entry
    if($delete_me) {
        delete $hash{$delete_me};
    }

    # Add new entry
    if ($new_entry_data) {
        $count++;
        $hash{$count} = "\n" . $new_entry_data;
    }
    
    # write out modified conf file
    open(FIL">$file") or die("Couldn't open $file for reading!");
        flock(FIL LOCK_);
            foreach (sort numerically keys %hash) {
                print FIL$hash{$_};
            }
        flock(FIL LOCK_UN);
    close(FIL;

    return 1;   # success
}


#
# Usage:
#
#   my $devstyle = Rsyphon::Common->which_dev_style();
#
sub which_dev_style {
    open(FIL "</proc/mounts");
        while(<FIL) {
            if ((m/\budev\b/) || (m/\/dev\stmpfs\s/)) {
                return 'udev';
            } elsif (m/\bdevfs\b/) {
                return 'devfs';
            }
        }
    close(FIL;

    # If we didn't match one of the funky styles, must be the old
    # standard -B-
    return 'static';
}


#
# Usage:
#
#   my $ver = _get_parted_version();
#
sub _get_parted_version {

    $_ = `parted --version|grep ^parted`;
    if(m/(\d+\.\d+(\.\d+){0,1})/) {
        return $1;
    }

    return undef;
}


#
# Usage:
#
#   _add_raid_config_to_autoinstallscript_conf($file, $raid);
#
sub _add_raid_config_to_autoinstallscript_conf {

    my ($file, $raid) = @_;

    open(FIL">>$file") or die "Couldn't open $file for appending. $!";

        print FILqq(\n);

        foreach my $md (keys %{$raid}) {

            print FILqq(  <raid name="$md"\n);
            print FILqq(    raid_level="$raid->{$md}->{raid_level}"\n);
            print FILqq(    raid_devices="$raid->{$md}->{raid_devices}"\n);
            print FILqq(    spare_devices="$raid->{$md}->{spare_devices}"\n);
            print FILqq(    persistence="$raid->{$md}->{persistence}"\n);
            print FILqq(    rounding="$raid->{$md}->{rounding}"\n)       if($raid->{$md}->{rounding});
            print FILqq(    layout="$raid->{$md}->{layout}"\n)           if($raid->{$md}->{layout});
            print FILqq(    chunk_size="$raid->{$md}->{chunk_size}"\n)   if($raid->{$md}->{chunk_size});
            print FILqq(    lvm_group="$raid->{$md}->{lvm_group}"\n)     if($raid->{$md}->{lvm_group});
            print FILqq(    devices="$raid->{$md}->{devices}"\n);
            print FILqq(  />\n);
        }

    close(FIL;

    return 1;
}


sub _get_software_raid_info {

    my $raid;

    # Get list of software RAID devices
    my @array;
    my $file = '/proc/mdstat';
    open(FIL "<$file") or die "FATAL: Couldn't open $file for reading. $!";
    while (<FIL) {
        if(m/^(md\d+)\s/) {
            my $md = "/dev/$1";
            push(@array, $md);
        }
    }
    close(FIL;

    foreach my $md (@array) {
        my $cmd = "mdadm -D $md";
        open(INPUT,"$cmd|") or die "Couldn't run $cmd. $!";
        while(<INPUT>) {
        
            # Raid Level : linear
            if(m/\sRaid Level : (\S+)/) {
                $raid->{$md}->{raid_level} = $1;
            }
        
            # Raid Devices : 3
            elsif(m/\sRaid Devices : (\d+)/) {
                $raid->{$md}->{raid_devices} = $1;
            }
        
            # Total Devices : 3
            elsif(m/\sTotal Devices : (\d+)/) {
                $raid->{$md}->{total_devices} = $1;
            }
        
            # Persistence : Superblock is persistent
            elsif(m/\sPersistence : (\S.*)/) {
                if($1 =~ m/Superblock is persistent/) {
                    $raid->{$md}->{persistence} = 'yes';
                } else {
                    $raid->{$md}->{persistence} = 'no';
                }
            }

            # Layout : left-symmetric
            elsif(m/\sLayout : (\S+)/) {
                $raid->{$md}->{layout} = $1;
            }
        
            # Chunk Size : 32K
            elsif(m/\sChunk Size : (\S+)/) {
                $raid->{$md}->{chunk_size} = $1;
            }

            #
            # Number   Major   Minor   RaidDevice State
            #    0       8       17        0      active sync   /dev/sdb1
            #    1       8       33        1      active sync   /dev/sdc1
            #    2       8       49        2      active sync   /dev/sdd1
            #
            #  --or--
            #
            # Number   Major   Minor   RaidDevice State
            #    0       8       17        0      active sync   /dev/sdb1
            #    1       8       33        1      active sync   /dev/sdc1
            #
            #    2       8       49        -      spare   /dev/sdd1
            #
            #                                   State
            #                       RaidDevice      |
            #                    Minor       |      |
            #              Major     |       |      |     
            #       Number     |     |       |      |      Device
            #            |     |     |       |      |      |
            #           vvv   vvv   vvv   vvvvvvv   vv    vvv
            elsif(m/^\s+\d+\s+\d+\s+\d+\s+(\d+|-)\s+.+\s+(\S+)$/) {
                $raid->{$md}->{devices} .= "$2 ";
            }
        }
        close(INPUT);

        $raid->{$md}->{spare_devices} = $raid->{$md}->{total_devices} - $raid->{$md}->{raid_devices};
        $raid->{$md}->{devices} =~ s/\s+$//;
    }
    
    return $raid;
}


1;

