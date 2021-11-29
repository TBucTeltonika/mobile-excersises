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
set_modem_device() {
        USB_PORT=${line##*] usb } # Remove the left part.
        USB_PORT=${USB_PORT%%:*}  # Remove the right part.

        OUTPUT=$(dmesg | grep -A 1 "$USB_PORT:$USB_CHAN" | tail -1)
        DEV_NAME=${OUTPUT##*now attached to } # Remove the left part.
}

#Sets USB_CHAN if device is known.
set_USB_channel() {
        case $idVendor in
        #TELTTONIKA
        *2c7c*)                
                case $idProduct in
                #TRM240
                *0121*)
                        USB_CHAN="1.3" ;;
                esac
                ;;
        esac
}

get_active_device() {
        D_OUTPUT=$(dmesg | grep 'New USB device found,')
        temp=$IFS

        IFS=$'\n'
        for line in $D_OUTPUT; do
                #echo "$line"
                idVendor=${line##* idVendor=} # Remove the left part.
                idVendor=${idVendor%%,*}      # Remove the right part.
                idProduct=${line##* idProduct=} # Remove the left part.
                idProduct=${idProduct%%,*}      # Remove the right part.

                set_USB_channel
                [ ! -z "$USB_CHAN" ] && set_modem_device
                [ ! -z "$DEV_NAME" ] && break 1
        done

        IFS=$temp
}

set_PPP()
{
    set -x
    uci set network.mobile=interface
    uci set network.mobile.proto='ppp'
    uci set network.mobile.device=${MODEM_DEVICE}
    uci set network.mobile.ipv6='auto'
    { set +x; } 2>/dev/null

}

modem_set_PPP()
{
    set -x
    $(echo AT+CGDATA=\"PPP\",1 | atinout - $MODEM_DEVICE -) &
    PID=$!
    sleep 3
    kill $PID

    { set +x; } 2>/dev/null
}

get_active_device

[ ! -z "$DEV_NAME" ] || (echo "Modem not found"; exit 1)

MODEM_DEVICE="/dev/$DEV_NAME"
MODEM_OUTPUT=$(echo AT | atinout - $MODEM_DEVICE -)
case $MODEM_OUTPUT in
*OK*)
        set_PPP
        modem_set_PPP
        ubus call network restart
        ;;
*)
        echo "Something went wrong!"
        ;;
esac