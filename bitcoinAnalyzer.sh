#!/bin/bash

# Author: Cesar Lengua (aka rxshs3c)

greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c(){
    echo -e "\n${redColour}[!] EXIT...\n${endColour}"
    rm ut.t* direccion* total_entrada_salida* 2>/dev/null

    tput cnorm; exit 1
}

function helpPanel(){
    echo -e "\n${redColour}[!] Uso: ./btcAnalyzer${endColour}"
    for i in $(seq 1 80); do echo -ne "${redColour}-"; done; echo -ne "${endColour}"
    echo -e "\n\n\t${grayColour}[-e]${endColour}${yellowColour} Modo exploracion${endColour}"
    echo -e "\t\t${purpleColour}transactions${endColour}${yellowColour}:\t\t\t Listar transacciones no confirmadas${endColour}"
    echo -e "\t\t${purpleColour}inspect${endColour}${yellowColour}:\t\t\t Inspeccionar un hash de transaccion${endColour}"
    echo -e "\t\t${purpleColour}address${endColour}${yellowColour}:\t\t\t Inspeccionar una transaccion de direccion ${endColour}"
    echo -e "\n\t${grayColour}[-n]${endColour}${yellowColour} Limitar numero de resultados${endColour}${blueColour}\t\t\t(Ejemplo: -n 10)${endColour}"
    echo -e "\n\t${grayColour}[-i]${endColour}${yellowColour} Proporcionar el identificador de transaccion${endColour}${blueColour}\t(Ejemplo -i dde40023d3a5fc9eebef1064e9f5b07a5eff20ed3eb445897288c0c633119ecf)${endColour}"
  
    echo -e "\n\t${grayColour}[-a]${endColour}${yellowColour} Proporcionar una direccion de transaccion${endColour}${blueColour}\t\t(Ejemplo -a 7bd6db0596dc7c05114a61a05b6a30ecf0441c28df4368ecda56ea6a5ea29260)${endColour}"
    echo -e "\n\t${grayColour}[-h]${endColour}${yellowColour} Mostrar este panel de ayuda${endColour}\n"

    tput cnorm; exit 1

}


# Global variables

unconfirmed_transactions="https://blockchain.info/unconfirmed-transactions?format=json"
inspect_transaction_url="https://blockchain.info/rawtx/"
inspect_address_url="https://blockchain.info/rawaddr/"

function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                #echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
                echo -e "${table}" | column -s '#' -t | awk '/^[[:space:]]*\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}



function transactions(){

    number_output=$1

    echo '' > ut.tmp

    btc_usd_price=$(curl -s "https://blockchain.info/ticker" | jq -r '.USD.last')

    curl -s -H "User-Agent: Mozilla/5.0" "$unconfirmed_transactions" > ut.tmp

    hashes=$(jq -r '.txs[].hash' ut.tmp | head -n $number_output)

    echo "Hash_Cantidad_Bitcoin_Tiempo" > ut.table

    for hash in $hashes; do

        satoshis=$(jq -r ".txs[] | select(.hash==\"$hash\") | [.out[].value] | add" ut.tmp)
        bitcoin=$(awk "BEGIN {printf \"%.8f\", $satoshis/100000000}")

        cantidad=$(awk "BEGIN {printf \"$%.2f\", $bitcoin * $btc_usd_price}")

        unix_time=$(jq -r ".txs[] | select(.hash==\"$hash\") | .time" ut.tmp)
        tiempo=$(date -d @"$unix_time" +"%d/%m/%Y %H:%M:%S")

        echo "${hash}_${cantidad}_${bitcoin} BTC_${tiempo}" >> ut.table

    done

    total_btc=$(cat ut.table | grep -v "Hash" | awk -F'_' '{gsub(/ BTC/, "", $3); sum+=$3} END {printf "%.8f", sum}')
    total_usd=$(awk "BEGIN {printf \"$%.2f\", $total_btc * $btc_usd_price}")
    
    echo -n "Cantidad Total_" > amount.table
    echo "${total_usd}" >> amount.table

    if [ "$(cat ut.table | wc -l)" != "1" ]; then
        echo -ne "${yellowColour}"
        printTable '_' "$(cat ut.table)"
        echo -ne "${endColour}"
        
        echo -ne "${blueColour}"
        printTable '_' "$(cat amount.table)"
        echo -ne "${endColour}"
        
        rm ut.* amount.table 2>/dev/null
        tput cnorm; exit 0
    else
        rm ut.t* 2>/dev/null
    fi

    rm ut.* amount.table 2>/dev/null
    tput cnorm

}

function inspectTransaction(){
    inspect_transaction_hash=$1

    echo "Entrada Total_Salida Total" > total_entrada_salida.tmp

    curl -s "${inspect_transaction_url}${inspect_transaction_hash}" | jq -r '"\([.inputs[0].prev_out.value] | add / 100000000) BTC_\([.out[].value] | add / 100000000) BTC"' >> total_entrada_salida.tmp

    
    echo "Direccion (Entrada)_Valor" > direccion_entrada_value.tmp


    curl -s "${inspect_transaction_url}${inspect_transaction_hash}" | jq -r '.inputs[] | "\(.prev_out.addr)_\(.prev_out.value / 100000000) BTC"' >> direccion_entrada_value.tmp

    echo "Direccion (Salida)_Valor" > direccion_salida_valor.tmp
    curl -s "${inspect_transaction_url}${inspect_transaction_hash}" | jq -r '.out[] | "\(.addr)_\(.value / 100000000 ) BTC"' >> direccion_salida_valor.tmp
    echo -ne "${grayColour}"
    printTable '_' "$(cat total_entrada_salida.tmp)"
    echo -ne "${endColour}"

    echo -ne "${greenColour}"
    printTable '_' "$(cat direccion_entrada_value.tmp)"
    echo -ne "${endColour}"

    echo -ne "${greenColour}"
    printTable '_' "$(cat direccion_salida_valor.tmp)"
    echo -ne "${endColour}"

    rm total_entrada_salida.tmp 2>/dev/null
    rm direccion_entrada_value.tmp 2>/dev/null
    rm direccion_salida_valor.tmp 2>/dev/null
    
    tput cnorm

}

function inspectAdress(){

  address_hash=$1
  echo "Transacciones realizadas_Cantidad total recibida (BTC)_Cantidad total enviada (BTC)_Saldo total en la cuenta (BTC)" > address_information.table
  
  curl -s "${inspect_address_url}${address_hash}" > address.tmp

  total_transactions=$(jq -r '.n_tx' address.tmp)

  satoshis_recibidos=$(jq -r '.total_received' address.tmp)
  cant_total_recibida=$(awk "BEGIN {printf \"%.8f\", $satoshis_recibidos/100000000}")
  satoshis_enviados=$(jq -r '.total_sent' address.tmp)
  cant_total_enviada=$(awk "BEGIN {printf \"%.8f\", $satoshis_enviados/100000000}")
  satoshis_saldo=$(jq -r '.final_balance' address.tmp)
  saldo_total=$(awk "BEGIN {printf \"%.8f\", $satoshis_saldo/100000000}")

  echo "${total_transactions}_${cant_total_recibida}_${cant_total_enviada}_${saldo_total}" >> address_information.table

  echo "Transacciones realizadas_Cantidad total recibida (USD)_Cantidad total enviada (USD)_Saldo total en la cuenta (USD)" > address_information_usd.table

  # --- Conversion a USD ---
  btc_usd_price=$(curl -s "https://blockchain.info/ticker" | jq -r '.USD.last')
  saldo_total_usd=$(awk "BEGIN {printf \"%.2f\", $saldo_total * $btc_usd_price}")
  cant_total_recibida_usd=$(awk "BEGIN {printf \"%.2f\", $cant_total_recibida * $btc_usd_price}")
  cant_total_enviada_usd=$(awk "BEGIN {printf \"%.2f\", $cant_total_enviada * $btc_usd_price}")
  
  echo "${total_transactions}_\$${cant_total_recibida_usd}_\$${cant_total_enviada_usd}_\$${saldo_total_usd}" >> address_information_usd.table


  echo -ne "${blueColour}"
  printTable '_' "$(cat address_information.table)"
  echo -ne "${endColour}"

  echo -ne "${purpleColour}"
  printTable '_' "$(cat address_information_usd.table)"
  echo -ne "${endColour}"

  
  rm address_information.table address.tmp address_information_usd.table 2>/dev/null
  tput cnorm

}

parameter_counter=0; while getopts "e:n:i:a:h:" arg; do
    case $arg in
        e) mode=$OPTARG; let parameter_counter+=1;;
        n) number_output=$OPTARG; let parameter_counter+=1;;
        i) inspect_transaction=$OPTARG; let parameter_counter+=1;;
        a) inspect_address=$OPTARG; let parameter_counter+=1;;
        h) helpPanel;;
  esac
done

tput civis

if [ $parameter_counter -eq 0 ]; then
    helpPanel
else
    if [ "$(echo $mode)" == "transactions" ]; then
        if [ ! "$number_output" ]; then
            number_output=100
            transactions $number_output
        else
            transactions $number_output
        fi
    elif [ "$(echo $mode)" == "inspect" ]; then
        inspectTransaction $inspect_transaction
    elif [ "$(echo $mode)" == "address" ]; then
        inspectAdress $inspect_address
    fi
fi

