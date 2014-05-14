#! /bin/bash

# This script monitors the memory usage.

cep_memory_log_file=$(cat START_STOP_CONFIG.txt|grep -i "cep_memory_log_file"|cut -d'=' -f2)

if [ $(echo ${cep_memory_log_file}|wc -w) -eq 0 ]
then
  echo "ERROR!! The cep_memory_log_file variable is not defined in the START_STOP_CONFIG.txt!"
  echo "Please correct the cep_memory_log_file entries in the START_STOP_CONFIG.txt."
  echo "exiting without memory logging"
  exit
fi

while ( true ); do

        mypid=$(ps aux|grep -i dfesp_xml_server|grep $LOGNAME|grep -v grep|awk '{print $2}')

        if [ $(echo ${mypid}|wc -w) -eq 0 ]
        then
            echo $(date +'%Y%m%d%H%M%S')': ' >> $cep_memory_log_file
            sleep 60
        else
            echo $(date +'%Y%m%d%H%M%S')': '$(ps -p $mypid -o "pid vsz rss size pmem pcpu comm") | tail -1 >> $cep_memory_log_file
            sleep 60
        fi

done
