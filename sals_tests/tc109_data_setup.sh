#!/bin/bash
# nohup ./test_case1_v0.1.sh &> logs/test_execution_$(date +"%Y-%m-%d-%T").log &
echo "running test at $(date)"

my_loc=$(pwd)
tc=tc109

echo "POSTPAID" > SINGLE_FLOW_TYPE.conf
echo "EDR_PCRF_V6.36-POSTPAID_load.xml" > MODEL_XML_NAME.conf
echo "" > EXPECTED_BAD_FILES.conf

 
throttle_file=${tc}_EDR_UPCC231_MPU484_4924_40131211100031.csv
throttle_input=input_data/$throttle_file

paymenttype_lkp_file=${tc}_input_data_paymenttype_lkp.txt
paymenttype_lkp_input=input_data/$paymenttype_lkp_file

recurring_lkp_file=${tc}_input_data_recurring_lkp.txt
recurring_lkp_input=input_data/$recurring_lkp_file

data_dir=/opt/app/sas/custom/data

out_dir=$data_dir/output_postpaid
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
./requirement_13.sh
echo " "
echo "we make sure the join between the postpaid throttle 100 event works correctly"
echo "(via msisdn and  the QuotaName). We also confirm that when no lookup entry is "
echo "found, the postpaid throttle 100 event reaches the output but with these 2 "
echo "attributes empty. E.g. prepaid throttle 100 events shouldnt be seen in the output of the CEP Engine."
echo " "
echo " "
echo "EDR data setup:"
echo "Row1: a POSTPAID throttle 100, Quota_name=Q_110_local_Month"
echo "Row2: a POSTPAID throttle 100, Quota_name=Q_23_local_Month"
echo " "
echo " "
echo "Recurring Lookup Setup:"
echo "Row1: same msisdn but different quota name, is_recurring=Y, InitVol=1230"
echo "Row2: same msisdn and quota name as in the edr event, is_recurring=N, InitVol=1777"
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
# ROW1..a throttle 100 event - good Q_110_local_Month..
TriggerType1=2;                                                g_TriggerType=$TriggerType1;  #p1
Time1=$(date --date='50 hours ago' +"%Y-%m-%d %T");            g_Time=$Time1; # p1
msisdn1=4912345678901;                                         g_msisdn=$msisdn1; # p1
Quota_Name1=Q_110_local_Month;                                 g_Quota_Name=$Quota_Name1; # p3
Quota_Status1=6;                                               g_Quota_Status=$Quota_Status1; # p3
Quota_Usage1=1;                                                g_Quota_Usage=$Quota_Usage1; # p4
Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T");g_Quota_Next_Reset_Time=$Quota_Next_Reset_Time1; # p4
Quota_Value1=1;                                                g_Quota_Value=$Quota_Value1; # p7
PaymentType1=POSTPAID;                                         g_PaymentType=$PaymentType1; # payment type lookup
InitialVolume1=1230;                                           g_InitialVolume=$InitialVolume1; # recurring lkp
IsRecurring1=Y;                                                g_IsRecurring=$IsRecurring1; # recurring lkp
SGSNAddress1=0;                                                g_SGSNAddress=$SGSNAddress1; # p2
UEIP1=1.2.3.4;                                                 g_UEIP=$UEIP1; # p2
Quota_Consumption1=12                                          g_Quota_Consumption=$Quota_Consumption1; # p3

p1=$(ret_line "PCRF_EDR" "1")
p2=$(ret_line "PCRF_EDR" "2")
p3=$(ret_line "PCRF_EDR" "3")
p4=$(ret_line "PCRF_EDR" "4")
p5=$(ret_line "PCRF_EDR" "5")
p6=$(ret_line "PCRF_EDR" "6")
p7=$(ret_line "PCRF_EDR" "7")

echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW2.. another throttle event Q_23_local_Month..
msisdn2=4912345678902; g_msisdn=$msisdn2;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name2=Q_23_local_Month;  g_Quota_Name=$Quota_Name2; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

echo "${tc}: 1. feeding in the EDR file.."
rm -f input_data/${throttle_file}.gz
gzip input_data/${throttle_file}
cp input_data/${throttle_file}.gz $data_dir/pcrf_files_postpaid/
echo ""

echo ""

echo ""
#######################################################################

################################################################################
echo "${tc}: 2. paymenttype lkp.."
rm -f $paymenttype_lkp_input
echo "$msisdn1,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn2,$PaymentType1" >> $paymenttype_lkp_input


cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/
cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/${paymenttype_lkp_file}.done
echo ""
################################################################################
echo "${tc}: 3. recurring lkp.."
rm -f $recurring_lkp_input
echo "$msisdn1,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn1,Q_110999999_local_Month,555,N" >> $recurring_lkp_input

cp ${recurring_lkp_input} $data_dir/lookup_recurring/OUT
cd $data_dir/lookup_recurring/OUT
zip ${recurring_lkp_file}.zip ./${recurring_lkp_file}
#rm ${recurring_lkp_file}
touch ${recurring_lkp_file}.zip.done

ls -rtl $data_dir/lookup_recurring/OUT

Quota_Total1=$Quota_Usage1

echo "I,N:$Time1,$msisdn1,$SGSNAddress1,$UEIP1,$Quota_Name1,$Quota_Consumption1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,$SGSNAddress1,,,,,,$UEIP1,,,,,,,$Quota_Status1,$Quota_Consumption1,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$Quota_Total1,$IsRecurring1,$InitialVolume1" >> $expected_output

echo "I,N:$Time1,$msisdn2,$SGSNAddress1,$UEIP1,$Quota_Name2,$Quota_Consumption1,$Quota_Next_Reset_Time1,$TriggerType1,,,,,,,,,,,$SGSNAddress1,,,,,,$UEIP1,,,,,,,$Quota_Status1,$Quota_Consumption1,,,$Quota_Usage1,,,,,,,,,,$PaymentType1,$Quota_Total1,," >> $expected_output


cd $my_loc
################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "
echo "here is the paymenttype lookup we used.."
cat $my_loc/input_data/$paymenttype_lkp_file
echo " "
echo " "
echo "here is the recurring lookup we used.."
cat $my_loc/input_data/${tc}_input_data_recurring_lkp.txt
echo " "
echo " "
echo "here is the EDR stream we used.."
gzip -dc $my_loc/input_data/${throttle_file}.gz



