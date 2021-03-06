#!/bin/bash
# nohup ./test_case1_v0.1.sh &> logs/test_execution_$(date +"%Y-%m-%d-%T").log &
echo "running test at $(date)"

my_loc=$(pwd)
tc=tc105

start_stop_dir=start_stop_dir_1key

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
./requirement_5.sh
echo " "
echo "test strategy:"
echo "we make sure a stop and start down break the aggregations."
echo "we add various usage and throttle events and make sure we have"
echo "a mix of usage EDRs which are relevant for 1 or more POSTPAID throtte 100 events"
echo "and some usage EDRs which are not relevant for any throttle 100 events."
echo " "
echo " "
echo "EDR data setup:"
echo "Row1: ${SINGLE_FLOW_TYPE} usageA (1) - 50 hours ago (no relevant for any throttle events)"
echo "Row2: ${SINGLE_FLOW_TYPE} usageB (2) - 49 hours ago (relevant for Throttle1 only)"
echo "stop cep"
echo "start cep"
echo "Row3: ${SINGLE_FLOW_TYPE} usageC (4) - 48 hours ago (relevant for Throttle1 and Throttle2)"
echo "Row4: ${SINGLE_FLOW_TYPE} Throttle1 (8) - 3 hours ago (the total usage includes usageB and usageC (and Throttle1) )"
echo "Row5: ${SINGLE_FLOW_TYPE} usageD (16) - 3 minutes ago (relevant for Throttle2 only)"
echo "Row6: ${SINGLE_FLOW_TYPE} Throttle2 (32) - 2 minutes ago (the total usage includes usageC, Throttle1, usageD (and Throttle2) )"
echo "Row7: ${SINGLE_FLOW_TYPE} usageE (64) - 1 minute ago (not relevant for any throttle events)"
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
Time1=$(date --date='50 hours ago' +"%Y-%m-%d %T");            g_Time=$Time1;
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
# ROW2.. usage (2) event only
Time2=$(date --date='49 hours ago' +"%Y-%m-%d %T");          g_Time=$Time2;
Quota_Status2=16;     g_Quota_Status=$Quota_Status2; # Quota_Status=p3
Quota_Usage2=2;       g_Quota_Usage=$Quota_Usage2; #Quota_Usage=p4
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
p4=$(ret_line "PCRF_EDR" "4")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#######################################################################

echo "mv $throttle_input input_data/a${throttle_file}"
mv $throttle_input input_data/a${throttle_file}

echo "rm -f input_data/a${throttle_file}.gz"
rm -f input_data/a${throttle_file}.gz

echo "gzip input_data/a${throttle_file}"
gzip input_data/a${throttle_file}

echo "cp input_data/a${throttle_file}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/"
cp input_data/a${throttle_file}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/

################################################################################
echo "tc6: 2. ${SINGLE_FLOW_TYPE} lkp.."
rm -f $paymenttype_lkp_input
echo "$msisdn1,$PaymentType1" >> $paymenttype_lkp_input
cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/
cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/${paymenttype_lkp_file}.done
copy_paymenttypes

################################################################################
echo "tc6: 3. recurring lkp.."
rm -f $recurring_lkp_input
echo "$msisdn1,Q_111_local_Month,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
InitialVolume2=1777; IsRecurring2=N;
echo "$msisdn1,$Quota_Name1,$InitialVolume2,$IsRecurring2" >> $recurring_lkp_input

cp ${recurring_lkp_input} $data_dir/lookup_requirring/OUT
cd $data_dir/lookup_requirring/OUT
zip ${recurring_lkp_file}.zip ./${recurring_lkp_file}
#rm ${recurring_lkp_file}
touch ${recurring_lkp_file}.zip.done
echo "debug ls -rtl $data_dir/lookup_requirring/OUT"
ls -rtl $data_dir/lookup_requirring/OUT
cd $my_loc
################################################################################

my_loc2=$(pwd)

echo "starting the cep components..."
  cd $my_loc/$start_stop_dir
  ./START_ALL_CEP.sh

echo "stopping the cep components..."
  ./STOP_ALL_CEP.sh


cd $my_loc2
rm $throttle_input
touch $throttle_input
rm -f ${throttle_input}.gz

#######################################################################
####
# ROW3.. usage (4) event only
Time3=$(date --date='48 hours ago' +"%Y-%m-%d %T");          g_Time=$Time3;
Quota_Status3=16;     g_Quota_Status=$Quota_Status3; # Quota_Status=p3
Quota_Usage3=4;       g_Quota_Usage=$Quota_Usage3; #Quota_Usage=p4
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
p4=$(ret_line "PCRF_EDR" "4")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

####
# ROW4.. throttle 100 (8)
Time4=$(date --date='3 hours ago' +"%Y-%m-%d %T");          g_Time=$Time4;
Quota_Status4=6;     g_Quota_Status=$Quota_Status4; # Quota_Status=p3
Quota_Usage4=8;      g_Quota_Usage=$Quota_Usage4; #Quota_Usage=p4
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
p4=$(ret_line "PCRF_EDR" "4")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

####
# ROW5.. usage (16) event only
Time5=$(date --date='3 minutes ago' +"%Y-%m-%d %T");          g_Time=$Time5;
Quota_Status5=16;      g_Quota_Status=$Quota_Status5; # Quota_Status=p3
Quota_Usage5=16;       g_Quota_Usage=$Quota_Usage5; #Quota_Usage=p4
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
p4=$(ret_line "PCRF_EDR" "4")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

####
# ROW6.. throttle 100 (32)
Time6=$(date --date='2 minutes ago' +"%Y-%m-%d %T");          g_Time=$Time6;
Quota_Status6=6;     g_Quota_Status=$Quota_Status6; # Quota_Status=p3
Quota_Usage6=32;      g_Quota_Usage=$Quota_Usage6; #Quota_Usage=p4
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
p4=$(ret_line "PCRF_EDR" "4")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

####
# ROW7.. usage (64) event only
Time7=$(date --date='1 minutes ago' +"%Y-%m-%d %T");          g_Time=$Time7;
Quota_Status7=16;      g_Quota_Status=$Quota_Status7; # Quota_Status=p3
Quota_Usage7=64;       g_Quota_Usage=$Quota_Usage7; #Quota_Usage=p4
p1=$(ret_line "PCRF_EDR" "1")
p3=$(ret_line "PCRF_EDR" "3")
p4=$(ret_line "PCRF_EDR" "4")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input

Quota_Total4=$(($Quota_Usage1+$Quota_Usage2+$Quota_Usage3+$Quota_Usage4))
Quota_Total6=$(($Quota_Usage3+$Quota_Usage4+$Quota_Usage5+$Quota_Usage6))

###################
rm -f ${throttle_input}.gz
gzip $throttle_input
cp ${throttle_input}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/



################################################################################

cd $my_loc
################################################################################
echo "${tc}: 4. generating the expected output.."
rm -f $expected_output

echo "Name#Test;Transaction_ID#${Time4}_${msisdn1}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#${Quota_Total4}.0;Int_3#${InitialVolume2};Yes_No_1#${IsRecurring2};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn1};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time6}_${msisdn1}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#${Quota_Total6}.0;Int_3#${InitialVolume2};Yes_No_1#${IsRecurring2};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn1};" >> $expected_output


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




