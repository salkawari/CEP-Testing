#!/bin/bash

echo "calling $0 $1 $2"

cep_adapter_dir=$(cat START_STOP_CONFIG.txt|grep -i "cep_adapter_dir"|cut -d'=' -f2)
cep_adapter_file=$(cat START_STOP_CONFIG.txt|grep -i "cep_adapter_file"|cut -d'=' -f2)
cep_adapter_log_file=$(cat START_STOP_CONFIG.txt|grep -i "cep_adapter_log_file"|cut -d'=' -f2)
cep_adapter_params1=$(cat START_STOP_CONFIG.txt|grep -i "cep_adapter_params1"|cut -d'=' -f2)
cep_adapter_params2=$(cat START_STOP_CONFIG.txt|grep -i "cep_adapter_params2"|cut -d'=' -f2)
recurring_lkp_dir=$(cat START_STOP_CONFIG.txt|grep -i "recurring_lkp_dir"|cut -d'=' -f2)


if [ ! -d "${cep_adapter_dir}" ]
then
  echo "ERROR!! The specified cep adapter dir doesnt exist (currently cep_adapter_dir=$cep_adapter_dir)!"
  echo "Please correct the cep_adapter_dir entry in the START_STOP_CONFIG.txt."
  echo "exiting script WITHOUT starting the CEP ADAPTER!!!!"
  exit
fi

if [ ! -e "${cep_adapter_dir}/${cep_adapter_file}" ]
then
  echo "ERROR!! This script expects a cep adapter jar file name"
  echo "Please put on into the cep adapter directory ($cep_adapter_dir)."
  echo "exiting script WITHOUT starting the CEP ADAPTER!!!!"
  exit
fi

if [ $(echo ${cep_adapter_log_file}|wc -w) -eq 0 ]
then
  echo "ERROR!! The cep_adapter_log_file variable is not defined in the START_STOP_CONFIG.txt!"
  echo "Please correct the cep_adapter_log_file entries in the START_STOP_CONFIG.txt."
  echo "exiting script WITHOUT starting the server!!!!"
  exit
fi

if [ ! -d "${recurring_lkp_dir}" ]
then
  echo "ERROR!! The specified recurring_lkp dir doesnt exist (currently recurring_lkp_dir=$recurring_lkp_dir)!"
  echo "Please correct the recurring_lkp_dir entry in the START_STOP_CONFIG.txt."
  echo "exiting script WITHOUT starting the CEP ADAPTER!!!!"
  exit
fi

#####################################
# RECURRING LOOKUP LOGIC....

last_used_recurring_file=; # this is the name of the stale used recurring lookup file..
existing_new_recurring_lkp_flag=n # This flag tells us if there is a new recurring lkp file to be processed..

# now we check to see if the .done folder already exists..
if [ -d "${recurring_lkp_dir}/.done" ]
then
  
  # we check to see if the .done folder has a lkp which could be used
  if [ $(ls -tl "${recurring_lkp_dir}/.done"| grep "^-"|grep -v ".done$" |head -1 |wc -l) -eq 1 ]
  then
    last_used_recurring_file=$(ls -tl "$recurring_lkp_dir/.done"| grep "^-"|grep -v ".done$" |head -1| awk '{print $9}')
  fi

fi



# we check to see if there is a new recurring lkp file which can be used instead of the old stale one!
if [ $(ls -tl $recurring_lkp_dir| grep "^-"|grep -v ".done$" |head -1 |wc -l) -eq 1 ]
then

  existing_new_recurring_lkp_flag=y
fi


if ( [ "$existing_new_recurring_lkp_flag" == "n" ] ) && ( [ $(echo "$last_used_recurring_file" |wc -w) -gt 0 ] ) 
then
  echo "copying stale recurring_lkp file.. cp ${recurring_lkp_dir}/.done/$last_used_recurring_file ${recurring_lkp_dir}"
  cp "${recurring_lkp_dir}/.done/$last_used_recurring_file" "${recurring_lkp_dir}"

  echo "touch ${recurring_lkp_dir}/.done/${last_used_recurring_file}.done"
  touch ${recurring_lkp_dir}/${last_used_recurring_file}.done
elif ( [ "$existing_new_recurring_lkp_flag" == "n" ] ) && ( [ $(echo "$last_used_recurring_file" |wc -w) -eq 0 ] ) 
then
  echo "no new recurring file to process and no stale file to process!!! This should never happen!!! Please copy a new recurring lkp file (and a .done) to the lookup directory!!!"
fi

#####################################

my_loc=$(pwd)

echo "cd $cep_adapter_dir"
cd $cep_adapter_dir

if [ $(ls |grep "xml$"|wc -w) -ne 1 ]
then
  xml_count=$(ls |grep "xml$"|wc -w)
  echo "ERROR!! The CEP adapter needs 1 xml file to be in the directory $cep_adapter_dir (currently $xml_count were found)"
  echo "Please make sure 1 xml file is in this directory."
  echo "exiting script WITHOUT starting the CEP ADAPTER!!!!"
  exit
fi

already_running_process=$(ps aux|grep -i dfesp_xml_server| grep -v grep | awk '{print $2}')
if [ $(echo $already_running_process|wc -w) -eq 0 ]
then
  echo "ERROR!! The CEP Engine server is not yet running!!!"
  echo "Please start the CEP Engine server before trying to start the cep adapter!!"
  echo "exiting script WITHOUT starting the cep adapter!!!!"
  exit
fi


echo "starting the cep adapter.. java $cep_adapter_params1 $cep_adapter_params2 -jar $cep_adapter_file >> ${cep_adapter_log_file}"
java $cep_adapter_params1 $cep_adapter_params2 -jar $cep_adapter_file &>> ${cep_adapter_log_file} &

sleep 1

echo "running in the following cep adapter process.."
ps aux|grep -i "$cep_adapter_file"| grep -v grep


cd $my_loc


