#!/bin/bash
# nohup ./test_case1_v0.1.sh &> logs/test_execution_$(date +"%Y-%m-%d-%T").log &
echo "running test at $(date)"

my_loc=$(pwd)
tc=tc208

start_stop_dir=start_stop_dir_1key

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
./requirement_11.sh
echo " "
echo "test strategy:"
echo "(${SINGLE_FLOW_TYPE}) send in quota_names that should be processed in phase2 and those which shouldnt"
echo "send in all 18 good quota_names and"
echo "send in some other quota_names mixed in"
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
# ROW1..a throttle 100 event - good Q_23_local_Month..
TriggerType1=2;                                                g_TriggerType=$TriggerType1;  #p1
Time1=$(date --date='50 hours ago' +"%Y-%m-%d %T");            g_Time=$Time1; # p1
msisdn1=4922345678901;                                         g_msisdn=$msisdn1; # p1
Quota_Name1=Q_143_local_Month;                                 g_Quota_Name=$Quota_Name1; # p3
Quota_Status1=6;                                               g_Quota_Status=$Quota_Status1; # p3
Quota_Usage1=1;                                                g_Quota_Usage=$Quota_Usage1; # p4
Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T");g_Quota_Next_Reset_Time=$Quota_Next_Reset_Time1; # p4
Quota_Value1=1;                                                g_Quota_Value=$Quota_Value1; # p7
PaymentType1=PREPAID;                                          g_PaymentType=$PaymentType1; # payment type lookup
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
# ROW2.. another throttle event but not in the list Q_9143_local_Month..
msisdn2=4922345678902; g_msisdn=$msisdn2;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name2=Q_9143_local_Month;  g_Quota_Name=$Quota_Name2; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW3.. throttle in the list Q_144_local_Month
msisdn3=4922345678903; g_msisdn=$msisdn3;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name3=Q_144_local_Month;  g_Quota_Name=$Quota_Name3; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW4.. throttle in not the list Q_968_local_Month
msisdn4=4922345678904; g_msisdn=$msisdn4;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name4=Q_9144_local_Month;  g_Quota_Name=$Quota_Name4; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW5.. throttle in the list Q_145_local_Month
msisdn5=4922345678905; g_msisdn=$msisdn5;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name5=Q_145_local_Month;  g_Quota_Name=$Quota_Name5; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW6.. throttle in not the list Q_9145_local_Month
msisdn6=4922345678906; g_msisdn=$msisdn6;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name6=Q_9145_local_Month;  g_Quota_Name=$Quota_Name6; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW7.. throttle in the list Q_130_local_Month
msisdn7=4922345678907; g_msisdn=$msisdn7;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name7=Q_130_local_Month;  g_Quota_Name=$Quota_Name7; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW8.. throttle in not the list Q_9130_local_Month
msisdn8=4922345678908; g_msisdn=$msisdn8;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name8=Q_9130_local_Month;  g_Quota_Name=$Quota_Name8; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW9.. throttle in the list Q_126_local_Month
msisdn9=4922345678909; g_msisdn=$msisdn9;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name9=Q_126_local_Month;  g_Quota_Name=$Quota_Name9; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW10.. throttle in not the list Q_9126_local_Month
msisdn10=4922345678910; g_msisdn=$msisdn10;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name10=Q_9126_local_Month;  g_Quota_Name=$Quota_Name10; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW11.. throttle in the list Q_90_local_Month
msisdn11=4922345678911; g_msisdn=$msisdn11;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name11=Q_90_local_Month;  g_Quota_Name=$Quota_Name11; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW12.. throttle in not the list Q_990_local_Month
msisdn12=4922345678912; g_msisdn=$msisdn12;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name12=Q_990_local_Month;  g_Quota_Name=$Quota_Name12; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW13.. throttle in the list Q_147_local_Month
msisdn13=4922345678913; g_msisdn=$msisdn13;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name13=Q_147_local_Month;  g_Quota_Name=$Quota_Name13; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW14.. throttle in not the list Q_9147_local_Month
msisdn14=4922345678914; g_msisdn=$msisdn14;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name14=Q_9147_local_Month;  g_Quota_Name=$Quota_Name14; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW15.. throttle in the list Q_149_local_Month
msisdn15=4922345678915; g_msisdn=$msisdn15;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name15=Q_149_local_Month;  g_Quota_Name=$Quota_Name15; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW16.. throttle in not the list Q_9149_local_Month
msisdn16=4922345678916; g_msisdn=$msisdn16;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name16=Q_9149_local_Month;  g_Quota_Name=$Quota_Name16; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW17.. throttle in the list Q_11_local_Month
msisdn17=4922345678917; g_msisdn=$msisdn17;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name17=Q_11_local_Month;  g_Quota_Name=$Quota_Name17; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW18.. throttle in not the list Q_911_local_Month
msisdn18=4922345678918; g_msisdn=$msisdn18;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name18=Q_911_local_Month;  g_Quota_Name=$Quota_Name18; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################


# ROW19.. throttle in the list Q_89_local_Month
msisdn19=4922345678919; g_msisdn=$msisdn19;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name19=Q_89_local_Month;  g_Quota_Name=$Quota_Name19; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW20.. throttle in not the list Q_989_local_Month
msisdn20=4922345678920; g_msisdn=$msisdn20;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name20=Q_989_local_Month;  g_Quota_Name=$Quota_Name20; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW21.. throttle in the list Q_148_local_Month
msisdn21=4922345678921; g_msisdn=$msisdn21;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name21=Q_148_local_Month;  g_Quota_Name=$Quota_Name21; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW22.. throttle in not the list Q_9148_local_Month
msisdn22=4922345678922; g_msisdn=$msisdn22;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name22=Q_9148_local_Month;  g_Quota_Name=$Quota_Name22; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW23.. throttle in the list Q_73_local_Month
msisdn23=4922345678923; g_msisdn=$msisdn23;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name23=Q_89_local_Month;  g_Quota_Name=$Quota_Name23; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW24.. throttle in not the list Q_989_local_Month
msisdn24=4922345678924; g_msisdn=$msisdn24;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name24=Q_989_local_Month;  g_Quota_Name=$Quota_Name24; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW25.. throttle in the list Q_148_local_Month
msisdn25=4922345678925; g_msisdn=$msisdn25;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name25=Q_148_local_Month;  g_Quota_Name=$Quota_Name25; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW26.. throttle in not the list Q_9148_local_Month
msisdn26=4922345678926; g_msisdn=$msisdn26;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name26=Q_9148_local_Month;  g_Quota_Name=$Quota_Name26; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW27.. throttle in the list Q_150_local_Month
msisdn27=4922345678927; g_msisdn=$msisdn27;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name27=Q_150_local_Month;  g_Quota_Name=$Quota_Name27; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW28.. throttle in not the list Q_9150_local_Month
msisdn28=4922345678928; g_msisdn=$msisdn28;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name28=Q_9150_local_Month;  g_Quota_Name=$Quota_Name28; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW29.. throttle in the list Q_146_local_Month
msisdn29=4922345678929; g_msisdn=$msisdn29;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name29=Q_146_local_Month;  g_Quota_Name=$Quota_Name29; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW30.. throttle in not the list Q_9146_local_Month
msisdn30=4922345678930; g_msisdn=$msisdn30;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name30=Q_9146_local_Month;  g_Quota_Name=$Quota_Name30; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW31.. throttle in the list Q_128_local_Month
msisdn31=4922345678931; g_msisdn=$msisdn31;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name31=Q_128_local_Month;  g_Quota_Name=$Quota_Name31; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW32.. throttle in not the list Q_9128_local_Month
msisdn32=4922345678932; g_msisdn=$msisdn32;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name32=Q_9128_local_Month;  g_Quota_Name=$Quota_Name32; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW33.. throttle in the list Q_58_local_Month
msisdn33=4922345678933; g_msisdn=$msisdn33;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name33=Q_58_local_Month;  g_Quota_Name=$Quota_Name33; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW34.. throttle in not the list Q_958_local_Month
msisdn34=4922345678934; g_msisdn=$msisdn34;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name34=Q_958_local_Month;  g_Quota_Name=$Quota_Name34; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW35.. throttle in the list Q_59_local_Month
msisdn35=4922345678935; g_msisdn=$msisdn35;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name35=Q_59_local_Month;  g_Quota_Name=$Quota_Name35; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW36.. throttle in not the list Q_959_local_Month
msisdn36=4922345678936; g_msisdn=$msisdn36;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name36=Q_959_local_Month;  g_Quota_Name=$Quota_Name36; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW37.. throttle in the list Q_38_local_Month
msisdn37=4922345678937; g_msisdn=$msisdn37;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name37=Q_38_local_Month;  g_Quota_Name=$Quota_Name37; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW38.. throttle in not the list Q_938_local_Month
msisdn38=4922345678938; g_msisdn=$msisdn38;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name38=Q_938_local_Month;  g_Quota_Name=$Quota_Name38; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

# ROW39.. throttle in the list Q_88_local_Month
msisdn39=4922345678939; g_msisdn=$msisdn39;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name39=Q_88_local_Month;  g_Quota_Name=$Quota_Name39; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW38.. throttle in not the list Q_988_local_Month
msisdn40=4922345678940; g_msisdn=$msisdn40;
p1=$(ret_line "PCRF_EDR" "1")
Quota_Name40=Q_988_local_Month;  g_Quota_Name=$Quota_Name40; # p3
p3=$(ret_line "PCRF_EDR" "3")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################

echo "${tc}: 1. feeding in the EDR file.."
rm -f input_data/${throttle_file}.gz
gzip input_data/${throttle_file}
cp input_data/${throttle_file}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/
echo ""

echo ""

echo ""
#######################################################################

################################################################################
echo "${tc}: 2. paymenttype lkp.."
rm -f $paymenttype_lkp_input
echo "$msisdn1,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn2,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn3,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn4,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn5,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn6,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn7,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn8,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn9,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn10,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn11,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn12,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn13,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn14,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn15,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn16,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn17,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn18,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn19,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn20,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn21,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn22,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn23,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn24,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn25,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn26,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn27,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn28,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn29,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn30,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn31,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn32,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn33,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn34,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn35,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn36,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn37,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn38,$PaymentType1" >> $paymenttype_lkp_input

cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/
cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/${paymenttype_lkp_file}.done
copy_paymenttypes
echo ""
################################################################################
echo "${tc}: 3. recurring lkp.."
rm -f $recurring_lkp_input
echo "$msisdn1,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn2,$Quota_Name2,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn3,$Quota_Name3,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input


cp ${recurring_lkp_input} $data_dir/lookup_requirring/OUT
cd $data_dir/lookup_requirring/OUT
zip ${recurring_lkp_file}.zip ./${recurring_lkp_file}
#rm ${recurring_lkp_file}
touch ${recurring_lkp_file}.zip.done

ls -rtl $data_dir/lookup_requirring/OUT

Quota_Total1=$Quota_Usage1
echo "Name#Test;Transaction_ID#${Time1}_${msisdn1}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#${InitialVolume1};Yes_No_1#${IsRecurring1};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn1};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn3}_${Quota_Name3}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#${InitialVolume1};Yes_No_1#${IsRecurring1};String_1#${Quota_Name3};String_2#6;MSISDN#${msisdn3};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn5}_${Quota_Name5}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name5};String_2#6;MSISDN#${msisdn5};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn7}_${Quota_Name7}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name7};String_2#6;MSISDN#${msisdn7};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn9}_${Quota_Name9}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name9};String_2#6;MSISDN#${msisdn9};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn11}_${Quota_Name11}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name11};String_2#6;MSISDN#${msisdn11};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn13}_${Quota_Name13}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name13};String_2#6;MSISDN#${msisdn13};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn15}_${Quota_Name15}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name15};String_2#6;MSISDN#${msisdn15};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn17}_${Quota_Name17}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name17};String_2#6;MSISDN#${msisdn17};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn19}_${Quota_Name19}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name19};String_2#6;MSISDN#${msisdn19};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn21}_${Quota_Name21}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name21};String_2#6;MSISDN#${msisdn21};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn23}_${Quota_Name23}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name23};String_2#6;MSISDN#${msisdn23};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn25}_${Quota_Name25}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name25};String_2#6;MSISDN#${msisdn25};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn27}_${Quota_Name27}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name27};String_2#6;MSISDN#${msisdn27};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn29}_${Quota_Name29}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name29};String_2#6;MSISDN#${msisdn29};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn31}_${Quota_Name31}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name31};String_2#6;MSISDN#${msisdn31};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn33}_${Quota_Name33}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name33};String_2#6;MSISDN#${msisdn33};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn35}_${Quota_Name35}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name35};String_2#6;MSISDN#${msisdn35};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn37}_${Quota_Name37}_${Quota_Next_Reset_Time1};Int_1#18;Type#$PaymentType1;Float_1#0.0;Int_3#0;Yes_No_1#;String_1#${Quota_Name37};String_2#6;MSISDN#${msisdn37};" >> $expected_output

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



