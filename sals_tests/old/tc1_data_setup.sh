#!/bin/bash
# nohup ./test_case1_v0.1.sh &> logs/test_execution_$(date +"%Y-%m-%d-%T").log &
echo "running test at $(date)"

my_loc=$(pwd)
 
 
throttle_file=tc1_EDR_UPCC231_MPU484_4924_40131211100031.csv
throttle_input=input_data/$throttle_file

postpaid_lkp_file=tc1_input_data_postpaid_lkp.txt
postpaid_lkp_input=input_data/$postpaid_lkp_file

recurring_lkp_file=tc1_input_data_recurring_lkp.txt
recurring_lkp_input=input_data/$recurring_lkp_file

data_dir=/opt/app/sas/custom/data

out_dir=$data_dir/output_postpaid
expected_output=$out_dir/tc1_result.expected

if [ $(ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep|wc -l) -ne 0 ]
then
  echo "still cep processing running, please kill before starting this test!"
  ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep
  exit
fi
################################################################################
echo "TC1: 0. CEP requirement R1: the CEP Engine delivers POSTPAID throttle 100 events with various metrics. "
echo "EDRs which have a local QuotaName and TriggerType 1 to 6 are of interest."
echo "Throttle 100 events have the QuotaStatus=6 and QuotaValue=1."
echo " "
echo "input various combinations of QuotaName, TriggerType, QuotaStatus and QuotaValue"
echo "to confirm only valid combinations result in a processed throttle 100 event"
echo " "
echo "EDR data setup:"
echo "Row1: a valid POSTPAID throttle 100 event (Quota_Name=Q_110_local_Month, TriggerType=2, Quota_Status=6, QuotaValue=1)"
echo "Row2: a not valid POSTPAID throttle 100 event (TriggerType=7 instead of 1-6)"
echo "Row3: a not valid POSTPAID throttle 100 event (Quota_Name = Q_110_roaming_Month)"
echo "Row4: a not valid POSTPAID throttle 100 event (Quota_Status=4 instead of 6)"
echo "Row5: a not valid POSTPAID throttle 100 event (QuotaValue=11 instead of 1)"
echo "Row6: a not valid POSTPAID throttle 100 event (as its PREPAID)"

echo " "
echo ""
################################################################################
################################################################################
echo "TC1: 1. PCRF EDRs (input stream).."
rm -f $throttle_input

###################
# ROW1..
# 2014-03-10 14:48:24 -> datecp $postpaid_lkp_input $data_dir/lookup_postpaid/
  #p1=$(echo "$TriggerType,$Time,$SubscriberIdentifier,$IMSI,$MSISDN,$IMEI,$PaidType,$Category,$Home_Service_Zone,$Visit_Service_Zone")

# P1 - TriggerType, Time, MSISDN..
p1_desc=$(echo "# TriggerType, Time,,,MSISDN,,,,,")
TriggerType1=2; Time1=$(date +"%Y-%m-%d %T"); msisdn1=4912345678901; Quota_Name1=Q_110_local_Month; Quota_Status1=6; 
Quota_Usage1=1024; Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T"); Quota_Value1=1; PaymentType1=POSTPAID;
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
msisdn2=4912345678902;
TriggerType2=7
p1=$(echo "$TriggerType2,$Time1,,,$msisdn2,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW3..
msisdn3=4912345678903;
Quota_Name3=Q_110_roaming_Month
p1=$(echo "$TriggerType1,$Time1,,,$msisdn3,,,,,")
p3=$(echo ",,,,,,$Quota_Name3,$Quota_Status1,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW4..
msisdn4=4912345678904;
Quota_Status4=4
p1=$(echo "$TriggerType1,$Time1,,,$msisdn4,,,,,")
p3=$(echo ",,,,,,$Quota_Name1,$Quota_Status4,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW5..
msisdn5=4912345678905;
Quota_Value5=11
p1=$(echo "$TriggerType1,$Time1,,,$msisdn5,,,,,")
p7=$(echo ",,,,,,,$Quota_Value5,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
# ROW6..
msisdn6=4912345678906;
Quota_Value6=11
p1=$(echo "$TriggerType1,$Time1,,,$msisdn6,,,,,")
p3=$(echo ",,,,,,$Quota_Name1,$Quota_Status1,,")
p7=$(echo ",,,,,,,$Quota_Value1,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

###################
rm -f ${throttle_input}.gz
gzip $throttle_input
cp ${throttle_input}.gz $data_dir/pcrf_files_postpaid/

Quota_Total1=$Quota_Usage1
################################################################################
echo "TC1: 2. postpaid lkp.."
rm -f $postpaid_lkp_input
echo "$msisdn1,$PaymentType1" >> $postpaid_lkp_input
echo "$msisdn2,$PaymentType1" >> $postpaid_lkp_input
echo "$msisdn3,$PaymentType1" >> $postpaid_lkp_input
echo "$msisdn4,$PaymentType1" >> $postpaid_lkp_input
echo "$msisdn5,$PaymentType1" >> $postpaid_lkp_input
echo "$msisdn6,PREPAID" >> $postpaid_lkp_input
cp $postpaid_lkp_input $data_dir/lookup_postpaid/
cp $postpaid_lkp_input $data_dir/lookup_postpaid/${postpaid_lkp_file}.done

################################################################################
echo "TC1: 3. recurring lkp.."
rm -f $recurring_lkp_input
echo "$msisdn1,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn2,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn3,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn4,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
cp $recurring_lkp_input $data_dir/lookup_recurring/
cp $recurring_lkp_input $data_dir/lookup_recurring/${recurring_lkp_file}.done

################################################################################


################################################################################
echo "TC1: 4. generating the expected output.."
rm -f $expected_output

echo "I,N:$Time1,$msisdn1,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status1,,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$Quota_Total1,$IsRecurring1,$InitialVolume1" >> $expected_output

################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "
echo "here is the postpaid lookup we used.."
cat $data_dir/lookup_postpaid/tc1_input_data_postpaid_lkp.txt
echo " "
echo "here is the recurring lookup we used.."
cat $data_dir/lookup_recurring/tc1_input_data_recurring_lkp.txt
echo " "
echo "here is the EDR stream we used.."
gzip -dc $data_dir/pcrf_files_postpaid/${throttle_file}.gz



