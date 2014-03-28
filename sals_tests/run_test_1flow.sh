#!/bin/bash

esp_server_dir=/home/$LOGNAME/Desktop/dev/2.2-pre/bin
data_dir=/opt/app/sas/custom/data
err_dir=/opt/app/sas/custom/data/error_messages

input_dir=input_data
jar_adapter_path=/home/$LOGNAME/Desktop/$LOGNAME/try8


output_file_name=result.csv

# we set this to be blank to make sure our test sets this value..


if (( $# == 1 ))
then
  mylist=$1
else 
  mylist=$(ls |grep "^tc.*_data_setup.sh$")
fi

#rm -fr $data_dir
my_loc=$(pwd)

for i in $(echo "$esp_server_dir $data_dir $err_dir $jar_adapter_path $input_dir $data_dir/pcrf_files_prepaid $data_dir/pcrf_files_postpaid $data_dir/lookup_paymenttype $data_dir/lookup_paymenttype $data_dir/lookup_recurring $data_dir/output_prepaid $data_dir/output_postpaid $data_dir/output_fonic $data_dir/bad_server_events")
do
  if [ ! -d "$i" ]
  then
    echo "creating $i"
    mkdir -p $i
  fi
done

for i in $(echo "$model_xml_path")
do
  if [ ! -e "$i" ]
  then
    echo "please make sure you have setup your model xml properly (or update the location used in this script!)."
    echo "it is looking for $i and not finding it"
    echo "exiting the script - please fix and rerun!!!"
    exit;
  fi
done



for i in $(echo $mylist)
do
  test_case_name=$(echo $i|cut -d'_' -f1)
  cd $err_dir
  rm -f *
  cd $my_loc  
  echo "############################################################################"
  echo "starting $test_case_name at $(date).."
  ./$i
  export SINGLE_FLOW_TYPE=$(cat SINGLE_FLOW_TYPE.conf)
  export model_file_name=$(cat MODEL_XML_NAME.conf)


  out_dir=$data_dir/output_$(echo ${SINGLE_FLOW_TYPE,,} )
  if [ ! -d "$out_dir" ]
  then
    mkdir -p $out_dir;
  fi

  model_xml_def_path=$jar_adapter_path/${model_file_name}
  model_xml_start_path=$jar_adapter_path/${SINGLE_FLOW_TYPE}_start.xml
  model_xml_restore_path=$jar_adapter_path/${SINGLE_FLOW_TYPE}_restore.xml
  model_xml_persist_path=$jar_adapter_path/${SINGLE_FLOW_TYPE}_persist.xml
  missing_a_file=N
  for j in $(echo "$model_xml_def_path $model_xml_start_path $model_xml_restore_path $model_xml_persist_path")
  do
    if [ ! -e "$j" ]
    then
      echo "ERROR!!! Missing input xml configuration $j!!!! Please copy over and then rerun test!!!!"
      missing_a_file=Y
    fi
  done
  if [ "$missing_a_file" == "Y" ]
  then
    echo "exiting as missing atleast 1 xml config file!"
    exit
  fi

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
  echo "starting with the following command ... ./dfesp_xml_server -pubsub 55555 -server 55556 -loglevel debug -badevents $data_dir/bad_server_events >${my_loc}/server.txt"
  ./dfesp_xml_server -pubsub 55555 -server 55556 -loglevel debug -badevents $data_dir/bad_server_events/error.txt &>${my_loc}/server.txt &
  echo " "
  sleep 4
  ################################################################################

  echo "${test_case_name}: 6 a). loading the xml model via $model_xml_def_path.."
  echo "./dfesp_xml_client -server localhost:55556 -file $model_xml_def_path.."
  ./dfesp_xml_client -server localhost:55556 -file $model_xml_def_path &
  echo " "
  sleep 1

  echo "${test_case_name}: 6 b). starting xml model via $model_xml_start_path.."
  echo "./dfesp_xml_client -server localhost:55556 -file $model_xml_start_path"
  ./dfesp_xml_client -server localhost:55556 -file $model_xml_start_path &
  echo " "
  sleep 4

  echo "${test_case_name}: 6 c). restoring via $model_xml_restore_path.."
  echo "./dfesp_xml_client -server localhost:55556 -file $model_xml_restore_path"
  ./dfesp_xml_client -server localhost:55556 -file $model_xml_restore_path &> ${my_loc}/response_restore_${SINGLE_FLOW_TYPE}.out
  echo " "

##################################################################################
if [ $(echo $SINGLE_FLOW_TYPE| grep "PREPAID" |wc -l) -eq 1 ]
then
  echo "note we are using the new xml... $model_xml_def_path"
  PREPAID_LOAD=$model_xml_def_path
else
  PREPAID_LOAD=/home/nicopc/Desktop/nicopc/try8/EDR_PCRF_V6.36-PREPAID_load.xml
fi

PREPAID_START=/home/nicopc/Desktop/nicopc/try8/PREPAID_start.xml
PREPAID_RESTORE=/home/nicopc/Desktop/nicopc/try8/PREPAID_restore.xml
PREPAID_PERSIST=/home/nicopc/Desktop/nicopc/try8/PREPAID_persist.xml
for i in $(echo "$PREPAID_LOAD $PREPAID_START $PREPAID_RESTORE $PREPAID_PERSIST")
do
  if [ ! -e "$i" ]
  then
    echo "missing $i!!! exiting!!!"
    exit
  fi
done

  echo "${test_case_name}: PREPAID 7 a). loading the xml model via $PREPAID_LOAD.."
  echo "./dfesp_xml_client -server localhost:55556 -file $PREPAID_LOAD.."
  ./dfesp_xml_client -server localhost:55556 -file $PREPAID_LOAD &
  echo " "
  sleep 1
  


  echo "${test_case_name}: PREPAID 7 b). starting xml model via $PREPAID_START.."
  echo "./dfesp_xml_client -server localhost:55556 -file $PREPAID_START.."
  ./dfesp_xml_client -server localhost:55556 -file $PREPAID_START &
  echo " "
  sleep 2

  echo "${test_case_name}: PREPAID 7 c). restoring xml model via $PREPAID_RESTORE.."
  echo "./dfesp_xml_client -server localhost:55556 -file $PREPAID_RESTORE.."
  ./dfesp_xml_client -server localhost:55556 -file $PREPAID_RESTORE &
  echo " "
  sleep 1
##################################################################################
if [ $(echo $SINGLE_FLOW_TYPE| grep "POSTPAID" |wc -l) -eq 1 ]
then
  echo "note we are using the new xml... $model_xml_def_path"
  POSTPAID_LOAD=$model_xml_def_path
else
  POSTPAID_LOAD=/home/nicopc/Desktop/nicopc/try8/EDR_PCRF_V6.36-POSTPAID_load.xml
fi

POSTPAID_START=/home/nicopc/Desktop/nicopc/try8/POSTPAID_start.xml
POSTPAID_RESTORE=/home/nicopc/Desktop/nicopc/try8/POSTPAID_restore.xml
POSTPAID_PERSIST=/home/nicopc/Desktop/nicopc/try8/POSTPAID_persist.xml
for i in $(echo "$POSTPAID_LOAD $POSTPAID_START $POSTPAID_RESTORE $POSTPAID_PERSIST")
do
  if [ ! -e "$i" ]
  then
    echo "missing $i!!! exiting!!!"
    exit
  fi
done

  echo "${test_case_name}: POSTPAID 8 a). loading the xml model via $POSTPAID_LOAD.."
  echo "./dfesp_xml_client -server localhost:55556 -file $POSTPAID_LOAD.."
  ./dfesp_xml_client -server localhost:55556 -file $POSTPAID_LOAD &
  echo " "
  sleep 1
  


  echo "${test_case_name}: POSTPAID 8 b). starting xml model via $POSTPAID_START.."
  echo "./dfesp_xml_client -server localhost:55556 -file $POSTPAID_START.."
  ./dfesp_xml_client -server localhost:55556 -file $POSTPAID_START &
  echo " "
  sleep 2

  echo "${test_case_name}: POSTPAID 8 c). restoring xml model via $POSTPAID_RESTORE.."
  echo "./dfesp_xml_client -server localhost:55556 -file $POSTPAID_RESTORE.."
  ./dfesp_xml_client -server localhost:55556 -file $POSTPAID_RESTORE &
  echo " "
  sleep 1
##################################################################################
if [ $(echo $SINGLE_FLOW_TYPE| grep "FONIC" |wc -l) -eq 1 ]
then
  echo "note we are using the new xml... $model_xml_def_path"
  FONIC_LOAD=$model_xml_def_path
else
  FONIC_LOAD=/home/nicopc/Desktop/nicopc/try8/EDR_PCRF_V6.36-FONIC_load.xml
fi


FONIC_START=/home/nicopc/Desktop/nicopc/try8/FONIC_start.xml
FONIC_RESTORE=/home/nicopc/Desktop/nicopc/try8/FONIC_restore.xml
FONIC_PERSIST=/home/nicopc/Desktop/nicopc/try8/FONIC_persist.xml
for i in $(echo "$FONIC_LOAD $FONIC_START $FONIC_RESTORE $FONIC_PERSIST")
do
  if [ ! -e "$i" ]
  then
    echo "missing $i!!! exiting!!!"
    exit
  fi
done

  echo "${test_case_name}: FONIC 9 a). loading the xml model via $FONIC_LOAD.."
  echo "./dfesp_xml_client -server localhost:55556 -file $FONIC_LOAD.."
  ./dfesp_xml_client -server localhost:55556 -file $FONIC_LOAD &
  echo " "
  sleep 1
  
  echo "${test_case_name}: FONIC 9 b). starting xml model via $FONIC_START.."
  echo "./dfesp_xml_client -server localhost:55556 -file $FONIC_START.."
  ./dfesp_xml_client -server localhost:55556 -file $FONIC_START &
  echo " "
  sleep 2

  echo "${test_case_name}: FONIC 9 c). restoring xml model via $FONIC_RESTORE.."
  echo "./dfesp_xml_client -server localhost:55556 -file $FONIC_RESTORE.."
  ./dfesp_xml_client -server localhost:55556 -file $FONIC_RESTORE &
  echo " "
  sleep 1

##################################################################################
#
#  echo "${test_case_name}: 8. restoring via $model_xml_restore_path.."
#  echo "./dfesp_xml_client -server localhost:55556 -file $model_xml_restore_path"
#  ./dfesp_xml_client -server localhost:55556 -file $model_xml_restore_path &> ${my_loc}/response_restore_${SINGLE_FLOW_TYPE}.out
#  echo " "
#
#  ################################################################################
  echo "${test_case_name}: 10. starting the adapters.."
  cd $jar_adapter_path
  java -jar o2-adapters-pcrf-2.12.2.jar &>${my_loc}/adapter.txt &

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
        echo "${test_case_name}: RESULT: GOOD! match on $out_dir/$output_file_name.OUT with  $out_dir/${test_case_name}_result.expected"
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

    echo " "
    echo "###########################################################################"
    echo "${test_case_name}: 12 PREPAID a). persisting via $model_xml_persist_path.."
    cd $esp_server_dir  
    echo "./dfesp_xml_client -server localhost:55556 -file $model_xml_persist_path"
    ./dfesp_xml_client -server localhost:55556 -file $model_xml_persist_path &> ${my_loc}/response_persist_${SINGLE_FLOW_TYPE}.out
    echo " "
    echo "${test_case_name}: 12 POSTPAID b). persisting xml model via $POSTPAID_PERSIST.."
    echo "./dfesp_xml_client -server localhost:55556 -file $POSTPAID_PERSIST.."
    ./dfesp_xml_client -server localhost:55556 -file $POSTPAID_PERSIST &
    echo " "
    echo "${test_case_name}: 12 FONIC c). persist xml model via $FONIC_PERSIST.."
    echo "./dfesp_xml_client -server localhost:55556 -file $FONIC_PERSIST.."
    ./dfesp_xml_client -server localhost:55556 -file $FONIC_PERSIST &
    echo " "
    sleep 1

  fi
    cd $my_loc
    ################################################################################
    echo "13. checking for processes to kill.."
    for j in $(ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar" |grep -v egrep| awk '{print $2}')
    do
      echo "killing adapter $j"
      kill $j
    done
    sleep 4

    for j in $(ps aux|grep $LOGNAME|grep -v grep|egrep "dfesp_xml_server|jar|esp" | awk '{print $2}')
    do
      echo "killing -9 $j";
      kill $j;
    done
    sleep 10
  cd $my_loc
  echo "ending $test_case_name at $(date).."
  echo "############################################################################"
  ################################################################################
  
done

rm -f SINGLE_FLOW_TYPE.conf  ${my_loc}/response_restore_${SINGLE_FLOW_TYPE}.out ${my_loc}/response_restore_${SINGLE_FLOW_TYPE}.out
#export SINGLE_FLOW_TYPE=$(echo "")



