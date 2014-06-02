#!/bin/bash
# nohup ./test_case1_v0.1.sh &> logs/test_execution_$(date +"%Y-%m-%d-%T").log &
echo "running test at $(date)"

my_loc=$(pwd)
tc=tc301

echo "FONIC" > SINGLE_FLOW_TYPE.conf
echo "" > EXPECTED_BAD_FILES.conf

. ./pcrf_helper.sh
export SINGLE_FLOW_TYPE=$(get_flowtype_lower)
 
throttle_file=${tc}_EDR_UPCC231_MPU484_4924_40131211100031.csv
throttle_input=input_data/$throttle_file

paymenttype_lkp_file=${tc}_input_data_${SINGLE_FLOW_TYPE}_lkp.txt
paymenttype_lkp_input=input_data/${paymenttype_lkp_file}

recurring_lkp_file=${tc}_input_data_recurring_lkp.txt
recurring_lkp_input=input_data/$recurring_lkp_file

data_dir=/opt/app/sas/ESPData

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
./requirement_1.sh
./requirement_20.sh
echo " "
echo "test strategy:"
echo "input various combinations of QuotaName, TriggerType, QuotaStatus and QuotaValue "
echo "to confirm only valid combinations result in a processed fonic throttle 100 event"
echo " "
echo "EDR data setup:"
echo "Row1: a valid ${SINGLE_FLOW_TYPE} throttle 100 event (Quota_Name=Q_110_local_Month, TriggerType=2, Quota_Status=6, QuotaValue=1)"
echo "Row2: a not valid ${SINGLE_FLOW_TYPE} throttle 100 event (TriggerType=7 instead of 1-6)"
echo "Row3: a not valid ${SINGLE_FLOW_TYPE} throttle 100 event (Quota_Name = Q_110_roaming_Month)"
echo "Row4: a not valid ${SINGLE_FLOW_TYPE} throttle 100 event (Quota_Status=4 instead of 6)"
echo "Row5: a not valid ${SINGLE_FLOW_TYPE} throttle 100 event (QuotaValue=11 instead of 1)"
echo "Row6: a not valid ${SINGLE_FLOW_TYPE} throttle 100 event (as its POSTPAID)"

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


# ROW1..
TriggerType1=2;                                                g_TriggerType=$TriggerType1; #p1
Time1=$(date +"%Y-%m-%d %T");                                  g_Time=$Time1; #p1
msisdn1=4932345678901;                                         g_msisdn=$msisdn1; #p1
#SubscriberIdentifier1=9${msisdn1};                             g_SubscriberIdentifier=$SubscriberIdentifier1; #p1
Quota_Name1=Q_110_local_Month;                                 g_Quota_Name=$Quota_Name1; #p3
Quota_Status1=6;                                               g_Quota_Status=$Quota_Status1; #p3
Quota_Usage1=1024;                                             g_Quota_Usage=$Quota_Usage1; #p4
Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T");g_Quota_Next_Reset_Time=$Quota_Next_Reset_Time1; #p4
Quota_Value1=1;                                                g_Quota_Value=$Quota_Value1; # p7
PaymentType1=$(get_flowtype_upper);                            g_PaymentType=$PaymentType1; # payment type lookup
InitialVolume1=1230;                                           g_InitialVolume=$InitialVolume1; # recurring lkp
IsRecurring1=Y;                                                g_IsRecurring=$IsRecurring1; # recurring lkp
SGSNAddress1=0;                                                g_SGSNAddress=$SGSNAddress1; #p2
UEIP1=1.2.3.4;                                                 g_UEIP=$UEIP1; #p2
Quota_Consumption1=12                                          g_Quota_Consumption=$Quota_Consumption1; #p3

p1=$(ret_line "PCRF_EDR" "1")
p2=$(ret_line "PCRF_EDR" "2")
p3=$(ret_line "PCRF_EDR" "3")
p4=$(ret_line "PCRF_EDR" "4")
p5=$(ret_line "PCRF_EDR" "5")
p6=$(ret_line "PCRF_EDR" "6")
p7=$(ret_line "PCRF_EDR" "7")

echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####################
# ROW2.. bad trigger type
msisdn2=4932345678902; g_msisdn=$msisdn2;
TriggerType2=7;        g_TriggerType=$TriggerType2; #p1
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

####
# ROW3.. bad quota name
msisdn3=4932345678903;          g_msisdn=$msisdn3;
Quota_Name3=Q_110_roaming_Month; g_Quota_Name=$Quota_Name3; #p3
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW4.. bad quota status
msisdn4=4932345678904; g_msisdn=$msisdn4;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name4=Q_110_local_Month; g_Quota_Name=$Quota_Name4; #p3
Quota_Status4=4;       g_Quota_Status=$Quota_Status4; #p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW5.. bad quota value
msisdn5=4932345678905; g_msisdn=$msisdn5;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Status5=6;       g_Quota_Status=$Quota_Status5; #p3
p3=$(ret_line "PCRF_EDR" "3")
Quota_Value5=11;       g_Quota_Value=$Quota_Value5; #p7
p7=$(ret_line "PCRF_EDR" "7")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
####
# ROW6.. its prepaid!
msisdn6=4932345678906; g_msisdn=$msisdn6; #p1
p1=$(ret_line "PCRF_EDR" "1")
Quota_Value6=1;       g_Quota_Value=$Quota_Value6; #p7
p7=$(ret_line "PCRF_EDR" "7")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

###################
rm -f ${throttle_input}.gz
gzip $throttle_input
cp ${throttle_input}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/

Quota_Total1=$Quota_Usage1
################################################################################
echo "${tc}: 2. ${SINGLE_FLOW_TYPE} lkp.."
rm -f $paymenttype_lkp_input
echo "$msisdn1,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn2,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn3,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn4,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn5,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn6,POSTPAID" >> $paymenttype_lkp_input
echo "cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/"
echo "cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/${paymenttype_lkp_file}.done"
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

Quota_Total1=$Quota_Usage1
echo "Name#Test;Transaction_ID#${Time1}_${msisdn1}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#0.0;Int_3#${InitialVolume1};Yes_No_1#${IsRecurring1};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn1};" >> $expected_output


################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "
echo "here is the ${SINGLE_FLOW_TYPE} lookup we used.."
cat $data_dir/lookup_paymenttype/${tc}_input_data_${SINGLE_FLOW_TYPE}_lkp.txt
echo " "
echo "here is the requirring lookup we used.."
cat $data_dir/lookup_requirring/OUT/${tc}_input_data_recurring_lkp.txt
echo " "
echo "here is the EDR stream we used.."
gzip -dc $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/${throttle_file}.gz



