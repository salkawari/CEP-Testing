#!/bin/bash
# nohup ./test_case1_v0.1.sh &> logs/test_execution_$(date +"%Y-%m-%d-%T").log &
echo "running test at $(date)"

my_loc=$(pwd)
tc=tc207

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
./requirement_8.sh
echo " "
echo "test strategy:"
echo "prepare the lookups and put in the correct location"
echo "start CEP"
echo "feed in a EDR file"
echo "feed in changed lookups"
echo "feed in another EDR file"
echo "-> now the new lookup values should be used!!"
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
# ROW1..a throttle 100 event..
TriggerType1=2;                                                g_TriggerType=$TriggerType1;
Time1=$(date --date='50 hours ago' +"%Y-%m-%d %T");            g_Time=$Time1;
msisdn1=4922345678901;                                         g_msisdn=$msisdn1;
Quota_Name1=Q_143_local_Month;                                 g_Quota_Name=$Quota_Name1;
Quota_Status1=6;                                               g_Quota_Status=$Quota_Status1;
Quota_Usage1=1;                                                g_Quota_Usage=$Quota_Usage1;
Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T");g_Quota_Next_Reset_Time=$Quota_Next_Reset_Time1;
Quota_Value1=1;                                                g_Quota_Value=$Quota_Value1;
PaymentType1=PREPAID;                                          g_PaymentType=$PaymentType1;
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
#########################
# ROW2.. another throttle event..
msisdn2=4922345678902; g_msisdn=$msisdn2;
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################
# ROW3.. another throttle event..
msisdn3=4922345678903; g_msisdn=$msisdn3;
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> $throttle_input
#########################


echo ""

echo ""
#######################################################################

################################################################################
echo "${tc}: 2. paymenttype lkp.."
rm -f $paymenttype_lkp_input
echo "$msisdn1,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn2,$PaymentType1" >> $paymenttype_lkp_input
echo "$msisdn3,$PaymentType1" >> $paymenttype_lkp_input
cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/
cp $paymenttype_lkp_input $data_dir/lookup_paymenttype/${paymenttype_lkp_file}.done
copy_paymenttypes

echo ""
################################################################################
echo "${tc}: 3. recurring lkp.."
rm -f $recurring_lkp_input
echo "$msisdn1,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn2,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input
echo "$msisdn3,$Quota_Name1,$InitialVolume1,$IsRecurring1" >> $recurring_lkp_input


cp ${recurring_lkp_input} $data_dir/lookup_requirring/OUT
cd $data_dir/lookup_requirring/OUT
zip ${recurring_lkp_file}.zip ./${recurring_lkp_file}
#rm ${recurring_lkp_file}
touch ${recurring_lkp_file}.zip.done

ls -rtl $data_dir/lookup_requirring/OUT

Quota_Total1=$Quota_Usage1
echo "Name#Test;Transaction_ID#${Time1}_${msisdn1}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#${Quota_Total1}.0;Int_3#${InitialVolume1};Yes_No_1#${IsRecurring1};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn1};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn2}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#${Quota_Total1}.0;Int_3#${InitialVolume1};Yes_No_1#${IsRecurring1};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn2};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time1}_${msisdn3}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#${Quota_Total1}.0;Int_3#${InitialVolume1};Yes_No_1#${IsRecurring1};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn3};" >> $expected_output

cd $my_loc
################################################################################
echo ""
echo "starting the cep components..."
cd $my_loc/$start_stop_dir
./START_ALL_CEP.sh

cd $my_loc
################################################################################
echo "${tc}: 4. feeding in the 1st EDR file.."
rm -f input_data/${throttle_file}.gz
gzip input_data/${throttle_file}
cp input_data/${throttle_file}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/
echo ""

echo "${tc}: 5. we change the lookups.."
rm -f input_data/a${paymenttype_lkp_file}
touch input_data/a${paymenttype_lkp_file}
echo "$msisdn1,$PaymentType1" >> input_data/a${paymenttype_lkp_file}
echo "$msisdn2,POSTPAID"      >> input_data/a${paymenttype_lkp_file}
echo "$msisdn3,FONIC"         >> input_data/a${paymenttype_lkp_file}

rm -f input_data/a${recurring_lkp_file}
touch input_data/a${recurring_lkp_file}
InitialVolume2=5; IsRecurring2=Y
echo "$msisdn1,$Quota_Name1,$InitialVolume2,$IsRecurring2" >> input_data/a${recurring_lkp_file}
echo "$msisdn2,$Quota_Name1,$InitialVolume2,$IsRecurring2" >> input_data/a${recurring_lkp_file}
echo "$msisdn3,$Quota_Name1,$InitialVolume2,$IsRecurring2" >> input_data/a${recurring_lkp_file}

echo ""

echo "${tc}: 6. feed in the 2nd EDR file.."
rm -f input_data/a${throttle_file}
touch input_data/a${throttle_file}

# ROW1.. another throttle event..
msisdn1=4922345678901; g_msisdn=$msisdn1;
Time21=$(date --date='40 hours ago' +"%Y-%m-%d %T");            g_Time=$Time21;
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> input_data/a${throttle_file}
#########################
# ROW2.. another throttle event..
msisdn2=4922345678902; g_msisdn=$msisdn2;
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> input_data/a${throttle_file}
#########################
# ROW3.. another throttle event..
msisdn3=4922345678903; g_msisdn=$msisdn3;
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> input_data/a${throttle_file}
#########################

# we feed first the lookups, then the 2nd edr file in..
cp input_data/a${paymenttype_lkp_file} $data_dir/lookup_paymenttype/
cp input_data/a${paymenttype_lkp_file} $data_dir/lookup_paymenttype/a${paymenttype_lkp_file}.done
copy_paymenttypes

cp input_data/a${recurring_lkp_file} $data_dir/lookup_requirring/OUT
cd $data_dir/lookup_requirring/OUT
zip a${recurring_lkp_file}.zip ./a${recurring_lkp_file}
touch a${recurring_lkp_file}.zip.done
cd $my_loc

echo "sleep 14 before feeding in edr.."
sleep 14

rm -f input_data/a${throttle_file}.gz
gzip input_data/a${throttle_file}
cp input_data/a${throttle_file}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/

# here is the expected output..
Quota_Total1=$Quota_Usage1
echo "Name#Test;Transaction_ID#${Time21}_${msisdn1}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#${Quota_Total1}.0;Int_3#${InitialVolume2};Yes_No_1#${IsRecurring2};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn1};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time21}_${msisdn2}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#${Quota_Total1}.0;Int_3#${InitialVolume2};Yes_No_1#${IsRecurring2};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn2};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time21}_${msisdn3}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#${Quota_Total1}.0;Int_3#${InitialVolume2};Yes_No_1#${IsRecurring2};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn3};" >> $expected_output

#############################################
echo "${tc}: 6. we change the lookups back to what they were at the start.."
rm -f input_data/b${paymenttype_lkp_file}
touch input_data/b${paymenttype_lkp_file}
echo "$msisdn1,$PaymentType1" >> input_data/b${paymenttype_lkp_file}
echo "$msisdn2,$PaymentType1" >> input_data/b${paymenttype_lkp_file}
echo "$msisdn3,$PaymentType1" >> input_data/b${paymenttype_lkp_file}

rm -f input_data/b${recurring_lkp_file}
touch input_data/b${recurring_lkp_file}
InitialVolume3=1230; IsRecurring3=N
echo "$msisdn1,$Quota_Name1,$InitialVolume3,$IsRecurring3" >> input_data/b${recurring_lkp_file}
echo "$msisdn2,$Quota_Name1,$InitialVolume3,$IsRecurring3" >> input_data/b${recurring_lkp_file}
echo "$msisdn3,$Quota_Name1,$InitialVolume3,$IsRecurring3" >> input_data/b${recurring_lkp_file}

echo ""

echo "${tc}: 7. feed in the 2nd EDR file.."
rm -f input_data/b${throttle_file}
touch input_data/b${throttle_file}
# ROW1.. another throttle event..
msisdn1=4922345678901; g_msisdn=$msisdn1;
Time31=$(date --date='30 hours ago' +"%Y-%m-%d %T"); g_Time=$Time31;
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> input_data/b${throttle_file}
#########################
# ROW2.. another throttle event..
msisdn2=4922345678902; g_msisdn=$msisdn2;
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> input_data/b${throttle_file}
#########################
# ROW3.. another throttle event..
msisdn3=4922345678903; g_msisdn=$msisdn3;
p1=$(ret_line "PCRF_EDR" "1")
echo "$p1,$p2,$p3,$p4,$p5,$p6,$p7" >> input_data/b${throttle_file}
#########################
echo ""

# we feed first the lookups, then the 2nd edr file in..
cp input_data/b${paymenttype_lkp_file} $data_dir/lookup_paymenttype/
cp input_data/b${paymenttype_lkp_file} $data_dir/lookup_paymenttype/b${paymenttype_lkp_file}.done
copy_paymenttypes

cp input_data/b${recurring_lkp_file} $data_dir/lookup_requirring/OUT
cd $data_dir/lookup_requirring/OUT
zip b${recurring_lkp_file}.zip ./b${recurring_lkp_file}
touch b${recurring_lkp_file}.zip.done

echo "sleep 14 before feeding in edr.."
sleep 14

cd $my_loc
rm -f input_data/b${throttle_file}.gz
gzip input_data/b${throttle_file}
cp input_data/b${throttle_file}.gz $data_dir/pcrf_files_${SINGLE_FLOW_TYPE}/

# here is the expected output..
Quota_Total1=$Quota_Usage1
echo "Name#Test;Transaction_ID#${Time31}_${msisdn1}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#${Quota_Total1}.0;Int_3#${InitialVolume3};Yes_No_1#${IsRecurring3};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn1};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time31}_${msisdn2}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#${Quota_Total1}.0;Int_3#${InitialVolume3};Yes_No_1#${IsRecurring3};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn2};" >> $expected_output
echo "Name#Test;Transaction_ID#${Time31}_${msisdn3}_${Quota_Name1}_${Quota_Next_Reset_Time1};Int_1#16;Type#$PaymentType1;Float_1#${Quota_Total1}.0;Int_3#${InitialVolume3};Yes_No_1#${IsRecurring3};String_1#${Quota_Name1};String_2#6;MSISDN#${msisdn3};" >> $expected_output

#######################################################################

echo "stopping the cep components..."
cd $my_loc/$start_stop_dir
./STOP_ALL_CEP.sh

cd $my_loc
################################################################################
echo " "
echo "here is the contents we were looking for.."
cat $expected_output
echo " "
echo "here is the paymenttype lookup we used.."
echo "1st file.."
cat $my_loc/input_data/$paymenttype_lkp_file
echo "2st file.."
cat $my_loc/input_data/a${paymenttype_lkp_file}
echo "3rd file.."
cat $my_loc/input_data/b${paymenttype_lkp_file}
echo " "
echo " "
echo "here is the recurring lookup we used.."
echo "1st file.."
cat $my_loc/input_data/${tc}_input_data_recurring_lkp.txt
echo "2st file.."
cat $my_loc/input_data/a${tc}_input_data_recurring_lkp.txt
echo "3rd file.."
cat $my_loc/input_data/b${tc}_input_data_recurring_lkp.txt
echo " "
echo " "
echo "here is the EDR stream we used.."
echo "1st file.."
gzip -dc $my_loc/input_data/${throttle_file}.gz
echo "2st file.."
gzip -dc $my_loc/input_data/a${throttle_file}.gz
echo "3rd file.."
gzip -dc $my_loc/input_data/b${throttle_file}.gz
echo ""


