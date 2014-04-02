#!/bin/bash

echo "running test at $(date)"

my_loc=$(pwd)
 
echo "POSTPAID" > SINGLE_FLOW_TYPE.conf
#echo "EDR_PCRF_V6.36-POSTPAID_load.xml" > MODEL_XML_NAME.conf
echo "" > EXPECTED_BAD_FILES.conf


throttle_file=tc4_EDR_UPCC231_MPU484_4924_40131211100031.csv
throttle_input=input_data/$throttle_file

postpaid_lkp_file=tc4_input_data_postpaid_lkp.txt
postpaid_lkp_input=input_data/$postpaid_lkp_file

recurring_lkp_file=tc4_input_data_recurring_lkp.txt
recurring_lkp_input=input_data/$recurring_lkp_file

data_dir=/opt/app/sas/custom/data

out_dir=$data_dir/output_postpaid
if [ ! -d "$out_dir" ]
then 
  mkdir -p $out_dir;
fi

expected_output=$out_dir/tc4_result.expected

if [ $(ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep|wc -l) -ne 0 ]
then
  echo "still cep processing running, please kill before starting this test!"
  ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep
  exit
fi
################################################################################
################################################################################
echo "TC4:"
./requirement_4.sh
echo " "
echo "test strategy:"
echo "we add various usage and throttle events and make sure we have"
echo "a mix of usage EDRs which are relevant for 1 or more throtte 100 events"
echo "and some usage EDRs which are not relevant for any throttle 100 events."
echo " "
echo " "
echo "EDR data setup:"
echo "Row1: Postpaid usageA (1) - 50 hours ago (no relevant for any throttle events)"
echo "Row2: Postpaid usageB (2) - 49 hours ago (relevant for Throttle1 only)"
echo "Row3: Postpaid usageC (4) - 48 hours ago (relevant for Throttle1 and Throttle2)"
echo "Row4: Postpaid Throttle1 (8) - 2 hours ago (the total usage includes usageB and usageC (and Throttle1) )"
echo "Row5: Postpaid usageD (16) - 3 minutes ago (relevant for Throttle2 only)"
echo "Row6: Postpaid Throttle2 (32) - 2 minutes ago (the total usage includes usageC, Throttle1, usageD (and Throttle2) )"
echo "Row7: Postpaid usageE (64) - 1 minute ago (not relevant for any throttle events)"
echo " "
echo " "
echo ""
################################################################################
################################################################################
echo "tc4: 1. PCRD EDRs (input stream).."
rm -f $throttle_input

###################
# Row1: Postpaid usageA (1) - 50 hours ago (no relevant for any throttle events)
# P1 - TriggerType, Time, MSISDN..
p1_desc=$(echo "# TriggerType, Time,,,MSISDN,,,,,")
TriggerType1=2; Time1=$(date --date='50 hours ago' +"%Y-%m-%d %T"); msisdn1=4912345678901; Quota_Name1=Q_110_local_Month; Quota_Status1=16; 
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
######
# Row2: Postpaid usageB (2) - 49 hours ago (relevant for Throttle1 only)
Time2=$(date --date='49 hours ago' +"%Y-%m-%d %T"); Quota_Usage2=2
p1=$(echo "$TriggerType1,$Time2,,,$msisdn1,,,,,")
p4=$(echo ",$Quota_Usage2,$Quota_Next_Reset_Time1,,,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
######
# Row3: Postpaid usageC (4) - 48 hours ago (relevant for Throttle1 and Throttle2)
Time3=$(date --date='48 hours ago' +"%Y-%m-%d %T"); Quota_Usage3=4
p1=$(echo "$TriggerType1,$Time3,,,$msisdn1,,,,,")
p4=$(echo ",$Quota_Usage3,$Quota_Next_Reset_Time1,,,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
######
# Row4: Postpaid Throttle1 (8) - 2 hours ago (the total usage includes usageB and usageC (and Throttle1) )
Time4=$(date --date='2 hours ago' +"%Y-%m-%d %T"); Quota_Usage4=8; Quota_Status4=6;
p1=$(echo "$TriggerType1,$Time4,,,$msisdn1,,,,,")
p3=$(echo ",,,,,,$Quota_Name1,$Quota_Status4,,")
p4=$(echo ",$Quota_Usage4,$Quota_Next_Reset_Time1,,,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
######
# Row5: Postpaid usageD (16) - 3 minutes ago (relevant for Throttle2 only)
Time5=$(date --date='3 minutes ago' +"%Y-%m-%d %T"); Quota_Usage5=16; Quota_Status5=26;
p1=$(echo "$TriggerType1,$Time5,,,$msisdn1,,,,,")
p3=$(echo ",,,,,,$Quota_Name1,$Quota_Status5,,")
p4=$(echo ",$Quota_Usage5,$Quota_Next_Reset_Time1,,,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
######
# Row6: Postpaid Throttle2 (32) - 2 minutes ago (the total usage includes usageC, Throttle1, usageD (and Throttle2) )
Time6=$(date --date='2 minutes ago' +"%Y-%m-%d %T"); Quota_Usage6=32; Quota_Status6=6;
p1=$(echo "$TriggerType1,$Time6,,,$msisdn1,,,,,")
p3=$(echo ",,,,,,$Quota_Name1,$Quota_Status6,,")
p4=$(echo ",$Quota_Usage6,$Quota_Next_Reset_Time1,,,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
######
# Row7: Postpaid usageE (64) - 1 minute ago (not relevant for any throttle events)
Time7=$(date --date='1 minutes ago' +"%Y-%m-%d %T"); Quota_Usage7=64; Quota_Status7=26;
p1=$(echo "$TriggerType1,$Time7,,,$msisdn1,,,,,")
p3=$(echo ",,,,,,$Quota_Name1,$Quota_Status7,,")
p4=$(echo ",$Quota_Usage7,$Quota_Next_Reset_Time1,,,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

####################
###################
rm -f ${throttle_input}.gz
gzip $throttle_input
cp ${throttle_input}.gz $data_dir/pcrf_files_postpaid/

Quota_Total1=$Quota_Usage1
################################################################################
echo "tc4: 2. postpaid lkp.."
rm -f $postpaid_lkp_input
echo "$msisdn1,$PaymentType1" >> $postpaid_lkp_input
cp $postpaid_lkp_input $data_dir/lookup_paymenttype/
cp $postpaid_lkp_input $data_dir/lookup_paymenttype/${postpaid_lkp_file}.done

################################################################################
echo "tc4: 3. recurring lkp.."
rm -f $recurring_lkp_input
echo "$msisdn1,Q_111_local_Month,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
InitialVolume2=1777; IsRecurring2=N;
echo "$msisdn1,$Quota_Name1,$InitialVolume2,$IsRecurring2" >> $recurring_lkp_input
cp $recurring_lkp_input $data_dir/lookup_recurring/
cp $recurring_lkp_input $data_dir/lookup_recurring/${recurring_lkp_file}.done

################################################################################


################################################################################
echo "tc4: 4. generating the expected output.."
rm -f $expected_output
echo "I,N:$Time4,$msisdn1,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status4,,,,$Quota_Usage4,,,,,,,,,,$PaymentType1,$(($Quota_Usage2 + $Quota_Usage3 + $Quota_Usage4)),$IsRecurring2,$InitialVolume2" >> $expected_output
echo "I,N:$Time6,$msisdn1,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status6,,,,$Quota_Usage6,,,,,,,,,,$PaymentType1,$(($Quota_Usage3 + $Quota_Usage4 + $Quota_Usage5 + $Quota_Usage6)),$IsRecurring2,$InitialVolume2" >> $expected_output

################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "
echo "here is the postpaid lookup we used.."
cat $data_dir/lookup_paymenttype/tc4_input_data_postpaid_lkp.txt
echo " "
echo "here is the recurring lookup we used.."
cat $data_dir/lookup_recurring/tc4_input_data_recurring_lkp.txt
echo " "
echo "here is the EDR stream we used.."
gzip -dc $data_dir/pcrf_files_postpaid/${throttle_file}.gz



