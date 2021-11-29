#!/bin/sh
#1. Parašyti scriptą/programą kuri nustato router'io laiką/datą iš operatoriaus tinklo

##TODO: Move to a seprate file and include it!
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

get_active_device

[ ! -z "$DEV_NAME" ] || (echo "Modem not found"; exit 1)

MODEM_DEVICE="/dev/$DEV_NAME"
MODEM_OUTPUT=$(echo AT | atinout - $MODEM_DEVICE -)
case $MODEM_OUTPUT in
*OK*)
        #echo "Modem is found: $MODEM_DEVICE"
        TIME_OUTPUT=$(echo AT+CCLK? | atinout - $MODEM_DEVICE -)
        set -x
        date --set "20"${TIME_OUTPUT:9:2}"-"${TIME_OUTPUT:12:2}"-"${TIME_OUTPUT:15:2}" "${TIME_OUTPUT:18:8}
        { set +x; } 2>/dev/null
        ;;
*)
        echo "Something went wrong!"
        ;;
esac