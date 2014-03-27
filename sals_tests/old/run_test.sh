#!/bin/bash

# ./run_test.sh tc1_data_setup.sh &> /tmp/bug_ignored_lines.log

esp_server_dir=/home/$LOGNAME/Desktop/dev/2.2-pre/bin
data_dir=/opt/app/sas/custom/data
err_dir=/opt/app/sas/custom/data/error_messages
out_dir=$data_dir/output_postpaid
input_dir=input_data
jar_adapter_path=/home/$LOGNAME/Desktop/$LOGNAME/try6
model_xml_postpaid=$jar_adapter_path/EDR_PCRF_V6.36-POSTPAID.xml
#model_xml_prepaid=$jar_adapter_path/EDR_PCRF_V6.36-PREPAID.xml
output_file_name=result.csv


if (( $# == 1 ))
then
  mylist=$1
else 
  mylist=$(ls |grep "^tc.*_data_setup.sh$")
fi


for i in $(echo $esp_server_dir $data_dir $err_dir $out_dir $jar_adapter_path $input_dir)
do
  if [ ! -d "$i" ]
  then
    echo "please make sure you have setup your data, output, jar adapter directories properly (or update the location used in this script!)."
    echo "it is looking for $i and not finding it"
    echo "exiting the script - please fix and rerun!!!"
    exit;
  fi
done

for i in $(echo "$model_xml_postpaid")
do
  if [ ! -e "$i" ]
  then
    echo "please make sure you have setup your model xml properly (or update the location used in this script!)."
    echo "it is looking for $i and not finding it"
    echo "exiting the script - please fix and rerun!!!"
    exit;
  fi
done

my_loc=$(pwd)

for i in $(echo $mylist)
do
  test_case_name=$(echo $i|cut -d'_' -f1)
  cd $err_dir
  rm -f *
  cd $my_loc  
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
  echo "${test_case_name}: 5. starting the cep engine server .."
  rm -f $out_dir/$output_file_name $out_dir/$output_file_name.tmp $out_dir/$output_file_name.OUT
  cd $esp_server_dir
  ./dfesp_xml_server -pubsub 55555 -server 55556 -loglevel debug -model file:$model_xml_postpaid &>${my_loc}/server.txt &
  #./dfesp_xml_server -pubsub 55555 -server 55556 -loglevel &>${my_loc}/server.txt &
  echo " "
  sleep 4

#  echo "${test_case_name}: 5b. starting the xml models dfesp_xml_client for $model_xml_postpaid.."
#  ./dfesp_xml_client -server localhost:55556 -file $model_xml_postpaid &
#  sleep 1
#  echo "${test_case_name}: 5b. starting the xml models dfesp_xml_client for $model_xml_prepaid.."
#  ./dfesp_xml_client -server localhost:55556 -file $model_xml_prepaid &
#  sleep 1


#  echo "starting the POSTPAID_stuff.xml.."
#  ./dfesp_xml_client -server localhost:55556 -file POSTPAID_stuff.xml &
#  echo "starting the PREPAID_stuff.xml.."
#  ./dfesp_xml_client -server localhost:55556 -file PREPAID_stuff.xml &

  ################################################################################
  echo "${test_case_name}: 6. starting the adapters.."
  cd $jar_adapter_path
  java -jar o2-adapters-pcrf-2.12.2.jar &>${my_loc}/adapter.txt &

  ################################################################################
  sleep 3
  while [ $(ls $out_dir |grep "$output_file_name" | wc -l) -eq 0 ]
  do
    echo "waiting for $out_dir/$output_file_name to be created.."
    sleep 3
  done
  ################################################################################
  ################################################################################

  echo "${test_case_name}:7. now we can compare results.."
  cat $out_dir/$output_file_name | sed s/'I,N:'/'\n''I,N:'/g > $out_dir/$output_file_name.tmp
  
  if [ $(head -1 $out_dir/$output_file_name.tmp | wc -w) -eq "0" ]
  then
    line_count1=$(wc -l $out_dir/$output_file_name.tmp| awk '{print $1}')
    tail -${line_count1} $out_dir/$output_file_name.tmp > $out_dir/$output_file_name.OUT
  else
    cp $out_dir/$output_file_name.tmp $out_dir/$output_file_name.OUT
  fi
  #rm -f $out_dir/$output_file_name.tmp
  if [ $(ls $out_dir |grep "${test_case_name}_result.expected" |wc -l) -ne 0 ]
  then
    echo " "
    echo "here is the contents we were looking for.."
    cat $out_dir/${test_case_name}_result.expected
    echo "here is what we got.."
    cat $out_dir/$output_file_name.OUT
    echo " "
    if [ $(diff -w $out_dir/$output_file_name.OUT $out_dir/${test_case_name}_result.expected |wc -l) -eq 0 ]
    then
      echo "RESULT: GOOD! match on $out_dir/$output_file_name.OUT with  $out_dir/${test_case_name}_result.expected"
    else
      echo "ERROR!!!"
      echo "ERROR!!!"
      echo "RESULT: BAD! BAD! BAD! no match on $out_dir/$output_file_name.OUT with  $out_dir/${test_case_name}_result.expected"
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo "please fix!!!"
#      exit
    fi
  else
    echo "RESULT: BAD! missing expected file!!"
  fi
#  echo " "
#  echo "here is the contents we were looking for.."
#  cat $out_dir/${test_case_name}_result.expected
#  echo "here is what we got.."
#  cat $out_dir/$output_file_name.OUT
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



