#!/bin/sh
CFG_FILE=modem_info
CFG_PATH=/tmp/
CFG_FULLPATH="$CFG_PATH$CFG_FILE"
write_to_cfg(){

    echo "config serial" >> $CFG_FULLPATH
    echo -e "\toption device '$1'" >> $CFG_FULLPATH
    echo -e "\toption product '$2'" >> $CFG_FULLPATH
    echo "" >> $CFG_FULLPATH
 
}

remove_from_cfg(){
    i=0
    while uci -c $CFG_PATH get $CFG_FILE.@serial[$i] &>/dev/null
    do
        CFG_DEV=$(uci -c $CFG_PATH get $CFG_FILE.@serial[$i].device)
        CFG_PROD=$(uci -c $CFG_PATH get $CFG_FILE.@serial[$i].product)
        if [ "$CFG_DEV" == "$DEVICENAME" ] && [ "$CFG_PROD" == "$PRODUCT" ]; then
            uci -c $CFG_PATH delete $CFG_FILE.@serial[$i]
            uci -c $CFG_PATH commit
            exit 0
        fi
        i=$((i + 1))
    done
}

update_cfg() {
    case $ACTION in
    bind)
        write_to_cfg $DEVICENAME $PRODUCT
        ;;
    unbind)
        remove_from_cfg $DEVICENAME $PRODUCT
        ;;
    esac
}
case $PRODUCT in
2c7c/125/*)
    case $DEVICENAME in
    *:1.3)
        update_cfg $DEVICENAME
        ;;
    esac
    ;;
2c7c/121/*)
    case $DEVICENAME in
    *:1.3)
        update_cfg $DEVICENAME
        ;;
    esac
    ;;
2c7c/306/*)
    case $DEVICENAME in
    *:1.3)
        update_cfg $DEVICENAME
        ;;
    esac
    ;;
esac