#!/bin/bash

echo "calling $0 $1 $2"

cep_adapter_file=$(cat START_STOP_CONFIG.txt|grep -i "cep_adapter_file"|cut -d'=' -f2)

already_running_process=$(ps aux|grep -i "$cep_adapter_file"| grep -v grep | awk '{print $2}')
if [ $(echo $already_running_process|wc -w) -eq 0 ]
then
  echo "WARNING!!! The CEP adapter is not running anyway!!!"
  echo "exiting script as the CEP adapter has been stopped before running this script!!!!"
  exit
fi

echo "killing ${already_running_process}.."
kill $already_running_process

while [ $(ps aux|grep -i "$cep_adapter_file"| grep -v grep | awk '{print $2}'|wc -w) -ne 0 ]
do
  echo "waiting on the following processes to stop.."
  echo $(ps aux|grep -i "$cep_adapter_file"| grep -v grep | awk '{print $2}')
  sleep 3
done



