#!/bin/bash
declare -a USBPRT
declare -a USBDRV
declare -a WDIDLE
TIMEOUT=600
LOG=/var/log/wdspindown.log
while true ; do
    # check available USB ports
    USBPRT=($(synodiskport -enum_port -usb $1))
    for prt in ${USBPRT[*]}; do
        # check disk mode (active, standby, not connected)
        USBDRV=($(smartctl -n standby /dev/$prt | grep -e ACTIVE -e STANDBY))
        if [[ ${USBDRV[3]} = "ACTIVE" ]] ; then
            # if active mode, get idle time
            WDIDLE=($(synodisk --get_idle /dev/$prt $1))
            if [ ${WDIDLE[2]} -gt ${TIMEOUT} ] ; then
                # if idle time greater as timeout, then spin down
                echo "$(date +%Y%m%d-%H:%M:%S) : last access to /dev/$prt is ${WDIDLE[2]} second(s) ago. Spin down..." #>> $LOG
                synodisk --usbstandby /dev/$prt
            else
                # wait until idle time greater as timeout
                ((WAIT=${TIMEOUT}-${WDIDLE[2]}))
                echo "$(date +%Y%m%d-%H:%M:%S) : last access to /dev/$prt is ${WDIDLE[2]} second(s) ago. Waiting $WAIT second(s)..." #>> $LOG
                sleep ${WAIT}
            fi
        elif [[ ${USBDRV[3]} = "STANDBY" ]] ; then
            # if standby mode, then wait
            echo "$(date +%Y%m%d-%H:%M:%S) : /dev/$prt is ${USBDRV[3]}" #>> $LOG
            sleep ${TIMEOUT}
        else
            # it no disk connected, then skip
            #echo "$(date +%Y%m%d-%H:%M:%S) : /dev/$prt is ${USBDRV[3]:-not connected}"
            sleep 0
        fi
    done
done
