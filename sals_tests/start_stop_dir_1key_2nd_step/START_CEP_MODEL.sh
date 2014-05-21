#!/bin/bash

echo "calling $0 $1 $2"
myhost=$(cat START_STOP_CONFIG.txt|grep -i "myhost"|cut -d'=' -f2)
esp_server_dir=$(cat START_STOP_CONFIG.txt|grep -i "esp_server_dir"|cut -d'=' -f2)

if [ ! -d "${esp_server_dir}" ]
then
  echo "ERROR!! The specified esp server dir doesnt exist (currently esp_server_dir=$esp_server_dir)!"
  echo "Please correct the esp_server_dir entry in the START_STOP_CONFIG.txt."
  echo "exiting script WITHOUT starting the CEP MODEL!!!!"
  exit
fi

if (( $# == 1 ))
then
  CEP_MODEL_NAME=$1
else 
  echo "Please provide the CEP MODEL NAME"
  echo "usage: ./START_CEP_MODEL <CEP_MODEL_NAME>"
  echo "for example ./START_CEP_MODEL PREPAID_THROTTLE_EVENT"
  echo "exiting script WITHOUT starting the CEP MODEL!!!!"
  exit
fi

if [ ! -e "${CEP_MODEL_NAME}_load.xml" ]
then
  echo "ERROR!! This script expects a model xml loading file called ${CEP_MODEL_NAME}_load.xml"
  echo "Please create one in this directory."
  echo "exiting script WITHOUT starting the CEP MODEL!!!!"
  exit
fi

if [ ! -e "${CEP_MODEL_NAME}_start.xml" ]
then
  echo "ERROR!! This script expects a model xml loading file called ${CEP_MODEL_NAME}_start.xml"
  echo "Please create one in this directory."
  echo "exiting script WITHOUT starting the CEP MODEL!!!!"
  exit
fi


if [ ! -e "${CEP_MODEL_NAME}_restore.xml" ]
then
  echo "ERROR!! This script expects a model xml loading file called ${CEP_MODEL_NAME}_restore.xml"
  echo "Please create one in this directory."
  echo "exiting script WITHOUT starting the CEP MODEL!!!!"
  exit
fi


already_running_process=$(ps aux|grep -i dfesp_xml_server| grep -v grep | awk '{print $2}')
if [ $(echo $already_running_process|wc -w) -eq 0 ]
then
  echo "ERROR!! The CEP Engine server is not yet running!!!"
  echo "Please start the CEP Engine server before trying to start the cep model!!"
  echo "exiting script WITHOUT starting the cep model!!!!"
  exit
fi

my_loc=$(pwd)

echo "cd $esp_server_dir"
cd $esp_server_dir


if [ ! -e "dfesp_xml_client" ]
then
  echo "ERROR!! The dfesp_xml_client is missing!!!"
  echo "Please install the cep engine directory again!!!"
  echo "exiting script WITHOUT starting the server!!!!"
  exit
fi

echo "1/3) loading the cep model at $(date).."
echo "./dfesp_xml_client -server $myhost:55556 -file ${my_loc}/${CEP_MODEL_NAME}_load.xml"
./dfesp_xml_client -server $myhost:55556 -file ${my_loc}/${CEP_MODEL_NAME}_load.xml &
sleep 1

echo "2/3) starting the cep model.."
echo "./dfesp_xml_client -server $myhost:55556 -file ${my_loc}/${CEP_MODEL_NAME}_start.xml"
./dfesp_xml_client -server $myhost:55556 -file ${my_loc}/${CEP_MODEL_NAME}_start.xml &
echo " "
sleep 1

echo "3/3) restoring an existing binaries for this cep model.."
echo "./dfesp_xml_client -server $myhost:55556 -file ${my_loc}/${CEP_MODEL_NAME}_restore.xml"
./dfesp_xml_client -server $myhost:55556 -file ${my_loc}/${CEP_MODEL_NAME}_restore.xml &
echo " "
sleep 1

cd $my_loc



