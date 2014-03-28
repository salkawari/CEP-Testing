#!/bin/bash

echo "running test at $(date)"

my_loc=$(pwd)
 
echo "POSTPAID" > SINGLE_FLOW_TYPE.conf
echo "EDR_PCRF_V6.36-POSTPAID_load.xml" > MODEL_XML_NAME.conf


throttle_file=tc3_EDR_UPCC231_MPU484_4924_40131211100031.csv
throttle_input=input_data/$throttle_file

postpaid_lkp_file=tc3_input_data_postpaid_lkp.txt
postpaid_lkp_input=input_data/$postpaid_lkp_file

recurring_lkp_file=tc3_input_data_recurring_lkp.txt
recurring_lkp_input=input_data/$recurring_lkp_file

data_dir=/opt/app/sas/custom/data

out_dir=$data_dir/output_postpaid
if [ ! -d "$out_dir" ]
then 
  mkdir -p $out_dir;
fi

expected_output=$out_dir/tc3_result.expected

if [ $(ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep|wc -l) -ne 0 ]
then
  echo "still cep processing running, please kill before starting this test!"
  ps aux |grep $LOGNAME|egrep "o2-adapters-pcrf-2.12.2.jar|esp" |grep -v egrep
  exit
fi
################################################################################
################################################################################
echo "TC20:"
./requirement_20.sh
echo " "
echo "test strategy:"
echo "we have a set of good followed by bad entries, testin different possible bad entries."
echo "The bad entries should go into the bad_events subfolder."
echo "The good entres should be processed properly by the CEP Engine."
echo "attributes empty. E.g. prepaid throttle 100 events shouldnt be seen in the output of the CEP Engine."
echo " "
echo " "
echo "EDR data setup:"
echo "Row1: a valid POSTPAID throttle 100 EDR"
echo "Row2: an invalid POSTPAID throttle 100 EDR (no msisdn)"
echo "Row3: a valid POSTPAID throttle 100 EDR"
echo "Row4: an invalid POSTPAID throttle 100 EDR (no time)"
echo "Row5: a valid POSTPAID throttle 100 EDR"
echo "Row6: an invalid POSTPAID throttle 100 EDR (no quota name)"
echo "Row7: a valid POSTPAID throttle 100 EDR"
echo "Row8: an invalid POSTPAID throttle 100 EDR (no Quota_Next_Reset_Time)"
echo "Row9: a valid POSTPAID throttle 100 EDR"
echo "Row10: an invalid POSTPAID throttle 100 EDR (invalid msisdn)"
echo "Row11: a valid POSTPAID throttle 100 EDR"
echo "Row12: an invalid POSTPAID throttle 100 EDR (invalid time)"
echo "Row13: a valid POSTPAID throttle 100 EDR"
echo "Row14: an invalid POSTPAID throttle 100 EDR (invalid Quota_Next_Reset_Time)"
echo "Row15: a valid POSTPAID throttle 100 EDR"
echo " "
echo " "
################################################################################
################################################################################
echo "tc20: 1. PCRD EDRs (input stream).."
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
# ROW2.. no msisdn
msisdn2=;  
p1=$(echo "$TriggerType1,$Time1,,,$msisdn2,,,,,")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####################
###################
rm -f ${throttle_input}.gz
gzip $throttle_input
cp ${throttle_input}.gz $data_dir/pcrf_files_postpaid/

Quota_Total1=$Quota_Usage1
################################################################################
echo "tc20: 2. postpaid lkp.."
rm -f $postpaid_lkp_input
echo "$msisdn1,$PaymentType1" >> $postpaid_lkp_input
echo "$msisdn2,$PaymentType1" >> $postpaid_lkp_input

cp $postpaid_lkp_input $data_dir/lookup_paymenttype/
cp $postpaid_lkp_input $data_dir/lookup_paymenttype/${postpaid_lkp_file}.done

################################################################################
echo "tc20: 3. recurring lkp.."
rm -f $recurring_lkp_input
echo "$msisdn1,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input

cp $recurring_lkp_input $data_dir/lookup_recurring/
cp $recurring_lkp_input $data_dir/lookup_recurring/${recurring_lkp_file}.done

################################################################################


################################################################################
echo "tc20: 4. generating the expected output.."
rm -f $expected_output
echo "I,N:$Time1,$msisdn1,$Quota_Name1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,,,,,,,,,,,,,,$Quota_Status1,,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$((Quota_Usage1)),$IsRecurring2,$InitialVolume2" >> $expected_output

################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "
echo "here is the postpaid lookup we used.."
cat $data_dir/lookup_paymenttype/tc3_input_data_postpaid_lkp.txt
echo " "
echo "here is the recurring lookup we used.."
cat $data_dir/lookup_recurring/tc3_input_data_recurring_lkp.txt
echo " "
echo "here is the EDR stream we used.."
gzip -dc $data_dir/pcrf_files_postpaid/${throttle_file}.gz



