#!/bin/bash

esp_server_dir=/home/$LOGNAME/Desktop/dev/2.2-pre/bin

my_loc=$(pwd)

existing_proc=$(ps aux |grep $LOGNAME|grep "dfesp_xml_server" |grep -v grep)
if [ $(echo "$existing_proc"|wc -w) -ne 0 ]
then
  echo "Stop!! Server is already running!! script exiting.. $existing_proc"    
  exit
else
  echo "starting the cep engine server at $(date) from $esp_server_dir.."
  cd $esp_server_dir
  ./dfesp_xml_server -pubsub 55555 -server 55556 -loglevel &>${my_loc}/server.txt &
  echo " "
  sleep 3
  proc=$(ps aux |grep "dfesp_xml_server" |grep -v grep)
  echo "running server in the following process: $proc"
fi
