#!/bin/bash

esp_server_dir=/home/$LOGNAME/Desktop/dev/2.2-pre/bin

jar_adapter_path=/home/$LOGNAME/Desktop/$LOGNAME/try7

my_loc=$(pwd)

if (( $# != 1 ))
then
  echo "please provide a model name (POSTPAID, PREPAID or FONIC)"
  echo "exiting.."
  exit
else  
  if [ $(echo $1 |egrep "^POSTPAID$|^PREPAID$|^FONIC$"|wc -l) -eq 0 ]
  then
    echo "unknown model! Please provide PREPAID, POSTPAID or FONIC (or extend this script!)"
    echo "exiting.."
    exit
  else
    SINGLE_FLOW_TYPE=$1
    model_xml_def_path=$jar_adapter_path/EDR_PCRF_V6.36-${SINGLE_FLOW_TYPE}_client.xml
    model_xml_start_path=$jar_adapter_path/${SINGLE_FLOW_TYPE}_start.xml              
    model_xml_restore_path=$jar_adapter_path/${SINGLE_FLOW_TYPE}_restore.xml          
    #model_xml_persist_path=$jar_adapter_path/${SINGLE_FLOW_TYPE}_persist.xml          

    existing_proc=$(ps aux |grep "dfesp_xml_server" |grep -v grep)
    if [ $(echo "$existing_proc"|wc -w) -eq 0 ]
    then
      echo "Stop!! Server is not running!! please start the seerver first!!!"
      echo "script exiting.. $existing_proc"    
      exit
    else
      echo "starting the cep model $1 at $(date) from $esp_server_dir.."
      cd $esp_server_dir

      echo "starting the xml models dfesp_xml_client for $model_xml_path.."
      ./dfesp_xml_client -server localhost:55556 -file $model_xml_path &
      sleep 1
    
      echo "starting the $model_xml_start.."
      ./dfesp_xml_client -server localhost:55556 -file POSTPAID_start.xml &
    
      echo "sleep 4"
      sleep 4
    
      echo "${test_case_name}: 8. starting the POSTPAID_restore.xml.."
      ./dfesp_xml_client -server localhost:55556 -file POSTPAID_restore.xml &

    fi
  fi
fi
