#!/bin/sh
#4. Parašyti scriptą, kuris prijungtų router'į prie interneto naudojant QMI protokolą
CFG_FILE=modem_info
CFG_PATH=/tmp/
DEVICE_PATH=/sys/bus/usb/devices/

getTTY() {
    IFPATH=$(readlink -f $DEVICE_PATH$1)
    ttyDEV=$(ls $IFPATH | grep "ttyUSB*")
}

getQMI() {
    IFPATH=$(readlink -f $DEVICE_PATH$1)
    qmiDEV=$(ls $IFPATH/usbmisc/ | grep "cdc*")
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

get_devices_qmi() {
    QMIDEVICES=""
    i=0
    while uci -c $CFG_PATH get $CFG_FILE.@qmi[$i] &>/dev/null; do
        CDEVICE=$(uci -c $CFG_PATH get $CFG_FILE.@qmi[$i].device)
        QMIDEVICES="${QMIDEVICES} $CDEVICE"
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

qmi_from_serial() {
    get_devices_qmi
    for NAME in ${QMIDEVICES}; do
        value=${s%%:*}

        case $NAME in
        $value*)
            getQMI ${NAME}
            echo "$qmiDEV"
            return 1
            ;;
        esac

    done
}

configure_uci() {
    if ! uci -q show network.myqmi; then
        uci add network interface
        uci rename network.@interface[-1]='myqmi'
    fi

    uci set network.myqmi.proto='qmi'
    uci set network.myqmi.auth='none'
    uci set network.myqmi.apn='bangapro'
    uci set network.myqmi.device=/dev/${qmiDEV}
    uci set network.myqmi.pdptype='ipv4'
    uci commit
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

    exec_AT_comm "AT+QCFG=\"usbnet\""
    if [ $OK -eq 0 ]; then continue; fi

    #this one seems to be working?
    qmi_from_serial ${NAME}

    status=$(uqmi --device=/dev/${qmiDEV} --get-data-status)
    echo "$status"

    #this is probabably not needed.
    case $status in
    *disconnected*)
        res=$(uqmi --device=/dev/${qmiDEV} --set-device-operating-mode=online)
        ;;
    esac

    configure_uci

    ubus call network restart

    break
done
