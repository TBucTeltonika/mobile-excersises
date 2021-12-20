#!/bin/sh
#5. Hardcore, prijungti router'į prie dviejų skirtingų PDP context'ų

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

        #checking if AT is responding..

        exec_AT_comm "ATE0"
        if [ $OK -eq 0 ]; then continue; fi 

        exec_AT_comm "AT+CPIN?"
        if [ $OK -eq 0 ]; then continue; fi 

        exec_AT_comm "AT+CREG?"
        if [ $OK -eq 0 ]; then continue; fi

       exec_AT_comm "AT+CFUN=1"
        if [ $OK -eq 0 ]; then continue; fi

        sleep 1

        exec_AT_comm "AT+COPS=0"
        if [ $OK -eq 0 ]; then continue; fi

 

sleep 5

#Define the primary PDP context 1.
exec_AT_comm "AT+CGDCONT=1,\"IP\",\"omnitel\""
        if [ $OK -eq 0 ]; then continue; fi

exec_AT_comm "AT+CGACT=1,1"
        if [ $OK -eq 0 ]; then continue; fi

sleep 1

#define another context
exec_AT_comm "AT+CGDCONT=5,\"IP\",\"gprs.startas.lt\""
        if [ $OK -eq 0 ]; then continue; fi

exec_AT_comm "AT+CGACT=1,5"
        if [ $OK -eq 0 ]; then continue; fi

sleep 1

exec_AT_comm "AT+CGDCONT?"
        if [ $OK -eq 0 ]; then continue; fi

        break

done

