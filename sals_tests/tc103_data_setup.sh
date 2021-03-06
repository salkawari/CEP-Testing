#!/bin/bash
# nohup ./test_case1_v0.1.sh &> logs/test_execution_$(date +"%Y-%m-%d-%T").log &
echo "running test at $(date)"

my_loc=$(pwd)
tc=tc103

echo "POSTPAID" > SINGLE_FLOW_TYPE.conf
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
./requirement_3.sh
echo " "
echo "test strategy:"
echo "we have 2 usage ERDs followed by a throttle 100 postpaid event"
echo "The total usage should therefore be the total of these 3 EDRs"
echo "another usage event after this should be ignored"
echo " "
echo " "
echo "EDR data setup:"
echo "Row1: a ${SINGLE_FLOW_TYPE} usage EDR (usage=1) (Quota_Status1=16)"
echo "Row2: a ${SINGLE_FLOW_TYPE} usage EDR (usage=10)"
echo "Row3: a valid ${SINGLE_FLOW_TYPE} throttle EDR (usage=100)"
echo "Row4: a ${SINGLE_FLOW_TYPE} usage event (usage=1000) - ignored"

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
# ROW1..usage (1) event only (bad quota status)
TriggerType1=2;                                                g_TriggerType=$TriggerType1;
Time1=$(date --date='10 minutes ago' +"%Y-%m-%d %T");          g_Time=$Time1;
msisdn1=4912345678901;                                         g_msisdn=$msisdn1;
Quota_Name1=Q_110_local_Month;                                 g_Quota_Name=$Quota_Name1;
Quota_Status1=16;                                              g_Quota_Status=$Quota_Status1;
Quota_Usage1=1;                                                g_Quota_Usage=$Quota_Usage1;
Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T");g_Quota_Next_Reset_Time=$Quota_Next_Reset_Time1;
Quota_Value1=1;                                                g_Quota_Value=$Quota_Value1;
PaymentType1=$(get_flowtype_upper);                            g_PaymentType=$PaymentType1;
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
####################
# ROW2.. usage (10) event only
Time2=$(date --date='9 minutes ago' +"%Y-%m-%d %T");          g_Time=$Time2;
Quota_Usage2=10;       g_Quota_Usage=$Quota_Usage2; #Quota_Usage=p4
p1=$(ret_line "PCRF_EDR" "1")
p4=$(ret_line "PCRF_EDR" "4")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

####
# ROW3.. throttle 100 - usage 100
Time3=$(date --date='8 minutes ago' +"%Y-%m-%d %T");          g_Time=$Time3;
Quota_Status3=6;        g_Quota_Status=$Quota_Status3; # Quota_Status=p3
Quota_Usage3=100;        g_Quota_Usage=$Quota_Usage3; #Quota_Usage=p4
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
p4=$(ret_line "PCRF_EDR" "4")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

####
# ROW4.. usage event only (usage 1000) - to be ignored
Time4=$(date --date='7 minutes ago' +"%Y-%m-%d %T");          g_Time=$Time4;
Quota_Status4=16;       g_Quota_Status=$Quota_Status4; # Quota_Status=p3
Quota_Usage4=1000;      g_Quota_Usage=$Quota_Usage4; #Quota_Usage=p4
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
p4=$(ret_line "PCRF_EDR" "4")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

Quota_Total3=$(($Quota_Usage1+$Quota_Usage2+$Quota_Usage3))

###################
rm -f ${throttle_input}.gz
gzip $throttle_input
cp ${throttle_input}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/

################################################################################
echo "${tc}: 2. ${SINGLE_FLOW_TYPE} lkp.."
rm -f $paymenttype_lkp_input
echo "$msisdn1,$PaymentType1" >> $paymenttype_lkp_input
cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/
cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/${paymenttype_lkp_file}.done
copy_paymenttypes

################################################################################
echo "${tc}: 3. recurring lkp.."
rm -f $recurring_lkp_input ${recurring_lkp_input}.zip
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


################################################################################
echo "${tc}: 4. generating the expected output.."
rm -f $expected_output

echo "Name#Test;Transaction_ID#${Time3}_${msisdn1}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#${Quota_Total3}.0;Int_3#${InitialVolume1};Yes_No_1#${IsRecurring1};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn1};" >> $expected_output


################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "
echo "here is the ${SINGLE_FLOW_TYPE} lookup we used.."
cat $data_dir/lookup_paymenttype/${tc}_input_data_${SINGLE_FLOW_TYPE}_lkp.txt
echo " "
echo "here is the recurring lookup we used.."
cat $data_dir/lookup_requirring/OUT/${tc}_input_data_recurring_lkp.txt
echo " "
echo "here is the EDR stream we used.."
gzip -dc $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/${throttle_file}.gz



