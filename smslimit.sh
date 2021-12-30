#!/bin/sh
#Pabandykit į gcont per ubus'ą updatint kiek telpa sms'ų
get_sms_limit() {
    AT_OUTPUT=$(gsmctl -A ""AT+CPMS?"")
    echo "$AT_OUTPUT"
    counter=0
    storage_counter=0
    json_str="{"
    while [ "$AT_OUTPUT" != "$iter" ]; do

        iter=${AT_OUTPUT%%,*}

        AT_OUTPUT="${AT_OUTPUT#$iter,}"

        case $iter in
        *SM*)
            counter=0
            ;;
        *)
            counter=$((counter + 1))
            ;;
        esac

        if [ $counter -eq 2 ]; then
            echo "$iter"
            storage_counter=$((storage_counter + 1))

            json_str="${json_str}\\\"Storage${storage_counter}\\\":${iter},"
        fi
    done
    #delete last comma because its not needed.
    #close the brackets
    json_str=${json_str::-2}
    json_str="${json_str}}"
    echo ${json_str}
}
add_to_gcont(){
    result=$(ubus call gcont delete '{"array":"sms_storage"}')
    echo ${result}
    result=$(ubus call gcont add ''{\"array\":\"sms_storage\",\"json\":\"${json_str}\"}'')
    echo ${result}
}
#makes json_str to be written:
get_sms_limit

#makes ubus call to insert json_str into gcont.
add_to_gcont

#output of "AT+CPMS?":
#'+CPMS: "SM",0,50,"SM",0,50,"SM",0,50

#Working command:
#ubus call gcont add '{"array":"smsse23","json":"{ \"storage1\": 1}"}'