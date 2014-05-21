#!/bin/bash

# This is how to call it..
# ./run_2nd_step_tests.sh tc1_data_setup.sh |tee logs/test_execution_$(date +"%Y-%m-%d-%T").log
# ./run_2nd_step_tests.sh |tee logs/test_execution_$(date +"%Y-%m-%d-%T").log

. ./pcrf_helper.sh

# now we take care of soft links..
echo "$(check_espdata)"

echo "now calling $0 ${1} ${2}.."

my_loc=$(pwd)


data_dir=/opt/app/sas/ESPData
error_dir=/opt/app/sas/ESPData/error_messages

input_dir=${my_loc}/input_data



output_file_name=result.csv

if (( $# == 1 ))
then
  mylist=$1
else 
  mylist=$(ls |grep "^tc.*_data_setup.sh$")
fi

echo "mylist=$mylist"

#rm -fr $data_dir





needed_directories=$(echo "$esp_server_dir $data_dir $error_dir $jar_adapter_path")
needed_directories=$(echo "$needed_directories $input_dir $data_dir/pcrf_files_postpaid $data_dir/pcrf_files_prepaid $data_dir/pcrf_files_fonic")
needed_directories=$(echo "$needed_directories $data_dir/lookup_postpaid $data_dir/lookup_paymenttype")
needed_directories=$(echo "$needed_directories $data_dir/lookup_prepaid $data_dir/lookup_fonic $data_dir/lookup_requirring/OUT")
needed_directories=$(echo "$needed_directories $data_dir/output_prepaid $data_dir/output_postpaid $data_dir/output_fonic")
needed_directories=$(echo "$needed_directories $data_dir/bad_events ${jar_adapter_path}")
needed_directories=$(echo "$needed_directories $data_dir/persist_fonic_throttle_event $data_dir/persist_prepaid_throttle_event")
needed_directories=$(echo "$needed_directories $data_dir/persist_postpaid_throttle_event $data_dir/mem-log $data_dir/cep-adapter-log")
needed_directories=$(echo "$needed_directories $data_dir/cep-log $data_dir/campaign-contact-2nd-step $data_dir/pcrf-edr-postpaid-2nd-step")


for i in $(echo $mylist)
do
  test_case_name=$(echo $i|cut -d'_' -f1)

  rm -fr $data_dir
  for needed_dir in $(echo $needed_directories)
  do
    echo "cleaning out $data_dir"

    rm -fr $my_loc/$input_dir
 
   # cd $my_loc
 
    if [ ! -d "$needed_dir" ]
    then
      echo "creating $needed_dir"
      mkdir -p $needed_dir
    fi
  done

  cd $my_loc  
  echo "############################################################################"
  echo "starting $test_case_name at $(date).."
  ./$i
  export SINGLE_FLOW_TYPE=$(get_flowtype_lower)

###############################################################################
if [ -a "$my_loc/MODEL_TYPE.conf" ]
then
  start_stop_dir=start_stop_dir_1key_2nd_step
else
  start_stop_dir=start_stop_dir_1key
fi
echo "start_stop_dir=$start_stop_dir .."

esp_server_dir=$(cat $start_stop_dir/START_STOP_CONFIG.txt|grep "esp_server_dir"|cut -d'=' -f2)

cep_adapter_log_file=$(cat $start_stop_dir/START_STOP_CONFIG.txt|grep "cep_adapter_log_file"|cut -d'=' -f2)


# we set this to be blank to make sure our test sets this value..
rm -fr $(cat $start_stop_dir/START_STOP_CONFIG.txt|grep "cep_adapter_log_file"|cut -d'=' -f2)
rm -fr $(cat $start_stop_dir/START_STOP_CONFIG.txt|grep "cep_server_log_file"|cut -d'=' -f2)

###############################################################################
  out_dir=$data_dir/output_${SINGLE_FLOW_TYPE}
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
  pwd
  ./START_ALL_CEP.sh
   cd $my_loc 
  ################################################################################
  echo "sleeping 4 seconds.."
  sleep 4
  max_count=$(expr 70)
  my_waits=$((0))
  output_matched_flag=n;
  bad_files_expected_flag=n;
  missing_bad_file_flag=n;
  found_bad_file_flag=n;

  # check to see no bad file exists..
  if [ $(ls $error_dir|wc -c) -ne 0 ]
  then
    found_bad_file_flag=y
  fi
    echo "sleeping 20 seconds.."
    sleep 20

    echo "${test_case_name}:11. now we can compare results.."

    if [ -a "$my_loc/MODEL_TYPE.conf" ]
    then
      echo "second step.."
      grep "Input for rtdm 2nd step - only used fields" $cep_adapter_log_file | awk -F'Input for rtdm 2nd step - only used fields: *' '{print $2}'  > $out_dir/$output_file_name.OUT
      rm $my_loc/MODEL_TYPE.conf
    else 
      echo "not second step.."
      grep "Input for rtdm - only fields that are set" $cep_adapter_log_file | awk -F'Input for rtdm - only fields that are set: *' '{print $2}'  > $out_dir/$output_file_name.OUT
    fi

    ## checking that the output files matched the expected files..
    if [ $(diff -w $out_dir/$output_file_name.OUT $out_dir/${test_case_name}_result.expected |wc -l) -eq 0 ]
    then
      output_matched_flag=y;
    fi
    
    ## checking what bad files were expected..
    if [ $(cat ${my_loc}/EXPECTED_BAD_FILES.conf|wc -w) -ne 0 ]
    then
      bad_files_expected_flag=y;

      ## go through the list of expected bad output files to make sure they exist..
      for expected_bad_file in $(cat ${my_loc}/EXPECTED_BAD_FILES.conf)
      do
        echo "checking for expected bad file $expected_bad_file in $error_dir.."
        if [ ! -e "${error_dir}/${expected_bad_file}" ]
        then
          echo "ERROR! Missing expected bad file ${error_dir}/${expected_bad_file}"
          missing_bad_file_flag=y
          all_missing=$(echo "$all_missing $expected_bad_file")
        fi
      done
    fi
    

############
    echo "here is the contents we were looking for.."
    cat $out_dir/${test_case_name}_result.expected
    echo "here is what we got.."
    cat $out_dir/$output_file_name.OUT
    echo ""
# else
#    echo "here is the contents we were looking for, nothing recieved.."
#    cat $out_dir/${test_case_name}_result.expected
#  fi
  ## now we output the result of the test..
  if [ $my_waits -ge $max_count ]
  then 
    echo "output file was not created! test failed!!!"
    echo "${test_case_name}: RESULT: FAILED!"

  elif [ ! -e "$out_dir/${test_case_name}_result.expected" ]
  then
    echo "${test_case_name}: RESULT: FAILED! No expected file found!"

  elif ( [ "$output_matched_flag" == "y" ] ) && ( [ "$bad_files_expected_flag" == "n" ] ) && ( [ "$found_bad_file_flag" == "n" ] )
  then
    echo "${test_case_name}: RESULT: SUCCESS!!! (no bad files expected and none found)"

  elif ( [ "$output_matched_flag" == "y" ] ) && ( [ "$bad_files_expected_flag" == "n" ] ) && ( [ "$found_bad_file_flag" == "y" ] )
  then
    found_bad_files=$(ls $error_dir)
    echo "${test_case_name}: RESULT: FAILURE!!! (no bad files expected but some were found.. $found_bad_files)"

  elif ( [ "$output_matched_flag" == "y" ] ) && ( [ "$bad_files_expected_flag" == "y" ] ) && ( [ "$found_bad_file_flag" == "n" ] )
  then
    found_bad_files=$(ls $error_dir)
    echo "${test_case_name}: RESULT: FAILURE!!! (bad files were expected but none found)"

  elif ( [ "$output_matched_flag" == "y" ] ) && ( [ "$bad_files_expected_flag" == "y" ] ) && ( [ "$missing_bad_file_flag" == "n" ] )
  then
    found_bad_files=$(ls $error_dir)
    echo "${test_case_name}: RESULT: SUCCESS!!! (bad files expected and all found)"

  elif ( [ "$output_matched_flag" == "y" ] ) && ( [ "$bad_files_expected_flag" == "y" ] ) && ( [ "$missing_bad_file_flag" == "y" ] )
  then
    found_bad_files=$(ls $error_dir)
    echo "${test_case_name}: RESULT: FAILURE!!! (bad files expected and not all found.. $all_missing)"
  else
    echo "${test_case_name}: RESULT: FAILURE!!! output doesnt match the input"
  fi

    cd $my_loc/$start_stop_dir
    ./STOP_ALL_CEP.sh
    ################################################################################


  cd $my_loc
  echo "ending $test_case_name at $(date).."
  echo "############################################################################"
  ################################################################################
  
done

rm -f SINGLE_FLOW_TYPE.conf

