#!/bin/sh
#FTP download using AT commands and atinout/socat.
#Requires 00-modem_parser.sh to be setup on the device.
CFG_FILE=modem_info
CFG_PATH=/tmp/
DEVICE_PATH=/sys/bus/usb/devices/
AT_WAIT=2

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
    COMMAND=$1

    OK=0

    AT_OUTPUT=$( (
        echo $COMMAND
        sleep $AT_WAIT
    ) | atinout - /dev/$ttyDEV -)
    echo "$COMMAND"
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

exec_AT_comm_retry() {
    retry=0

    COMMAND=$1
    OK=0

    while [ $retry -le $2 ]; do
        exec_AT_comm $COMMAND
        if [ $OK -eq 0 ];then sleep 5 ; else break; fi        
        retry=$(($retry + 1))
    done
    sleep 1
}

#parse /tmp/modem_info uci config file to get list of DeviceNames like "1.1-3:2-4"
get_devices

for NAME in ${DEVICES}; do
    #convert device name into dev/ttyUSB* aka endpoint.
    getTTY ${NAME}
    echo "$ttyDEV"

    exec_AT_comm "ATE0"
    if [ $OK -eq 0 ]; then
        continue
    fi

    exec_AT_comm "AT"
    if [ $OK -eq 0 ]; then
        continue
    fi

    exec_AT_comm "AT+CPIN?"
    if [ $OK -eq 0 ]; then
        continue
    fi

    exec_AT_comm "AT+CREG?"
    if [ $OK -eq 0 ]; then
        continue
    fi

    exec_AT_comm "AT+QICSGP=1,1,\"internet\",\"\",\"\",1"
    if [ $OK -eq 0 ]; then
        continue
    fi

    sleep 5

    exec_AT_comm "AT+QIACT=1"
    if [ $OK -eq 0 ]; then echo "$ttyDEV did not register. Check if it is already registered..."; fi

    exec_AT_comm "AT+QIACT?"
    if [ $OK -eq 0 ]; then
        continue
    fi

    exec_AT_comm "AT+QFTPCFG=\"contextid\",1"
    if [ $OK -eq 0 ]; then
        continue
    fi

    exec_AT_comm "AT+QFTPCFG=\"transmode\",1"
    if [ $OK -eq 0 ]; then
        continue
    fi

    exec_AT_comm "AT+QFTPCFG=\"account\",\"demo\",\"password\""
    if [ $OK -eq 0 ]; then
        continue
    fi

    exec_AT_comm "AT+QFTPCFG=\"filetype\",1"
    if [ $OK -eq 0 ]; then
        continue
    fi

    exec_AT_comm "AT+QFTPCFG=\"rsptimeout\",90"
    if [ $OK -eq 0 ]; then
        continue
    fi
    exec_AT_comm_retry "AT+QFTPOPEN=\"test.rebex.net\",21" 30

    sleep 5

    exec_AT_comm_retry "AT+QFTPCWD=\"/\"" 20

    exec_AT_comm_retry "AT+IFC=2.2" 20

    #GET THE FILE NOW.

    retry=0
    OK=0
    while [ $retry -le 20 ]; do
        AT_OUTPUT=$( (
            echo "AT+QFTPGET=\"readme.txt\",\"COM:\""
            sleep 10
        ) | socat - /dev/$ttyDEV,raw,crnl)

        case $AT_OUTPUT in
        *CONNECT*)
            OK=1
            ;;
        esac

        if [ $OK -eq 0 ];then sleep 5; else break; fi
        retry=$(($retry + 1))
    done

    #remove "CONNECT prefix which comes first"
    NO_PREFIX=${AT_OUTPUT:9}
    #remove the trailing part. everything after OK and one /n
    RAW_DATA="${NO_PREFIX%?OK*}"
    #Write it to a file.
    echo "$RAW_DATA" >"/tmp/readme.txt"


    exec_AT_comm "AT+QFTPCLOSE"
    if [ $OK -eq 0 ]; then
        continue
    fi

    break
done
