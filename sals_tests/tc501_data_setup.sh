#!/bin/bash
# nohup ./test_case1_v0.1.sh &> logs/test_execution_$(date +"%Y-%m-%d-%T").log &
echo "running test at $(date)"

my_loc=$(pwd)
tc=tc501

echo "POSTPAID" > SINGLE_FLOW_TYPE.conf
echo "" > EXPECTED_BAD_FILES.conf
echo "SECOND_STEP" > MODEL_TYPE.conf

. ./pcrf_helper.sh
export SINGLE_FLOW_TYPE=$(get_flowtype_lower)
 
throttle_file=${tc}_EDR_UPCC231_MPU484_4924_40131211100031.csv
throttle_input=input_data/$throttle_file

paymenttype_lkp_file=${tc}_input_data_${SINGLE_FLOW_TYPE}_lkp.txt
paymenttype_lkp_input=input_data/${paymenttype_lkp_file}

fct_2nd_step_camp_file=${tc}_input_data_${SINGLE_FLOW_TYPE}_fct_camp.txt
fct_2nd_step_camp_input=input_data/${fct_2nd_step_camp_file}

data_dir=/opt/app/sas/ESPData

out_dir=$data_dir/output_${SINGLE_FLOW_TYPE}_2nd_step
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
./requirement_500.sh
echo " "
echo "test strategy:"
echo "input the data for a lazy user to be recognised by the POSTPAID_SECOND_STEP model"
echo " "
echo "EDR data setup:"
echo "25 hours ago: msisdn1 lazy"
echo "25 hours ago: msisdn2 not lazy"
echo "24 hours ago: msisdn3 lazy"
echo "24 hours ago: msisdn4 not lazy"
echo "2 seconds ago: msisdn2 lazy"
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

# 52 works
#51 doesnt work


# ROW1.. 25 hours ago: msisdn1 lazy
TriggerType1=2;                                                g_TriggerType=$TriggerType1; #p1
Time1=$(date --date='25 hours ago' +"%Y-%m-%d %T");            g_Time=$Time1; #p1
msisdn1=4912345678901;                                         g_msisdn=$msisdn1; #p1
Quota_Name1=Q_111_local_Month;                                 g_Quota_Name=$Quota_Name1; #p3
Quota_Status1=6;                                               g_Quota_Status=$Quota_Status1; #p3
Quota_Usage1=1024;                                             g_Quota_Usage=$Quota_Usage1; #p4
Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T");g_Quota_Next_Reset_Time=$Quota_Next_Reset_Time1; #p4
Quota_Value1=0;                                                g_Quota_Value=$Quota_Value1; # p7
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
#####################
# ROW2.. 25 hours ago: msisdn2 not lazy
msisdn2=4912345678902; g_msisdn=$msisdn2;
Time2=$(date --date='25 hours ago' +"%Y-%m-%d %T");            g_Time=$Time2; #p1
Quota_Name2=Q_110_local_Month;        g_Quota_Name=$Quota_Name2; #p3
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#####################
# ROW3.. 24 hours ago: msisdn3 lazy
msisdn3=4912345678903; g_msisdn=$msisdn3;
Time3=$(date --date='24 hours ago' +"%Y-%m-%d %T");            g_Time=$Time3; #p1
Quota_Name3=Q_111_local_Month;        g_Quota_Name=$Quota_Name3; #p3
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#####################
# ROW4.. 24 hours ago: msisdn4 not lazy
msisdn4=4912345678904; g_msisdn=$msisdn4;
Time4=$(date --date='24 hours ago' +"%Y-%m-%d %T");            g_Time=$Time4; #p1
Quota_Name4=Q_110_local_Month;        g_Quota_Name=$Quota_Name4; #p3
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#####################
# ROW5.. 2 seconds ago: msisdn2 lazy
msisdn2=4912345678902; g_msisdn=$msisdn2;
Time2=$(date --date='2 seconds ago' +"%Y-%m-%d %T");            g_Time=$Time2; #p1
Quota_Name2=Q_111_local_Month;        g_Quota_Name=$Quota_Name2; #p3
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

###################
rm -f ${throttle_input}.gz
gzip $throttle_input
echo "debug $(pwd)"
echo "cp ${throttle_input}.gz $data_dir/pcrf_files_post_2nd_step"
cp ${throttle_input}.gz $data_dir/pcrf_files_post_2nd_step


Quota_Total1=$Quota_Usage1
################################################################################

################################################################################
echo "${tc}: 3. fct_2nd_step_camp.."
rm -f $fct_2nd_step_camp_input ${fct_2nd_step_camp_input}.zip
caa_id1=1; cam_id1=$(echo "1"); profile_id1=$Quota_Name1; ThrottleVol1=2; DaysRemaining1=3;
caaSendDt1=$(date --date='16 days' +"%Y-%m-%d %T");
caaValidToDt1=$(date --date='2 days' +"%Y-%m-%d %T");

caa_id2=2;profile_id2=$Quota_Name2;
caa_id3=3;profile_id3=$Quota_Name3;
caa_id4=4;profile_id4=Q_111_local_Month

echo "$caa_id1,$cam_id1,$msisdn1,$profile_id1,$ThrottleVol1,$DaysRemaining1,$caaSendDt1,$caaValidToDt1" >> $fct_2nd_step_camp_input
echo "$caa_id2,$cam_id1,$msisdn2,$profile_id2,$ThrottleVol1,$DaysRemaining1,$caaSendDt1,$caaValidToDt1" >> $fct_2nd_step_camp_input
echo "$caa_id3,$cam_id1,$msisdn3,$profile_id3,$ThrottleVol1,$DaysRemaining1,$caaSendDt1,$caaValidToDt1" >> $fct_2nd_step_camp_input
echo "$caa_id4,$cam_id1,$msisdn4,$profile_id4,$ThrottleVol1,$DaysRemaining1,$caaSendDt1,$caaValidToDt1" >> $fct_2nd_step_camp_input

cp ${fct_2nd_step_camp_input} $data_dir/post_camp_stream
cd $data_dir/post_camp_stream
zip ${fct_2nd_step_camp_file}.zip ${fct_2nd_step_camp_file}
touch ${fct_2nd_step_camp_file}.zip.done
echo "debug ls -rtl $data_dir/post_camp_stream"
ls -rtl $data_dir/post_camp_stream
cd $my_loc
################################################################################


################################################################################
echo "${tc}: 4. generating the expected output.."
rm -f $expected_output

echo "TransactionID#${caa_id2}_${Quota_Status1}_${profile_id2};MSISDN#${msisdn2};CAM_ID#${cam_id1};IN_THROTTLE#Yes;CAA_ID#${caa_id2};THROTTLE_VOLUME#${ThrottleVol1};Days_Remaining#${DaysRemaining1};PROFILE_ID#${profile_id2};CAA_SEND_DATE#${caaSendDt1};CAA_VALID_TO_DATE#${caaValidToDt1};Name#Test;" >> $expected_output
echo "TransactionID#${caa_id3}_${Quota_Status1}_${profile_id3};MSISDN#${msisdn3};CAM_ID#${cam_id1};IN_THROTTLE#Yes;CAA_ID#${caa_id3};THROTTLE_VOLUME#${ThrottleVol1};Days_Remaining#${DaysRemaining1};PROFILE_ID#${profile_id3};CAA_SEND_DATE#${caaSendDt1};CAA_VALID_TO_DATE#${caaValidToDt1};Name#Test;" >> $expected_output

################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "
#echo "here is the ${SINGLE_FLOW_TYPE} lookup we used.."
#cat $data_dir/lookup_paymenttype/${tc}_input_data_${SINGLE_FLOW_TYPE}_lkp.txt
echo " "
echo "here is the campaign we used.."
cat $data_dir/post_camp_stream/${fct_2nd_step_camp_file}
echo " "
echo "here is the EDR stream we used.."
gzip -dc $data_dir/pcrf_files_post_2nd_step/${throttle_file}.gz



