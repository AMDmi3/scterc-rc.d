# rc.d script for boottime SCT ERC configuration #

## Synopsis ##

```shell
/etc/rc.d:

# Configure read/write timeouts on disks in redundant RAID so
# if read/write error occurs, array performance is not severely
# degraded by disks trying to read/write data for too long
scterc_enable="YES"
scterc_disks="ada0 ada1"  # disks to configure
scterc_read_timeout="70"  # 7 seconds
scterc_write_timeout="70" # 7 seconds
```

## About SCT ERC ##

Modern hard drives allow to set the amount of time a hard disk is
allowed to spend recovering from a read or write error. This feature
is called ERC (error recovery control, usually in Seagate), TLER
(time-limited error recovery, usually on Western Digital) or CCLT
(command completion time limit, usually on Samsung or Hitachi).

Desktop disks usually have this feature disabled by default and
don't limit time of read/write request, so they have highest chances
of recovering from errors and not losing data.

Disks designed for RAID usage, in contrast, have this feature enabled
by default and set a small timeout (usually 7 seconds), as in
redundant environement data may be quickly accessed from another
device, and a single disk should not delay requests for too long,
degrading array performance.

However, it is common now that even desktop disks are used in
redundant configurations, and most modern disks, though still having
ERC disabled by default, allow enabling it and setting a timeout,
so it is recommended to enable this setting to not have system
performance severely degraded when one of the drives start to
experience read/write errors.

The ERC setting, however, does not survive reboot and requires
updating it each time the system boots, and that's what this script
does.

## Viewing and setting SCT ERC by hand ##

You can view and change SCT ERC with smartctl from smartmontools package:

To view:

```
% smartctl -l scterc /dev/ada0 
smartctl 6.2 2013-07-26 r3841 [FreeBSD 10.0-RELEASE amd64] (local build)
Copyright (C) 2002-13, Bruce Allen, Christian Franke, www.smartmontools.org

SCT Error Recovery Control set to:
           Read: Disabled
          Write: Disabled

```

To set:

```
% smartctl -l scterc,70,70 /dev/ada0
smartctl 6.2 2013-07-26 r3841 [FreeBSD 10.0-RELEASE amd64] (local build)
Copyright (C) 2002-13, Bruce Allen, Christian Franke, www.smartmontools.org

SCT Error Recovery Control set to:
           Read:     70 (7.0 seconds)
          Write:     70 (7.0 seconds)

```

## Setting SCT ERC by this script ##

After installing this script by hand or with port, you should add
some lines to /etc/rc.conf to tell it which disks to configure and
which timeouts to set.

For simple configurations, there are 4 rc.conf variables to set:

- ```scterc_enable``` set to ```YES``` to enable the script
- ```scterc_disks``` specify space separated list of disks to configure
- ```scterc_read_timeout``` specify read timeout in tenths (1/10) of second, default is 70 (7.0 seconds)
- ```scterc_write_timeout``` specify write timeout in tenths (1/10) of second, default is 70 (7.0 seconds)

For more complex configurations when you have multiple disk groups for which you want different settings:

- ```scterc_enable``` set to ```YES``` to enable the script
- ```scterc_groups``` specify space separated list of disk group names

Then, for each group, you may specify individual settings:

- ```scterc_{group}_disks``` specify space separated list of disks to configure
- ```scterc_{group}_read_timeout``` specify read timeout in tenths (1/10) of second, default is ```scterc_read_timeout``` value
- ```scterc_{group}_write_timeout``` specify write timeout in tenths (1/10) of second, default is ```scterc_read_timeout``` value

You may use ```scterc_disks``` and ```scterc_groups``` at the same time.

## Example configuration ##

```shell
scterc_enable="YES"

scterc_disks="ada0 ada1"
scterc_read_timeout=100
scterc_write_timeout=100

scterc_groups="group1 group2"

scterc_group1_disks="ada2 ada3"
scterc_group1_read_timeout="120"
scterc_group1_write_timeout="120"

scterc_group2_disks="ada4 ada5"
scterc_group2_read_timeout="140"
```

This will configure read/write timeouts like this ada0:100/100, ada1:100,100, ada2:120/120, ada3:120/120, ada4:140/100, ada5:140/100.

## Diagnostics ##

To check your configuration, you can run script by hand, after which it will print which drives it configure and which timeouts is sets:

```
$ /usr/local/etc/rc.d/scterc start
Setting SCT ERC on disks: ada0:100,100 ada1:100,100 ada2:120,120 ada3:120,120 ada4:140,100 ada5:140,100.
$
```

The same line will be printed on the system startup. In case of error, ERROR message will be printed instead of timeout values for each disk which has failed to configure:

```
Setting SCT ERC on disks: ada0:ERROR ada1:ERROR
```

if that happens, check your config and/or run smartctl by hand as specified above and check its output for errors.

## See also ##

* [smartctl(8) manual page](http://smartmontools.sourceforge.net/man/smartctl.8.html)
* [Wikipedia article on ERC](http://en.wikipedia.org/wiki/Error_recovery_control)
* [Article on SCT ERC](http://habrahabr.ru/post/92701/) (Russian)
* Documentation on your hard drive

## License ##

CC0. This is just a simple script.

## Author ##

* [Dmitry Marakasov](https://github.com/AMDmi3) <amdmi3@amdmi3.ru>
