#!/bin/sh
#3. Parašyti scriptą/programą kuri prijungtų routerį prie interneto naudojant modemą ir PPP protokolą

#This was quite a mess. So pretty much what I have done is.
#put some values into UCI.
#call
#AT+CGDATA=\"PPP\",1
#this forces the modem to enter PPP mode and no more AT commands work after this.
#Then we need to restart network for the UCI changes to take effect.
#seems quite messy, but i think it's how it has to be done.

#TODO: Move to a seprate file and include it!
#will set DEV_NAME if its a modem.
CFG_FILE=modem_info
CFG_PATH=/tmp/
DEVICE_PATH=/sys/bus/usb/devices/

getTTY() {
        IFPATH=$(readlink -f $DEVICE_PATH$1)
        ttyDEV=$(ls $IFPATH | grep "ttyUSB*")
}
get_devices() {
        DEVICES=""
        i=0
        while uci -c $CFG_PATH get $CFG_FILE.@serial[$i] &>/dev/null; do
                CDEVICE=$(uci -c $CFG_PATH get $CFG_FILE.@serial[$i].device)
                DEVICES="${DEVICES} $CDEVICE"
                i=$((i + 1))
        done
}

exec_AT_comm() {
        OK=0
        echo "$1"
        AT_OUTPUT=$(echo $1 | atinout - /dev/$ttyDEV -)
        echo "$AT_OUTPUT"
        case $AT_OUTPUT in
        *ERROR*)
                OK=0
                echo "$AT_OUTPUT"
                ;;
        *OK)
                OK=1
                ;;
        *)
                OK=0
                ;;
        esac
}

set_PPP() {
        set -x
        uci set network.mobile=interface
        uci set network.mobile.proto='ppp'
        uci set network.mobile.device=${MODEM_DEVICE}
        uci set network.mobile.ipv6='auto'
        { set +x; } 2>/dev/null

}

modem_set_PPP() {
        set -x
        $(echo AT+CGDATA=\"PPP\",1 | atinout - $MODEM_DEVICE -) &
        PID=$!
        sleep 3
        kill $PID

        { set +x; } 2>/dev/null
}

get_devices

for NAME in ${DEVICES}; do
        getTTY ${NAME}
        echo "$ttyDEV"

        #checking if AT is responding..

        exec_AT_comm "ATE0"
        if [ $OK -eq 0 ]; then continue; fi 

        exec_AT_comm "AT+CPIN?"
        if [ $OK -eq 0 ]; then continue; fi 

        exec_AT_comm "AT+CREG?"
        if [ $OK -eq 0 ]; then continue; fi

        #sets config on the router.
        set_PPP

        #this function initalizes PPP mode.
        modem_set_PPP

        #restart device to commit the changes.
        ubus call network restart
        
        break

done
