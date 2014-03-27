#!/bin/bash

echo "running test at $(date)"

my_loc=$(pwd)
 
 
throttle_file=tc3_EDR_UPCC231_MPU484_4924_40131211100031.csv
throttle_input=input_data/$throttle_file

postpaid_lkp_file=tc3_input_data_postpaid_lkp.txt
postpaid_lkp_input=input_data/$postpaid_lkp_file

recurring_lkp_file=tc3_input_data_recurring_lkp.txt
recurring_lkp_input=input_data/$recurring_lkp_file

data_dir=/opt/app/sas/custom/data

out_dir=$data_dir/output_postpaid
expected_output=$out_dir/tc3_result.expected

if [ $(ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep|wc -l) -ne 0 ]
then
  echo "still cep processing running, please kill before starting this test!"
  ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep
  exit
fi
################################################################################
################################################################################
echo "TC3: 0. CEP requirement R2: The is_recurring flag and the InitialVolume "
echo "come from the recurring lookup. The join is via msisdn and QuotaName to the throttle 100 postpaid events."
echo " "
echo "we make sure the join between the postpaid throttle 100 event works correctly"
echo " (via msisdn and  the QuotaName). We also confirm that when no lookup entry is found,"
echo "the postpaid throttle 100 event reaches the output but with these 2 attributes empty."
echo " "
echo "EDR data setup:"
echo "Row1: a POSTPAID throttle 100, Quota_name=Q_110_local_Month"
echo "Row2: a POSTPAID throttle 100, Quota_name=Q_444_local_Month"
echo " "
echo " "
echo "Recurring Lookup Setup:"
echo "Row1: same msisdn but different quota name, is_recurring=Y, InitVol=1230"
echo "Row2: same msisdn and quota name as in the edr event, is_recurring=N, InitVol=1777"
echo ""
################################################################################
################################################################################
echo "tc3: 1. PCRD EDRs (input stream).."
rm -f $throttle_input

###################
# ROW1..
# P1 - TriggerType, Time, MSISDN..
p1_desc=$(echo "# TriggerType, Time,,,MSISDN,,,,,")
TriggerType1=2; Time1=$(date --date='10 minutes ago' +"%Y-%m-%d %T"); msisdn1=4912345678901; Quota_Name1=Q_110_local_Month; Quota_Status1=6; 
Quota_Usage1=100; Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T"); Quota_Value1=1; PaymentType1=POSTPAID;
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
######
# ROW2.. valid postpaid throttle
msisdn2=4912345678902;  Quota_Name2=Q_444_local_Month
p1=$(echo "$TriggerType1,$Time1,,,$msisdn2,,,,,")
p3=$(echo ",,,,,,$Quota_Name2,$Quota_Status1,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####################
###################
rm -f ${throttle_input}.gz
gzip $throttle_input
cp ${throttle_input}.gz $data_dir/pcrf_files_postpaid/

Quota_Total1=$Quota_Usage1
################################################################################
echo "tc3: 2. postpaid lkp.."
rm -f $postpaid_lkp_input
echo "$msisdn1,$PaymentType1" >> $postpaid_lkp_input
echo "$msisdn2,$PaymentType1" >> $postpaid_lkp_input
cp $postpaid_lkp_input $data_dir/lookup_postpaid/
cp $postpaid_lkp_input $data_dir/lookup_postpaid/${postpaid_lkp_file}.done

################################################################################
echo "tc3: 3. recurring lkp.."
rm -f $recurring_lkp_input
echo "$msisdn1,Q_111_local_Month,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
InitialVolume2=1777; IsRecurring2=N;
echo "$msisdn1,$Quota_Name1,$InitialVolume2,$IsRecurring2" >> $recurring_lkp_input
cp $recurring_lkp_input $data_dir/lookup_recurring/
cp $recurring_lkp_input $data_dir/lookup_recurring/${recurring_lkp_file}.done

################################################################################


################################################################################
echo "tc3: 4. generating the expected output.."
rm -f $expected_output
echo "I,N:$Time1,$msisdn1,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status1,,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$((Quota_Usage1)),$IsRecurring2,$InitialVolume2" >> $expected_output
echo "I,N:$Time1,$msisdn2,$Quota_Name2,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status1,,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$((Quota_Usage1)),," >> $expected_output

################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "
echo "here is the postpaid lookup we used.."
cat $data_dir/lookup_postpaid/tc3_input_data_postpaid_lkp.txt
echo " "
echo "here is the recurring lookup we used.."
cat $data_dir/lookup_recurring/tc3_input_data_recurring_lkp.txt
echo " "
echo "here is the EDR stream we used.."
gzip -dc $data_dir/pcrf_files_postpaid/${throttle_file}.gz



