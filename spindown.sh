#!/bin/bash
while true ; do
    timeOut=600
    usbDrvs=($(synousbdisk -enum | grep 'sd')) #  get available disk(s)
    for drv in ${usbDrvs[*]}; do
        if smartctl -q silent -n standby /dev/$drv ; then # get disk mode: active/idle - exit code 0, standby/notconnected - exit code 2
            idleTime=($(synodisk --get_idle /dev/$drv)) # get idle time
            if [ ${idleTime[2]} -gt ${timeOut} ] ; then # idle time greater as timeout? then spin down
                synodisk --usbstandby /dev/$drv
                echo "$(date +%Y%m%d-%H:%M:%S) : /dev/$drv is idle since ${idleTime[2]} second(s). Spin down..." >> /var/log/spindown.log
                synodsmnotify @administrators "USB Disk" "Spin Down"
            else
                ((timeOut=${timeOut}-${idleTime[2]})) # wait just until idle time greater as timeout
            fi
        fi
    done
    sleep ${timeOut}
done
