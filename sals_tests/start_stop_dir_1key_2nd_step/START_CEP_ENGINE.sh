#!/bin/bash

echo "calling $0 $1 $2"

esp_server_dir=$(cat START_STOP_CONFIG.txt|grep -i "esp_server_dir"|cut -d'=' -f2)
bad_events_dir=$(cat START_STOP_CONFIG.txt|grep -i "bad_events_dir"|cut -d'=' -f2)



bad_events_file=$(cat START_STOP_CONFIG.txt|grep -i "bad_events_file"|cut -d'=' -f2)

cep_server_log_file=$(cat START_STOP_CONFIG.txt|grep -i "cep_server_log_file"|cut -d'=' -f2)



if [ ! -d "${esp_server_dir}" ]

then

  echo "ERROR!! The specified esp server dir doesnt exist (currently esp_server_dir=$esp_server_dir)!"

  echo "Please correct the esp_server_dir entry in the START_STOP_CONFIG.txt."

  echo "exiting script WITHOUT starting the server!!!!"

  exit

fi



if [ ! -d "${bad_events_dir}" ]

then

  echo "ERROR!! The specified bad_events_dir doesnt exist (currently bad_events_dir=$bad_events_dir)!"

  echo "Please correct the bad_events_dir entry in the START_STOP_CONFIG.txt."

  echo "exiting script WITHOUT starting the server!!!!"

  exit

fi



if [ $(echo ${bad_events_file}|wc -w) -eq 0 ]

then

  echo "ERROR!! The bad_events_file variable is not defined in the START_STOP_CONFIG.txt!"

  echo "Please correct the bad_events_file entries in the START_STOP_CONFIG.txt."

  echo "exiting script WITHOUT starting the server!!!!"

  exit

fi



if [ $(echo ${cep_server_log_file}|wc -w) -eq 0 ]

then

  echo "ERROR!! The cep_server_log_file variable is not defined in the START_STOP_CONFIG.txt!"

  echo "Please correct the cep_server_log_file entries in the START_STOP_CONFIG.txt."

  echo "exiting script WITHOUT starting the server!!!!"

  exit

fi



already_running_process=$(ps aux|grep -i dfesp_xml_server| grep -v grep | awk '{print $2}')

if [ $(echo $already_running_process|wc -w) -ne 0 ]

then

  echo "ERROR!! already running CEP Engine server found (process id= $already_running_process!!!)"

  echo "Please stop the CEP Engine server before trying to start it!!"

  echo "exiting script WITHOUT starting the server!!!!"

  exit

fi



my_loc=$(pwd)



echo "cd $esp_server_dir"

cd $esp_server_dir



if [ ! -e "dfesp_xml_server" ]

then

  echo "ERROR!! The dfesp_xml_server script is missing!!!"

  echo "Please install the cep engine directory again!!!"

  echo "exiting script WITHOUT starting the server!!!!"

  exit

fi



echo "starting the cep server at $(date).."

echo "./dfesp_xml_server -pubsub 55555 -server 55556 -loglevel debug -badevents ${bad_events_dir}/${bad_events_file} >> ${cep_server_log_file}"

./dfesp_xml_server -pubsub 55555 -server 55556 -loglevel debug -badevents ${bad_events_dir}/${bad_events_file} &>> ${cep_server_log_file} &

sleep 3

echo "running in the following cep server process.."

ps aux|grep -i dfesp_xml_server| grep -v grep



cd $my_loc







