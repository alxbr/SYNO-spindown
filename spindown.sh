#!/bin/bash
# 
# /usr/local/etc/rc.d/spindown.sh

pid_file=/var/run/spindown.pid
log_file=/var/log/spindown.log

start_spindown_ctl () {
if [ -r $pid_file ]; then
	read mypid < $pid_file
	echo "$0 is already running. PID is $mypid"
	exit 0
else
	echo $$ > $pid_file
	echo "$(date +%Y%m%d-%H:%M:%S) : $0 is started. New PID is $$" >> $log_file
fi

trap 'stop_spindown_ctl' 2 # if started in interactive mode and ended with ctrl+c, the pid file should be deleted

while true ; do
    timeOut=600
    usbDrvs=($(synousbdisk -enum | grep 'sd')) #  get available disk(s)
    for drv in ${usbDrvs[*]}; do
        if smartctl -q silent -n standby /dev/$drv ; then # get disk mode: active/idle - exit code 0, standby/notconnected - exit code 2
            idleTime=($(synodisk --get_idle /dev/$drv)) # get idle time
            if [ ${idleTime[2]} -gt ${timeOut} ] ; then # idle time greater as timeout? then spin down
                synodisk --usbstandby /dev/$drv
                echo "$(date +%Y%m%d-%H:%M:%S) : /dev/$drv is idle since 10 minutes now. Spin down..." >> $log_file
            else
                ((timeOut=${timeOut}-${idleTime[2]})) # wait just until idle time greater as timeout
            fi
        fi
    done
    sleep ${timeOut}
done
}

stop_spindown_ctl () {
if [ -w $pid_file ] ; then
    read mypid < $pid_file
	rm $pid_file
	echo "$(date +%Y%m%d-%H:%M:%S) : $0 (PID $mypid) is stopped now" >> $log_file
	kill $mypid
else
	echo "$0 is not running"
fi
}

status () {
usbDrvs=($(synousbdisk -enum | grep 'sd'))
for drv in ${usbDrvs[*]}; do
	synodisk --get_idle /dev/$drv
	smartctl -n standby /dev/$drv | grep -e mode -e Mode
done
if [ -r $pid_file ] ; then
	read mypid < $pid_file
	echo "$0 is still running. PID is $mypid"
else	
	echo "$0 is not running"
fi
}

case $1 in
start) start_spindown_ctl;;
stop) stop_spindown_ctl;;
status) status;;
*) echo "Usage: $0 start|stop|status";;
esac
