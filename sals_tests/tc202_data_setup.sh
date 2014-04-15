#!/bin/bash
# nohup ./test_case1_v0.1.sh &> logs/test_execution_$(date +"%Y-%m-%d-%T").log &
echo "running test at $(date)"

my_loc=$(pwd)
tc=tc202

echo "PREPAID" > SINGLE_FLOW_TYPE.conf
echo "" > EXPECTED_BAD_FILES.conf

. ./pcrf_helper.sh
export SINGLE_FLOW_TYPE=$(get_flowtype_lower)
 
throttle_file=${tc}_EDR_UPCC231_MPU484_4924_40131211100031.csv
throttle_input=input_data/$throttle_file

paymenttype_lkp_file=${tc}_input_data_${SINGLE_FLOW_TYPE}_lkp.txt
paymenttype_lkp_input=input_data/${paymenttype_lkp_file}

recurring_lkp_file=${tc}_input_data_recurring_lkp.txt
recurring_lkp_input=input_data/$recurring_lkp_file


data_dir=/opt/app/sas/custom/data

out_dir=$data_dir/output_prepaid
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
./requirement_9.sh
echo " "
echo "test strategy:"
echo "we try various valid and invalid prepaid throttle 100 events and make sure"
echo "the good ones are cleanly processed and none are skipped (this was a bug in the CEP engine!!!!)"
echo " "
echo "EDR data setup:"
echo "Row1: a valid PREPAID throttle 100 event (Quota_Name=Q_110_local_Month, TriggerType=2, Quota_Status=6, QuotaValue=1)"
echo "Row2: a valid PREPAID throttle 100 event"
echo "Row3: a not valid PREPAID throttle 100 event (TriggerType=7 instead of 1-6)"
echo "Row4: a not valid PREPAID throttle 100 event (Quota_Status=4 instead of 6)"
echo "Row5: a not valid PREPAID throttle 100 event (QuotaValue=11 instead of 1)"
echo "Row6: a POSTPAID throttle 100 event - it should be igonored"
echo "Row7: a FONIC throttle 100 event - it should be igonored"
echo "Row8: a PREPAID throttle 100 event - it should be processed"

echo " "
echo ""
################################################################################
################################################################################
echo "${tc}: 1. PCRF EDRs (input stream).."
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
# ROW1..valid throttle 100
TriggerType1=2;                                                g_TriggerType=$TriggerType1;
Time1=$(date +"%Y-%m-%d %T");                                  g_Time=$Time1;
msisdn1=4912345678901;                                         g_msisdn=$msisdn1;
Quota_Name1=Q_110_local_Month;                                 g_Quota_Name=$Quota_Name1;
Quota_Status1=6;                                               g_Quota_Status=$Quota_Status1;
Quota_Usage1=1024;                                             g_Quota_Usage=$Quota_Usage1;
Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T");g_Quota_Next_Reset_Time=$Quota_Next_Reset_Time1;
Quota_Value1=1;                                                g_Quota_Value=$Quota_Value1;
PaymentType1=PREPAID;                                          g_PaymentType=$PaymentType1;
InitialVolume1=1230;                                           g_InitialVolume=$InitialVolume1;
IsRecurring1=Y;                                                g_IsRecurring=$IsRecurring1;
SGSNAddress1=0;                                                g_SGSNAddress=$SGSNAddress1;
UEIP1=1.2.3.4;                                                 g_UEIP=$UEIP1;
Quota_Consumption1=12;                                         g_Quota_Consumption=$Quota_Consumption1;

p1=$(ret_line "PCRF_EDR" "1")
p2=$(ret_line "PCRF_EDR" "2")
p3=$(ret_line "PCRF_EDR" "3")
p4=$(ret_line "PCRF_EDR" "4")
p5=$(ret_line "PCRF_EDR" "5")
p6=$(ret_line "PCRF_EDR" "6")
p7=$(ret_line "PCRF_EDR" "7")

echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####################
# ROW2.. valid throttle 100
msisdn2=4912345678902; g_msisdn=$msisdn2;
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

####
# ROW3.. bad trigger type (valid is 1 to 6)
msisdn3=4912345678903;          g_msisdn=$msisdn3;
TriggerType3=7; g_TriggerType=$TriggerType3; # TriggerType=P1
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW4.. bad quota status
msisdn4=4912345678904; g_msisdn=$msisdn4;
TriggerType4=2;        g_TriggerType=$TriggerType4; #TriggerType=P1
Quota_Status4=4;       g_Quota_Status=$Quota_Status4; #Quota_Status=P3
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW5.. bad quota value
msisdn5=4912345678905; g_msisdn=$msisdn5;
Quota_Status5=6;       g_Quota_Status=$Quota_Status5; #Quota_Status=P3
Quota_Value5=11;       g_Quota_Value=$Quota_Value5; #Quota_Value=p7
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
p7=$(ret_line "PCRF_EDR" "7")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
# ROW6.. its prepaid!
msisdn6=4912345678906; g_msisdn=$msisdn6;
Quota_Value6=1;        g_Quota_Value=$Quota_Value6;  #Quota_Value=p7
p1=$(ret_line "PCRF_EDR" "1")
p7=$(ret_line "PCRF_EDR" "7")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
# ROW7.. its fonic!
msisdn7=4912345678907; g_msisdn=$msisdn7;
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
# ROW8.. valid
msisdn8=4912345678908; g_msisdn=$msisdn8;
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

###################
rm -f ${throttle_input}.gz
gzip $throttle_input
cp ${throttle_input}.gz $data_dir/pcrf_files_prepaid/

Quota_Total1=$Quota_Usage1
################################################################################
echo "${tc}: 2. paymenttype lkp.."
rm -f $paymenttype_lkp_input
echo "$msisdn1,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn2,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn3,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn4,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn5,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn6,POSTPAID" >> $paymenttype_lkp_input
echo "$msisdn7,FONIC" >> $paymenttype_lkp_input
echo "$msisdn8,$PaymentType1" >> $paymenttype_lkp_input
cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/
cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/${paymenttype_lkp_file}.done
copy_paymenttypes

################################################################################
echo "${tc}: 3. recurring lkp.."
rm -f $recurring_lkp_input ${recurring_lkp_input}.zip
echo "$msisdn1,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn2,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn3,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn4,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input

cp ${recurring_lkp_input} $data_dir/lookup_requirring/OUT
cd $data_dir/lookup_requirring/OUT
zip ${recurring_lkp_file}.zip ./${recurring_lkp_file}
#rm ${recurring_lkp_file}
touch ${recurring_lkp_file}.zip.done
echo "debug ls -rtl $data_dir/lookup_requirring/OUT"
ls -rtl $data_dir/lookup_requirring/OUT
cd $my_loc
################################################################################


################################################################################
echo "${tc}: 4. generating the expected output.."
rm -f $expected_output

echo "I,N:$Time1,$msisdn1,$SGSNAddress1,$UEIP1,$Quota_Name1,$Quota_Consumption1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,$SGSNAddress1,,,,,,$UEIP1,,,,,,,$Quota_Status1,$Quota_Consumption1,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$Quota_Total1,$IsRecurring1,$InitialVolume1" >> $expected_output

echo "I,N:$Time1,$msisdn2,$SGSNAddress1,$UEIP1,$Quota_Name1,$Quota_Consumption1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,$SGSNAddress1,,,,,,$UEIP1,,,,,,,$Quota_Status1,$Quota_Consumption1,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$Quota_Total1,$IsRecurring1,$InitialVolume1" >> $expected_output

echo "I,N:$Time1,$msisdn8,$SGSNAddress1,$UEIP1,$Quota_Name1,$Quota_Consumption1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,$SGSNAddress1,,,,,,$UEIP1,,,,,,,$Quota_Status1,$Quota_Consumption1,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$Quota_Total1,," >> $expected_output


################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "
echo "here is the paymenttype lookup we used.."
cat $data_dir/lookup_paymenttype/${tc}_input_data_paymenttype_lkp.txt
echo " "
echo "here is the recurring lookup we used.."
cat $data_dir/lookup_requirring/OUT/${tc}_input_data_recurring_lkp.txt
echo " "
echo "here is the EDR stream we used.."
gzip -dc $data_dir/pcrf_files_prepaid/${throttle_file}.gz



