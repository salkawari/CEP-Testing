#!/bin/bash
# nohup ./test_case1_v0.1.sh &> logs/test_execution_$(date +"%Y-%m-%d-%T").log &
echo "running test at $(date)"

my_loc=$(pwd)
tc=tc106

echo "FONIC" > SINGLE_FLOW_TYPE.conf
echo "b${tc}_EDR_UPCC231_MPU484_4924_40131211100031.csv" > EXPECTED_BAD_FILES.conf

. ./pcrf_helper.sh
export SINGLE_FLOW_TYPE=$(get_flowtype_lower)
 
throttle_file=${tc}_EDR_UPCC231_MPU484_4924_40131211100031.csv
throttle_input=input_data/$throttle_file

paymenttype_lkp_file=${tc}_input_data_${SINGLE_FLOW_TYPE}_lkp.txt
paymenttype_lkp_input=input_data/${paymenttype_lkp_file}

recurring_lkp_file=${tc}_input_data_recurring_lkp.txt
recurring_lkp_input=input_data/$recurring_lkp_file


data_dir=/opt/app/sas/custom/data

out_dir=$data_dir/output_${SINGLE_FLOW_TYPE}
if [ ! -d "$out_dir" ]
then 
  mkdir -p $out_dir;
fi

expected_output=$out_dir/${tc}_result.expected

if [ $(ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep|wc -l) -ne 0 ]
then
  echo "still cep processing running, please kill before starting this test!"
  ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep
  exit
fi
################################################################################
echo "${tc}:"
./requirement_7.sh
echo " "
echo "test strategy:"
echo "prepare the lookups and put in the correct location (${SINGLE_FLOW_TYPE})"
echo "start CEP"
echo "feed in a good EDR file"
echo "feed in a corrupted EDR file"
echo "feed in a good EDR file"
echo " "
echo ""
################################################################################
echo "${tc}: 1. send PCRF EDRs (input stream).."
rm -f $throttle_input

# here are the variables we are going to work with..
g_TriggerType=
g_Time=
g_msisdn=
g_Quota_Name=
g_Quota_Status=
g_Quota_Usage=
g_Quota_Next_Reset_Time=
g_Quota_Value=
g_PaymentType=
g_InitialVolume=
g_IsRecurring=
g_SGSNAddress=
g_UEIP=
g_Quota_Consumption=

###################
function ret_line() {
local line_type=$1
local line_num=$2

if [ "$line_type" == "PCRF_EDR" ]
then
  if [ "$line_num" == "1" ]
  then
    echo "$g_TriggerType,$g_Time,,,$g_msisdn,,,,,";
  elif [ "$line_num" == "2" ]
  then
    echo ",,,$g_SGSNAddress,,,,,,$g_UEIP";
  elif [ "$line_num" == "3" ]
  then
    echo ",,,,,,$g_Quota_Name,$g_Quota_Status,$g_Quota_Consumption,";
  elif [ "$line_num" == "4" ]
  then
    echo ",$g_Quota_Usage,$g_Quota_Next_Reset_Time,,,,,,,";
  elif [ "$line_num" == "5" ]
  then
    echo ",,,,,,,,,";
  elif [ "$line_num" == "6" ]
  then
    echo ",,,,,,,,,";
  elif [ "$line_num" == "7" ]
  then
    echo ",,,,,,,$g_Quota_Value,,";
  fi
fi
}
###################
# ROW1..a throttle 100 event..
TriggerType1=2;                                                g_TriggerType=$TriggerType1;
Time1=$(date --date='50 hours ago' +"%Y-%m-%d %T");            g_Time=$Time1;
msisdn1=4912345678901;                                         g_msisdn=$msisdn1;
Quota_Name1=Q_110_local_Month;                                 g_Quota_Name=$Quota_Name1;
Quota_Status1=6;                                               g_Quota_Status=$Quota_Status1;
Quota_Usage1=1;                                                g_Quota_Usage=$Quota_Usage1;
Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T");g_Quota_Next_Reset_Time=$Quota_Next_Reset_Time1;
Quota_Value1=1;                                                g_Quota_Value=$Quota_Value1;
PaymentType1=FONIC;                                            g_PaymentType=$PaymentType1;
InitialVolume1=1230;                                           g_InitialVolume=$InitialVolume1;
IsRecurring1=Y;                                                g_IsRecurring=$IsRecurring1;
SGSNAddress1=0;                                                g_SGSNAddress=$SGSNAddress1;
UEIP1=1.2.3.4;                                                 g_UEIP=$UEIP1;
Quota_Consumption1=12                                          g_Quota_Consumption=$Quota_Consumption1;

p1=$(ret_line "PCRF_EDR" "1")
p2=$(ret_line "PCRF_EDR" "2")
p3=$(ret_line "PCRF_EDR" "3")
p4=$(ret_line "PCRF_EDR" "4")
p5=$(ret_line "PCRF_EDR" "5")
p6=$(ret_line "PCRF_EDR" "6")
p7=$(ret_line "PCRF_EDR" "7")

echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
echo ""

echo ""
#######################################################################

################################################################################
echo "${tc}: 2. paymenttype lkp.."
rm -f $paymenttype_lkp_input
echo "$msisdn1,$PaymentType1" >> $paymenttype_lkp_input
cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/
cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/${paymenttype_lkp_file}.done
copy_paymenttypes
echo ""
################################################################################
echo "${tc}: 3. recurring lkp.."
rm -f $recurring_lkp_input
echo "$msisdn1,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input


cp ${recurring_lkp_input} $data_dir/lookup_requirring/OUT
cd $data_dir/lookup_requirring/OUT
zip ${recurring_lkp_file}.zip ./${recurring_lkp_file}
#rm ${recurring_lkp_file}
touch ${recurring_lkp_file}.zip.done
echo "debug ls -rtl $data_dir/lookup_requirring/OUT"
ls -rtl $data_dir/lookup_requirring/OUT
cd $my_loc
################################################################################
echo ""
echo "starting the cep components..."
cd $my_loc/start_stop_dir
./START_CEP_ENGINE.sh
./START_CEP_MODEL.sh POSTPAID_THROTTLE_EVENT
./START_CEP_MODEL.sh PREPAID_THROTTLE_EVENT
./START_CEP_MODEL.sh FONIC_THROTTLE_EVENT
./START_CEP_ADAPTER.sh

cd $my_loc
################################################################################
echo "${tc}: 4. send PCRF EDRs (input stream).."
rm -f input_data/a${throttle_file}

echo "a) feeding in a good EDR file.."

echo "mv $throttle_input input_data/a${throttle_file}"
mv $throttle_input input_data/a${throttle_file}


echo "rm -f input_data/a${throttle_file}.gz"
rm -f input_data/a${throttle_file}.gz

echo "gzip input_data/a${throttle_file}"
gzip input_data/a${throttle_file}

echo "cp input_data/a${throttle_file}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/"
cp input_data/a${throttle_file}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/
echo ""
echo "b) throwing in a bad EDR file.."
echo "gunzip input_data/a${throttle_file}.gz"
gunzip input_data/a${throttle_file}.gz
echo "cp input_data/a${throttle_file} $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/b${throttle_file}.gz"
cp input_data/a${throttle_file} $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/b${throttle_file}.gz
gzip input_data/a${throttle_file}
echo ""
echo "c) feeding in another good EDR file.."
rm -f input_data/c${throttle_file}
msisdn2=4912345678902; g_msisdn=$msisdn2;
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> input_data/c${throttle_file}
rm -f input_data/c${throttle_file}.gz
gzip input_data/c${throttle_file}

echo "cp input_data/c${throttle_file}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/"
cp input_data/c${throttle_file}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/
echo ""
#######################################################################

echo "stopping the cep components..."
cd $my_loc/start_stop_dir
./STOP_CEP_ADAPTER.sh
./STOP_CEP_MODEL.sh POSTPAID_THROTTLE_EVENT
./STOP_CEP_MODEL.sh PREPAID_THROTTLE_EVENT
./STOP_CEP_MODEL.sh FONIC_THROTTLE_EVENT
./STOP_CEP_ENGINE.sh

cd $my_loc
################################################################################
echo "${tc}: 4. generating the expected output.."
rm -f $expected_output

echo "I,N:$Time1,$msisdn1,$SGSNAddress1,$UEIP1,$Quota_Name1,$Quota_Consumption1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,$SGSNAddress1,,,,,,$UEIP1,,,,,,,$Quota_Status1,$Quota_Consumption1,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$Quota_Total1,$IsRecurring1,$InitialVolume1" >> $expected_output

echo "I,N:$Time1,$msisdn2,$SGSNAddress1,$UEIP1,$Quota_Name1,$Quota_Consumption1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,$SGSNAddress1,,,,,,$UEIP1,,,,,,,$Quota_Status1,$Quota_Consumption1,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$Quota_Total1,$IsRecurring1,$InitialVolume1" >> $expected_output


################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "
echo "here is the paymenttype lookup we used.."
cat $my_loc/input_data/$paymenttype_lkp_file
echo " "
echo "here is the recurring lookup we used.."
cat $my_loc/input_data/${tc}_input_data_recurring_lkp.txt
echo " "
echo "here is the EDR stream we used.."
gzip -dc $my_loc/input_data/a${throttle_file}.gz
gzip -dc $my_loc/input_data/c${throttle_file}.gz



