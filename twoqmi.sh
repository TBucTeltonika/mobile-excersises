#!/bin/sh
AT_WAIT=2
ttyDEV=ttyUSB3

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

initial_setup() {
    exec_AT_comm "ATE0"
    if [ $OK -eq 0 ]; then return; fi

    exec_AT_comm "AT+CPIN?"
    if [ $OK -eq 0 ]; then return; fi

    exec_AT_comm "AT+CFUN=0"
    if [ $OK -eq 0 ]; then return; fi

    sleep 5

    exec_AT_comm "AT+CFUN=1"
    if [ $OK -eq 0 ]; then return; fi

    exec_AT_comm "AT+QCFG=\"usbnet\",0"
    if [ $OK -eq 0 ]; then return; fi

    exec_AT_comm "AT+QNETDEVSTATUS=1"
    if [ $OK -eq 0 ]; then return; fi

    sleep 30

    (qmicli -d /dev/cdc-wdm0 -E raw-ip)

    (qmicli -d /dev/cdc-wdm0 --dms-set-operating-mode=online)

    sleep 5

    (qmicli -d /dev/cdc-wdm0 --nas-get-serving-system)

    (qmicli -d /dev/cdc-wdm0 -e raw-ip)

    ip link set wwan0 down
    ip link set qmimux0 down
    ip link set qmimux1 down

    #set ip to raw mode
    (echo 1 >/sys/class/net/wwan0/qmi/raw_ip)

    #add qmimux
    (echo 1 >/sys/class/net/wwan0/qmi/add_mux)
    (echo 2 >/sys/class/net/wwan0/qmi/add_mux)

    ip link set qmimux0 mtu 1500
    ip link set qmimux1 mtu 1500
    ip link set wwan0 mtu 4094

    #Get IDS
    WDA=$(qmicli -p -d /dev/cdc-wdm0 --client-no-release-cid --wda-noop)
    WDA=${WDA#*CID: \'}
    WDA=${WDA%%\'*}
    WDS1=$(qmicli -p -d /dev/cdc-wdm0 --client-no-release-cid --wds-noop)
    WDS1=${WDS1#*CID: \'}
    WDS1=${WDS1%%\'*}
    WDS2=$(qmicli -p -d /dev/cdc-wdm0 --client-no-release-cid --wds-noop)
    WDS2=${WDS2#*CID: \'}
    WDS2=${WDS2%%\'*}

    sleep 5
    #Setup data format
    (qmicli -p -d /dev/cdc-wdm0 --wda-set-data-format=""link-layer-protocol=raw-ip,ul-protocol=qmap,dl-protocol=qmap,dl-max-datagrams=32,dl-datagram-max-size=32768,ep-type=hsusb,ep-iface-number=4"" --client-cid=1 --client-no-release-cid)

}
#1-client num, #2-client wds
startqmimux() {
    i=$((1 + $1))
    (qmicli -p -d /dev/cdc-wdm0 --wds-bind-mux-data-port=""mux-id=$i,ep-iface-number=4"" --client-cid="$2" --client-no-release-cid)

    (qmicli -p -d /dev/cdc-wdm0 --wds-start-network="$3" --client-cid="$2" --client-no-release-cid)

    (qmicli -d /dev/cdc-wdm0 --wds-get-packet-service-status)

    ip link set wwan0 up
    ip link set qmimux"$1" up

    ifconfig qmimux"$1" 0.0.0.0
    ifconfig qmimux"$1" down

    #wan setup if needed:
    # config interface wan
    #    option ifname   qmimux0
    #    option proto    dhcp

    ifconfig qmimux"$1" up

    sleep 5
    (udhcpc -f -n -q -t 5 -i qmimux"$1")
}

initial_setup
startqmimux 0 "$WDS1" internet
startqmimux 1 "$WDS2" wap
