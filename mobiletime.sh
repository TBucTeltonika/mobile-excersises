#!/bin/sh
#1. Parašyti scriptą/programą kuri nustato router'io laiką/datą iš operatoriaus tinklo
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

get_devices

for NAME in ${DEVICES}; do
    getTTY ${NAME}
    echo "$ttyDEV"

    exec_AT_comm "ATE0"
    if [ $OK -eq 0 ]; then continue; fi 

    exec_AT_comm "AT+CPIN?"
    if [ $OK -eq 0 ]; then continue; fi 

    exec_AT_comm "AT+CREG?"
    if [ $OK -eq 0 ]; then continue; fi
        
    exec_AT_comm "AT+CCLK?"
    if [ $OK -eq 0 ]; then continue; fi 

    #RUTX11
    set -x
    date --set "20"${AT_OUTPUT:10:2}"-"${AT_OUTPUT:13:2}"-"${AT_OUTPUT:16:2}" "${AT_OUTPUT:19:8}
    { set +x; } 2>/dev/null
    
    break

done
