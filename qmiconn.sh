#!/bin/sh

AT_WAIT=2
ttyDEV=ttyUSB3
[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. ../netifd-proto.sh
	init_proto "$@"
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

initial_setup() {
    exec_AT_comm "ATE0"
    if [ $OK -eq 0 ]; then exit 1; fi

    exec_AT_comm "AT+CFUN=0"
    if [ $OK -eq 0 ]; then exit 1; fi

    sleep 5

    exec_AT_comm "AT+CFUN=1"
    if [ $OK -eq 0 ]; then exit 1; fi

    exec_AT_comm "AT+CPIN?"
    if [ $OK -eq 0 ]; then exit 1; fi



    exec_AT_comm "AT+QCFG=\"usbnet\",0"
    if [ $OK -eq 0 ]; then exit 1; fi

    exec_AT_comm "AT+QNETDEVSTATUS=1"
    if [ $OK -eq 0 ]; then exit 1; fi

    sleep 30

    (qmicli -d /dev/cdc-wdm0 -E raw-ip)

    (qmicli -d /dev/cdc-wdm0 --dms-set-operating-mode=online)

    sleep 5

    (qmicli -d /dev/cdc-wdm0 --nas-get-serving-system)

    (qmicli -d /dev/cdc-wdm0 -e raw-ip)

    ip link set wwan0 down
    ip link set qmimux$1 down

    #set ip to raw mode
    (echo 1 >/sys/class/net/wwan0/qmi/raw_ip)
    i=$1
    i=$((1 + $i))
    #add qmimux
    (echo $i >/sys/class/net/wwan0/qmi/add_mux)

    ip link set qmimux$1 mtu 1500
    ip link set wwan0 mtu 4094

    #Get IDS
    #could be problematic as this will only succeed once it only needs to be used once though.
    #fix later
    WDA=$(qmicli -p -d /dev/cdc-wdm0 --client-no-release-cid --wda-noop)
    WDA=${WDA#*CID: \'}
    WDA=${WDA%%\'*}

    echo "WDA:$WDA"

    WDS1=$(qmicli -p -d /dev/cdc-wdm0 --client-no-release-cid --wds-noop)
    WDS1=${WDS1#*CID: \'}
    WDS1=${WDS1%%\'*}

    echo "WDS:$WDS1"
    sleep 5
    #Setup data format
    (qmicli -p -d /dev/cdc-wdm0 --wda-set-data-format=""link-layer-protocol=raw-ip,ul-protocol=qmap,dl-protocol=qmap,dl-max-datagrams=32,dl-datagram-max-size=32768,ep-type=hsusb,ep-iface-number=4"" --client-cid=$i --client-no-release-cid)

}

#1-client num, #2-client wds #3-apn
startqmimux() {

    echo "1:$1 2:$2 3:$3"

    i=$((1 + $1))

    (qmicli -p -d /dev/cdc-wdm0 --wds-bind-mux-data-port=""mux-id=$i,ep-iface-number=4"" --client-cid="$2" --client-no-release-cid)


    (qmicli -p -d /dev/cdc-wdm0 --wds-start-network="$3" --client-cid="$2" --client-no-release-cid)

    (qmicli -d /dev/cdc-wdm0 --wds-get-packet-service-status)

    ip link set wwan0 up
    #ip link set qmimux"$1" up

    ifconfig qmimux"$1" 0.0.0.0
    ifconfig qmimux"$1" down

    #wan setup if needed:
    # config interface wan
    #    option ifname   qmimux0
    #    option proto    dhcp

    ifconfig qmimux"$1" up

    sleep 5
    (udhcpc -f -n -q -t 5 -i qmimux$1)
}

proto_qmiconn_init_config() {
	no_device=1
	available=1

    #internet etc. etc.
	proto_config_add_string "apn"
    #0-8
	proto_config_add_int "id"
    #time till live. needed for modems to fully init.
	proto_config_add_int "delay"
}

proto_qmiconn_setup() {
	local interface=$1
	local device=$2

    logger -t "qmiconn" "SETUP CALLED"

    #PROBLEM WITH READING THESE FOR SOME REASON
    #json_load "$(ubus call network.interface.$interface status)"
	#json_select data

	#json_get_var id id
	#json_get_var apn apn
	#json_get_var delay delay
    local id apn delay
    json_get_vars id apn delay

    [ -n "$id" ] || {
		echo "No control id specified"
		proto_set_available "$interface" 0
		return 1
	}

    [ -n "$apn" ] || {
		echo "No control apn specified"
		proto_set_available "$interface" 0
		return 1
	}


	echo "qmiconn_setup($interface), device=$device, apn=$apn id=$id delay=$delay"

    sleep $delay

    initial_setup $id

    startqmimux "$id" "$WDS1" "$apn"

    proto_set_available "$interface" 1
    proto_block_restart "$interface"

    proto_init_update "$ifname" 1
	proto_set_keep 1
}

proto_qmiconn_teardown() {
	return
}

add_protocol qmiconn