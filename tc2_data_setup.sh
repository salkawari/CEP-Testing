#!/bin/bash
# nohup ./test_case1_v0.1.sh &> logs/test_execution_$(date +"%Y-%m-%d-%T").log &
echo "running test at $(date)"

my_loc=$(pwd)
 
 
throttle_file=tc2_EDR_UPCC231_MPU484_4924_40131211100031.csv
throttle_input=input_data/$throttle_file
postpaid_lkp_input=input_data/tc2_input_data_postpaid_lkp.txt
recurring_lkp_input=input_data/tc2_input_data_recurring_lkp.txt

data_dir=/opt/app/sas/custom/data

out_dir=$data_dir/output
expected_output=$out_dir/tc2_ADD_REQUIRRING.expected

if [ $(ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep|wc -l) -ne 0 ]
then
  echo "still cep processing running, please kill before starting this test!"
  ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep
  exit
fi
################################################################################
echo "TC2: 0. design requirement: Data Usage in last 48 hours should be calculated correctly"
echo "(add all Quota_Usage for a particular msisdn (with the same profile id)."
echo " "
echo "EDR data setup:"
echo "Row1: a usage edr (not a throttle), Quota_Usage=100, Quota_Status=1, Quota_Value=99, 10 minutes ago"
echo "Row2: a usage edr (not a throttle), Quota_Usage=200, Quota_Status=2, Quota_Value=99, 9 minutes ago"
echo "Row3: the first 100% throttle edr (with usage), Quota_Usage=277, Quota_Status=6, Quota_Value=1, 8 minutes ago"
echo "Row4: a usage edr (after the 100% throttle), Quota_Usage=150, Quota_Status=6, Quota_Value=0, 7 minutes ago"
echo "Row5: a usage edr (after the 100% throttle), Quota_Usage=15, Quota_Status=6, Quota_Value=0, 6 minutes ago"
echo "Row6: a usage edr (before the 100% throttle), Quota_Usage=999999, Quota_Status=1, Quota_Value=99, 49 hours ago (it should be ignored for the total usage value!)"

echo " "
echo "Lookup setup:"
echo ""
################################################################################
################################################################################
echo "TC2: 1. PCRD EDRs (input stream).."
rm -f $throttle_input

###################
# ROW1..
# P1 - TriggerType, Time, MSISDN..
p1_desc=$(echo "# TriggerType, Time,,,MSISDN,,,,,")
TriggerType1=2; Time1=$(date --date='10 minutes ago' +"%Y-%m-%d %T"); msisdn1=4912345678901; Quota_Name1=Q_110_local_Month; Quota_Status1=1; 
Quota_Usage1=100; Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T"); Quota_Value1=99; PaymentType1=POSTPAID;
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
####################
# ROW2..
Time2=$(date --date='9 minutes ago' +"%Y-%m-%d %T"); Quota_Usage2=200; Quota_Status2=1; Quota_Value2=99;
p1=$(echo "$TriggerType1,$Time2,,,$msisdn1,,,,,")
p3=$(echo ",,,,,,$Quota_Name1,$Quota_Status2,,")
p4=$(echo ",$Quota_Usage2,$Quota_Next_Reset_Time1,,,,,,,")
p7=$(echo ",,,,,,,$Quota_Value2,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW3.. the throttle 100 event..
Time3=$(date --date='8 minutes ago' +"%Y-%m-%d %T"); Quota_Usage3=277; Quota_Status3=6; Quota_Value3=1;
p1=$(echo "$TriggerType1,$Time3,,,$msisdn1,,,,,")
p3=$(echo ",,,,,,$Quota_Name1,$Quota_Status3,,")
p4=$(echo ",$Quota_Usage3,$Quota_Next_Reset_Time1,,,,,,,")
p7=$(echo ",,,,,,,$Quota_Value3,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW4..
Time4=$(date --date='7 minutes ago' +"%Y-%m-%d %T"); Quota_Usage4=150; Quota_Status4=6; Quota_Value4=0;
p1=$(echo "$TriggerType1,$Time4,,,$msisdn1,,,,,")
p3=$(echo ",,,,,,$Quota_Name1,$Quota_Status4,,")
p4=$(echo ",$Quota_Usage4,$Quota_Next_Reset_Time1,,,,,,,")
p7=$(echo ",,,,,,,$Quota_Value4,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW5..
Time5=$(date --date='6 minutes ago' +"%Y-%m-%d %T"); Quota_Usage5=115; Quota_Status5=6; Quota_Value5=0;
p1=$(echo "$TriggerType1,$Time5,,,$msisdn1,,,,,")
p3=$(echo ",,,,,,$Quota_Name1,$Quota_Status5,,")
p4=$(echo ",$Quota_Usage5,$Quota_Next_Reset_Time1,,,,,,,")
p7=$(echo ",,,,,,,$Quota_Value5,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
# ROW6.. it should be ignored for the total usage as it happened before 48 hours ago..
Time6=$(date --date='49 hours ago' +"%Y-%m-%d %T"); Quota_Usage6=7; Quota_Status6=1; Quota_Value6=99;
p1=$(echo "$TriggerType1,$Time6,,,$msisdn1,,,,,")
p3=$(echo ",,,,,,$Quota_Name1,$Quota_Status6,,")
p4=$(echo ",$Quota_Usage6,$Quota_Next_Reset_Time1,,,,,,,")
p7=$(echo ",,,,,,,$Quota_Value6,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

###################
rm -f ${throttle_input}.gz
gzip $throttle_input
cp ${throttle_input}.gz $data_dir/pcrf_files/

Quota_Total1=$Quota_Usage1
################################################################################
echo "TC2: 2. postpaid lkp.."
rm -f $postpaid_lkp_input
echo "$msisdn1,$PaymentType1" >> $postpaid_lkp_input
cp $postpaid_lkp_input $data_dir/lookup_postpaid/

################################################################################
echo "TC2: 3. recurring lkp.."
rm -f $recurring_lkp_input
echo "$msisdn1,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
cp $recurring_lkp_input $data_dir/lookup_recurring/

################################################################################


################################################################################
echo "TC2: 4. generating the expected output.."
rm -f $expected_output
echo "I,N:$Time3,$msisdn1,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status3,,,,$Quota_Usage3,,,,,,,,,,,,$PaymentType1,$((Quota_Usage1+Quota_Usage2+Quota_Usage3+Quota_Usage4+Quota_Usage5)),$IsRecurring1,$InitialVolume1" >> $expected_output

################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "
echo "here is the postpaid lookup we used.."
cat $data_dir/lookup_postpaid/tc2_input_data_postpaid_lkp.txt
echo " "
echo "here is the recurring lookup we used.."
cat $data_dir/lookup_recurring/tc2_input_data_recurring_lkp.txt
echo " "
echo "here is the EDR stream we used.."
gzip -dc $data_dir/pcrf_files/${throttle_file}.gz



