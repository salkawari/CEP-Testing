#!/bin/bash

# This is how to call it..
# ./run_3flows.sh tc1_data_setup.sh |tee logs/test_execution_$(date +"%Y-%m-%d-%T").log
# ./run_3flows.sh |tee logs/test_execution_$(date +"%Y-%m-%d-%T").log

echo "now calling $0 ${1} ${2}.."

esp_server_dir=/home/$LOGNAME/Desktop/dev/2.2-pre/bin
data_dir=/opt/app/sas/custom/data
err_dir=/opt/app/sas/custom/data/error_messages

input_dir=input_data

start_stop_dir=start_stop_dir

output_file_name=result.csv

# we set this to be blank to make sure our test sets this value..

rm -fr $(cat start_stop_dir/START_STOP_CONFIG.txt|grep "cep_adapter_log_file"|cut -d'=' -f2)
rm -fr $(cat start_stop_dir/START_STOP_CONFIG.txt|grep "cep_server_log_file"|cut -d'=' -f2)

if (( $# == 1 ))
then
  mylist=$1
else 
  mylist=$(ls |grep "^tc.*_data_setup.sh$")
fi

echo "mylist=$mylist"

#rm -fr $data_dir
my_loc=$(pwd)

echo "cleaning out $data_dir"
rm -fr $data_dir

needed_directories=$(echo "$esp_server_dir $data_dir $err_dir $jar_adapter_path")
needed_directories=$(echo "$needed_directories $input_dir $data_dir/pcrf_files_prepaid $data_dir/pcrf_files_postpaid")
needed_directories=$(echo "$needed_directories $data_dir/lookup_paymenttype $data_dir/lookup_recurring")
needed_directories=$(echo "$needed_directories $data_dir/output_prepaid $data_dir/output_postpaid $data_dir/output_fonic")
needed_directories=$(echo "$needed_directories $data_dir/bad_server_events ${jar_adapter_path} ${my_loc}/${start_stop_dir}")
needed_directories=$(echo "$needed_directories $data_dir/persist_fonic_throttle_event $data_dir/persist_prepaid_throttle_event")
needed_directories=$(echo "$needed_directories $data_dir/persist_postpaid_throttle_event")


for needed_dir in $(echo $needed_directories)
do
  if [ ! -d "$needed_dir" ]
  then
    echo "creating $needed_dir"
    mkdir -p $needed_dir
  fi
done

for i in $(echo $mylist)
do
  test_case_name=$(echo $i|cut -d'_' -f1)
  cd $err_dir
  rm -f *
  cd $data_dir/output_postpaid
  rm -f *
  cd $data_dir/output_prepaid
  rm -f *
  cd $data_dir/output_fonic
  rm -f *

  cd $my_loc  
  echo "############################################################################"
  echo "starting $test_case_name at $(date).."
  ./$i
  export SINGLE_FLOW_TYPE=$(cat SINGLE_FLOW_TYPE.conf)

  out_dir=$data_dir/output_$(echo ${SINGLE_FLOW_TYPE,,} )
  if [ ! -d "$out_dir" ]
  then
    mkdir -p $out_dir;
  fi

  if [ $(ps aux |grep $LOGNAME|egrep "jar|esp" |grep -v egrep|wc -l) -ne 0 ]
  then
    echo "still cep processing running, please kill before starting this test!"
    ps aux |grep $LOGNAME|egrep "jar|esp" |grep -v egrep
    exit
  fi
  ################################################################################
  cd $my_loc/$start_stop_dir
  ./START_CEP_ENGINE.sh
  ./START_CEP_MODEL.sh POSTPAID_THROTTLE_EVENT
  ./START_CEP_MODEL.sh PREPAID_THROTTLE_EVENT
  ./START_CEP_MODEL.sh FONIC_THROTTLE_EVENT
  ./START_CEP_ADAPTER.sh
   cd $my_loc 
  ################################################################################
  sleep 4
  max_count=$(expr 6)
  my_waits=$((0))
  while [ $(ls $out_dir |grep "$output_file_name" | wc -l) -eq 0 ] && [ $my_waits -lt $max_count ]
  do
    echo "waiting for $out_dir/$output_file_name to be created.."
    my_waits=$(($my_waits+1))
    sleep 4    
  done
  if [ $my_waits -ge $max_count ]
  then 
    echo "output file was not created! test failed!!!"
    echo "${test_case_name}: RESULT: FAILED!"
  else


    ################################################################################
    ################################################################################

    echo "${test_case_name}:11. now we can compare results.."
    cat $out_dir/$output_file_name | sed s/'I,N:'/'\n''I,N:'/g > $out_dir/$output_file_name.tmp
    
    if [ $(head -1 $out_dir/$output_file_name.tmp | wc -w) -eq "0" ]
    then
      line_count1=$(wc -l $out_dir/$output_file_name.tmp| awk '{print $1}')
      tail -${line_count1} $out_dir/$output_file_name.tmp > $out_dir/$output_file_name.OUT
    else
      cp $out_dir/$output_file_name.tmp $out_dir/$output_file_name.OUT
    fi
    rm -f $out_dir/$output_file_name.tmp
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
        touch ${my_loc}/EXPECTED_BAD_FILES.conf
        missing_bad_file=n
        for expected_bad_file in $(cat ${my_loc}/EXPECTED_BAD_FILES.conf)
        do
          echo "checking for expected bad file $expected_bad_file in $err_dir.."
          if [ ! -e "${err_dir}/${expected_bad_file}" ]
          then
            echo "ERROR! Missing expected bad file ${err_dir}/${expected_bad_file}"
            missing_bad_file=y
          fi
        done

        if [ $(echo $missing_bad_file |grep n|wc -w) -ne 0 ]
        then
          echo "${test_case_name}: RESULT: GOOD! match on $out_dir/$output_file_name.OUT with  $out_dir/${test_case_name}_result.expected"
        else
          echo "${test_case_name}: RESULT: Failed!! Missing expected bad file ${err_dir}/${expected_bad_file} (good file output match on $out_dir/$output_file_name.OUT with  $out_dir/${test_case_name}_result.expected)"
        fi
      else
        echo "ERROR!!!"
        echo "ERROR!!!"
        echo "${test_case_name}: RESULT: FAILED! BAD! BAD! no match on $out_dir/$output_file_name.OUT with  $out_dir/${test_case_name}_result.expected"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "please fix!!!"
      fi
    else
      echo "RESULT: BAD! missing expected file!!"
    fi

    cd $my_loc/$start_stop_dir
    ./STOP_CEP_MODEL.sh POSTPAID_THROTTLE_EVENT
    ./STOP_CEP_MODEL.sh PREPAID_THROTTLE_EVENT
    ./STOP_CEP_MODEL.sh FONIC_THROTTLE_EVENT
    ./STOP_CEP_ADAPTER.sh
    ./STOP_CEP_ENGINE.sh

  fi

  cd $my_loc
  echo "ending $test_case_name at $(date).."
  echo "############################################################################"
  ################################################################################
  
done

rm -f SINGLE_FLOW_TYPE.conf 




