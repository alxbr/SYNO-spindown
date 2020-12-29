# SYNO-spindown

If WD MyBook 8TB (or WD MyBook 12TB) connected via USB to Synology Disk Station (as daily backup HDD) wont sleep,
place this script in /usr/local/etc/rc.d/ to spin down the disk after 10 minutes inactivity, s. timeOut variable. 
The permission must be 755.
