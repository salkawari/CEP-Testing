#!/bin/bash

echo "running test at $(date)"

my_loc=$(pwd)
 
echo "POSTPAID" > SINGLE_FLOW_TYPE.conf
#echo "EDR_PCRF_V6.36-POSTPAID_load.xml" > MODEL_XML_NAME.conf
echo "" > EXPECTED_BAD_FILES.conf


throttle_file=tc8_EDR_UPCC231_MPU484_4924_40131211100031.csv
throttle_dir=input_data
throttle_input=$throttle_dir/$throttle_file

postpaid_lkp_file=tc8_input_data_postpaid_lkp.txt
postpaid_lkp_input=input_data/$postpaid_lkp_file

recurring_lkp_file=tc8_input_data_recurring_lkp.txt
recurring_lkp_input=input_data/$recurring_lkp_file

data_dir=/opt/app/sas/custom/data

out_dir=$data_dir/output_postpaid
if [ ! -d "$out_dir" ]
then 
  mkdir -p $out_dir;
fi

expected_output=$out_dir/tc8_result.expected

if [ $(ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep|wc -l) -ne 0 ]
then
  echo "still cep processing running, please kill before starting this test!"
  ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep
  exit
fi
################################################################################
################################################################################
echo "tc8:"
./requirement_8.sh
echo " "
echo "test strategy:"
echo "we add a text file instead of a gzip file, then we add a valid file"
echo " "
echo " "
echo "EDR data setup:"
echo "file 1: "
echo "msisdn1 throttle100 event"
echo "msisdn2 throttle100 event"
echo "msisdn3 throttle100 event"
echo ""
echo "Recurring Lookup"
echo "isRecurring=Y for all"
echo ""
echo "Payment Type Lookup:"
echo "msisdn1 postpaid"
echo "msisdn2 postpaid"
echo "msisdn3 postpaid"
echo ""
echo "start cep"
echo "all 3 throttle 100 postpaid reach the output"
echo ""
echo ""
echo "load a new Payment Type Lookup:"
echo "msisdn1 postpaid"
echo "msisdn2 prepaid"
echo "msisdn3 fonic"
echo ""
echo "only msisdn2 should reach the output"
echo ""
echo "Payment Type Lookup:"
echo "msisdn1 postpaid"
echo "msisdn2 postpaid"
echo "msisdn3 postpaid"
echo ""
echo "Recurring Lookup"
echo "isRecurring=N for all"
echo ""
echo ""
################################################################################
################################################################################


rm -f $throttle_input
touch $throttle_input
###################
# Row1: A valid postpaid throttle event 1 hour ago.
# P1 - TriggerType, Time, MSISDN..
p1_desc=$(echo "# TriggerType, Time,,,MSISDN,,,,,")
TriggerType1=2; Time1=$(date --date='2 hours ago' +"%Y-%m-%d %T"); msisdn1=4912345678901; Quota_Name1=Q_110_local_Month; Quota_Status1=6; 
Quota_Usage1=1; Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T"); Quota_Value1=1; PaymentType1=POSTPAID;
InitialVolume1=1230; IsRecurring1=Y;
p1=$(echo "$TriggerType1,$Time1,,,$msisdn1,,,,,")

# P2 - nothing of interest here..
p2_desc=$(echo "# CGI,SAI,RAI,SGSNAddress,MCC_MNC,Roam_Status,Roam_Region,AccessType,IPCan_Type,UEIP")
p2=$(echo ",,,,,,,,,")

# P3 - Quota_Name, Quota_Status..
p3_desc=$(echo "APN,Download_Bandwidth,Upload_Bandwidth,Service_Package_Name,Service_Name,Rule_Name,Quota_Name,Quota_Status,Quota_Consumption,Quota_Balance")
p3=$(echo ",,,,,,$Quota_Name1,$Quota_Status1,,")

# P4 - Quota_Usage,Quota_Next_Reset_Time
p4_desc=$(echo "Quota_Recharge,Quota_Usage,Quota_Next_Reset_Time,Account_Name,Account_Status,Account_Privilege,Personal_Value,Account_Balance,Account_Consumption,Account_Usage")
date_16days=$(date --date='16 days' +"%Y-%m-%d %T")
p4=$(echo ",$Quota_Usage1,$Quota_Next_Reset_Time1,,,,,,,")

# P5 - nothing..
p5=$(echo ",,,,,,,,,")

# P6 - nothing..
p6=$(echo ",,,,,,,,,")

# P7 - Quota_Value..
p7=$(echo ",,,,,,,$Quota_Value1,,")

echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW2..
msisdn2=4912345678902;
p1=$(echo "$TriggerType1,$Time1,,,$msisdn2,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW3..
msisdn3=4912345678903;
p1=$(echo "$TriggerType1,$Time1,,,$msisdn3,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
###################
rm -f ${throttle_input}.gz
gzip $throttle_input
cp ${throttle_input}.gz $data_dir/pcrf_files_postpaid/${throttle_file}.gz


################################################################################
echo "tc8: 2. postpaid lkp.."
rm -f $postpaid_lkp_input
echo "$msisdn1,$PaymentType1" >> $postpaid_lkp_input
echo "$msisdn2,$PaymentType1" >> $postpaid_lkp_input
echo "$msisdn3,$PaymentType1" >> $postpaid_lkp_input
cp $postpaid_lkp_input $data_dir/lookup_paymenttype/
cp $postpaid_lkp_input $data_dir/lookup_paymenttype/${postpaid_lkp_file}.done

################################################################################
echo "tc8: 3. recurring lkp.."
rm -f $recurring_lkp_input

echo "$msisdn1,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn2,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn3,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
cp $recurring_lkp_input $data_dir/lookup_recurring/
cp $recurring_lkp_input $data_dir/lookup_recurring/${recurring_lkp_file}.done

################################################################################
echo "part1.."
echo "here is the postpaid lookup we used.."
cat $data_dir/lookup_paymenttype/tc8_input_data_postpaid_lkp.txt
echo " "
echo "here is the recurring lookup we used.."
cat $data_dir/lookup_recurring/tc8_input_data_recurring_lkp.txt
echo " "
echo "here is the EDR stream we used.. (this is the valid file)"
gzip -dc $data_dir/pcrf_files_postpaid/${throttle_file}.gz

my_loc2=$(pwd)

rm -f $expected_output
echo "I,N:$Time1,$msisdn1,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status1,,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$(($Quota_Usage1)),$IsRecurring1,$InitialVolume1" >> $expected_output
echo "I,N:$Time1,$msisdn2,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status1,,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$(($Quota_Usage1)),$IsRecurring1,$InitialVolume1" >> $expected_output
echo "I,N:$Time1,$msisdn3,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status1,,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$(($Quota_Usage1)),$IsRecurring1,$InitialVolume1" >> $expected_output

echo "starting the cep components..."
cd $my_loc/start_stop_dir
./START_CEP_ENGINE.sh
./START_CEP_MODEL.sh POSTPAID_THROTTLE_EVENT
./START_CEP_MODEL.sh PREPAID_THROTTLE_EVENT
./START_CEP_MODEL.sh FONIC_THROTTLE_EVENT
./START_CEP_ADAPTER.sh
cd $my_loc2

echo ""
echo "####################################################"
echo "part2.."
echo "now we change the lookups so that msisdn2 is prepaid and msisdn3 is fonic"
rm -f $postpaid_lkp_input
echo "$msisdn1,$PaymentType1" >> $postpaid_lkp_input
echo "$msisdn2,PREPAID" >> $postpaid_lkp_input
echo "$msisdn3,FONIC" >> $postpaid_lkp_input
cp $postpaid_lkp_input $data_dir/lookup_paymenttype/
cp $postpaid_lkp_input $data_dir/lookup_paymenttype/${postpaid_lkp_file}.done
#############################
echo ""
echo "here is the 2nd file we send off.."
rm -fr ${throttle_dir}/2${throttle_file}
# ROW1..
msisdn1=4912345678901; Time1=$(date --date='50 minutes ago' +"%Y-%m-%d %T")
p1=$(echo "$TriggerType1,$Time1,,,$msisdn1,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> ${throttle_dir}/2${throttle_file}
####
# ROW2..
msisdn2=4912345678902;
p1=$(echo "$TriggerType1,$Time1,,,$msisdn2,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> ${throttle_dir}/2${throttle_file}
####
# ROW3..
msisdn3=4912345678903;
p1=$(echo "$TriggerType1,$Time1,,,$msisdn3,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> ${throttle_dir}/2${throttle_file}
###################
rm -f ${throttle_dir}/2${throttle_file}.gz
gzip ${throttle_dir}/2${throttle_file}
cp ${throttle_dir}/2${throttle_file}.gz $data_dir/pcrf_files_postpaid/2${throttle_file}.gz


echo "here is the postpaid lookup we used.."
cat $data_dir/lookup_paymenttype/tc8_input_data_postpaid_lkp.txt
echo " "
echo "here is the recurring lookup we used.."
cat $data_dir/lookup_recurring/tc8_input_data_recurring_lkp.txt
echo " "
echo "here is the EDR stream we used.. (this is the valid file)"
gzip -dc $data_dir/pcrf_files_postpaid/2${throttle_file}.gz

# we add the next set of results we expect
echo "I,N:$Time1,$msisdn1,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status1,,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$(($Quota_Usage1)),$IsRecurring1,$InitialVolume1" >> $expected_output

echo ""
echo "####################################################"

echo ""
echo "####################################################"
echo "part3.."
echo "now we change the lookups so that all are postpaid and isRecurring=N"
rm -f $postpaid_lkp_input
echo "$msisdn1,$PaymentType1" >> $postpaid_lkp_input
echo "$msisdn2,$PaymentType1" >> $postpaid_lkp_input
echo "$msisdn3,$PaymentType1" >> $postpaid_lkp_input
cp $postpaid_lkp_input $data_dir/lookup_paymenttype/
cp $postpaid_lkp_input $data_dir/lookup_paymenttype/${postpaid_lkp_file}.done

rm -f  $recurring_lkp_input
InitialVolume2=5; IsRecurring2=Y
echo "$msisdn1,$Quota_Name1,$InitialVolume2,$IsRecurring2" >> $recurring_lkp_input
echo "$msisdn2,$Quota_Name1,$InitialVolume2,$IsRecurring2" >> $recurring_lkp_input
echo "$msisdn3,$Quota_Name1,$InitialVolume2,$IsRecurring2" >> $recurring_lkp_input
cp $recurring_lkp_input $data_dir/lookup_recurring/
cp $recurring_lkp_input $data_dir/lookup_recurring/${recurring_lkp_file}.done
#############################
echo ""
echo "here is the 3rd file we send off.."
rm -fr ${throttle_dir}/3${throttle_file}
# ROW1..
msisdn1=4912345678901; Time1=$(date --date='40 minutes ago' +"%Y-%m-%d %T")
p1=$(echo "$TriggerType1,$Time1,,,$msisdn1,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> ${throttle_dir}/3${throttle_file}
####
# ROW2..
msisdn2=4912345678902;
p1=$(echo "$TriggerType1,$Time1,,,$msisdn2,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> ${throttle_dir}/3${throttle_file}
####
# ROW3..
msisdn3=4912345678903;
p1=$(echo "$TriggerType1,$Time1,,,$msisdn3,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> ${throttle_dir}/3${throttle_file}
###################
rm -f ${throttle_dir}/3${throttle_file}.gz
gzip ${throttle_dir}/3${throttle_file}
cp ${throttle_dir}/3${throttle_file}.gz $data_dir/pcrf_files_postpaid/3${throttle_file}.gz


echo "here is the postpaid lookup we used.."
cat $data_dir/lookup_paymenttype/tc8_input_data_postpaid_lkp.txt
echo " "
echo "here is the recurring lookup we used.."
cat $data_dir/lookup_recurring/tc8_input_data_recurring_lkp.txt
echo " "
echo "here is the EDR stream we used.. (this is the valid file)"
gzip -dc $data_dir/pcrf_files_postpaid/3${throttle_file}.gz

# we add the next set of results we expect
echo "I,N:$Time1,$msisdn1,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status1,,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$(($Quota_Usage1)),$IsRecurring2,$InitialVolume2" >> $expected_output
echo "I,N:$Time1,$msisdn2,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status1,,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$(($Quota_Usage1)),$IsRecurring2,$InitialVolume2" >> $expected_output
echo "I,N:$Time1,$msisdn3,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status1,,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$(($Quota_Usage1)),$IsRecurring2,$InitialVolume2" >> $expected_output
echo "####################################################"
echo ""
echo "stopping the cep components...(as it will be started by the main testing framework"
my_loc3=$(pwd)
cd $my_loc/start_stop_dir
./STOP_CEP_ADAPTER.sh
./STOP_CEP_MODEL.sh POSTPAID_THROTTLE_EVENT
./STOP_CEP_MODEL.sh PREPAID_THROTTLE_EVENT
./STOP_CEP_MODEL.sh FONIC_THROTTLE_EVENT
./STOP_CEP_ENGINE.sh
cd $my_loc3




################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "



