#!/bin/bash

# nohup ./run_test.sh &> logs/test_execution_$(date +"%Y-%m-%d-%T").log &

esp_server_dir=/home/sal/Desktop/dev/2.2-pre/bin
data_dir=/opt/app/sas/custom/data
out_dir=$data_dir/output
jar_adapter_path=/home/sal/Desktop/sal/try5
model_xml=$jar_adapter_path/EDR_PCRF_V6.35-sjk-NewFormat3.xml

for i in $(echo $esp_server_dir $data_dir $out_dir $jar_adapter_path)
do
  if [ ! -d "$i" ]
  then
    echo "please make sure you have setup your data, output, jar adapter directories properly (or update the location used in this script!)."
    echo "it is looking for $i and not finding it"
    echo "exiting the script - please fix and rerun!!!"
    exit;
  fi
done

  if [ ! -e "$model_xml" ]
  then
    echo "please make sure you have setup your model xml properly (or update the location used in this script!)."
    echo "it is looking for $model_xml and not finding it"
    echo "exiting the script - please fix and rerun!!!"
    exit;
  fi

my_loc=$(pwd)

for i in $(ls |grep "^tc.*_data_setup.sh$")
do
  test_case_name=$(echo $i|cut -d'_' -f1)
  echo "############################################################################"
  echo "starting $test_case_name at $(date).."
  ./$i
  if [ $(ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep|wc -l) -ne 0 ]
  then
    echo "still cep processing running, please kill before starting this test!"
    ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep
    exit
  fi
  ################################################################################
  echo "${test_case_name}: 5. starting the cep engine server with model=$model_xml.."
  rm -f $out_dir/ADD_REQUIRRING.result.csv $out_dir/ADD_REQUIRRING.result.tmp $out_dir/ADD_REQUIRRING.result.OUT
  cd $esp_server_dir
  ./dfesp_xml_server -pubsub 55555 -server 55556 -loglevel debug -model file:$model_xml &>${my_loc}/server.txt &
  echo " "
  ################################################################################
  echo "${test_case_name}: 6. starting the adapters.."
  cd $jar_adapter_path
  java -jar o2-adapters-pcrf-2.12.2.jar &>${my_loc}/adapter.txt &

  ################################################################################
  sleep 3
  while [ $(ls $out_dir |grep "ADD_REQUIRRING.result.csv" | wc -l) -eq 0 ]
  do
    echo "waiting for $out_dir/ADD_REQUIRRING.result.csv to be created.."
    sleep 3
  done
  ################################################################################
  ################################################################################

  echo "${test_case_name}:7. now we can compare results.."
  cat $out_dir/ADD_REQUIRRING.result.csv | sed s/'I,N:'/'\n''I,N:'/g > $out_dir/ADD_REQUIRRING.result.tmp
  
  line_count1=$(wc -l $out_dir/ADD_REQUIRRING.result.tmp| awk '{print $1}')
  tail -${line_count1} $out_dir/ADD_REQUIRRING.result.tmp > $out_dir/ADD_REQUIRRING.result.OUT

  rm -f $out_dir/ADD_REQUIRRING.result.tmp
  if [ $(ls $out_dir |grep "${test_case_name}_ADD_REQUIRRING.expected" |wc -l) -ne 0 ]
  then
    if [ $(diff -w $out_dir/ADD_REQUIRRING.result.OUT $out_dir/${test_case_name}_ADD_REQUIRRING.expected |wc -l) -eq 0 ]
    then
      echo "RESULT: GOOD! match on ADD_REQUIRRING"
    else
      echo "RESULT: BAD! no match on ADD_REQUIRRING!!"
    fi
  else
    echo "RESULT: BAD! missing expected file!!"
  fi
  echo " "
  echo "here is the contents we were looking for.."
  cat $out_dir/${test_case_name}_ADD_REQUIRRING.expected
  echo "here is the EDR stream we used.."
  cat $out_dir/ADD_REQUIRRING.result.OUT
  echo " "
  ################################################################################
  echo "8. checking for processes to kill.."
  for j in $(ps -ef|grep $LOGNAME|grep -v grep|egrep "jar|esp" | awk '{print $2}')
  do
    echo "killing $j";
    kill $j;
  done
  sleep 2
  cd $my_loc
  echo "ending $test_case_name at $(date).."
  echo "############################################################################"
  ################################################################################
done



