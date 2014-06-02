. ./helper.sh
##################################
function setup_input_data1() {
# here we create the input data we want to work with.

# pcrf stream..
rm -fr pcrf_stream.txt
Time1=$(date --date='52 hours ago' +"%Y-%m-%d %T")
Time2=$(date --date='25 hours ago' +"%Y-%m-%d %T"); 
Time2=
Time3=$(date --date='2 seconds ago' +"%Y-%m-%d %T"); 
Time3=hi!
Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T")

## these are the POSTPAID entries..
echo "2,$Time1,,,4912345678901,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_110_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream.txt
echo "2,$Time2,,,4912345678902,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_110_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream.txt
echo "2,$Time3,,,4912345678903,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_110_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream.txt

## these are the PREPAID entries..
echo "2,$Time1,,,4922345678901,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_143_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream.txt
echo "2,$Time2,,,4922345678902,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_143_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream.txt
echo "2,$Time3,,,4922345678903,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_143_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream.txt

## these are the FONIC entries..
echo "2,$Time1,,,4932345678901,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_143_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream.txt
echo "2,$Time2,,,4932345678902,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_143_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream.txt
echo "2,$Time3,,,4932345678903,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_143_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream.txt

# these are the camp stream entries..
rm -fr camp_stream.txt
echo "1,1,4912345678901,Q_110_local_Month,2,3,2014-06-07 10:51:21,2014-05-24 10:51:21" >> camp_stream.txt
echo "2,1,4912345678902,Q_110_local_Month,2,3,2014-06-07 10:51:21,2014-05-24 10:51:21" >> camp_stream.txt
echo "3,1,4912345678903,Q_110_local_Month,2,3,2014-06-07 10:51:21,2014-05-24 10:51:21" >> camp_stream.txt

echo "############################"
echo "preparing pcrf stream.."
rm -fr pcrf_stream.csv
cnt=0
max_cnt=$(wc -l pcrf_stream.txt| awk '{print $1}')
while [ "$cnt" -ne "$max_cnt" ]
do
#  echo "cnt=$cnt"
  cnt=$(( $cnt + 1 ))
  myline=$(head -${cnt} pcrf_stream.txt|tail -1)
  echo "i,n,$myline,${cnt}" >> pcrf_stream.csv
done
rm -fr pcrf_stream.txt
echo "############################"


echo "############################"
echo "preparing camp stream.."
rm -fr camp_stream.csv
cnt=0
max_cnt=$(wc -l camp_stream.txt| awk '{print $1}')
while [ "$cnt" -ne "$max_cnt" ]
do
#  echo "cnt=$cnt"
  cnt=$(( $cnt + 1 ))
  myline=$(head -${cnt} camp_stream.txt|tail -1)
  echo "i,n,$myline" >> camp_stream.csv
  
done
rm -fr camp_stream.txt
echo "############################"

# payment type for POSTPAID..
rm -fr payment_type_POSTPAID.txt
echo "4912345678901,POSTPAID" >> payment_type_POSTPAID.txt
echo "4912345678902,POSTPAID" >> payment_type_POSTPAID.txt
echo "4912345678903,POSTPAID" >> payment_type_POSTPAID.txt

# payment type for PREPAID..
rm -fr payment_type_PREPAID.txt
echo "4922345678901,PREPAID" >> payment_type_PREPAID.txt
echo "4922345678902,PREPAID" >> payment_type_PREPAID.txt
echo "4922345678903,PREPAID" >> payment_type_PREPAID.txt

# payment type for FONIC..
rm -fr payment_type_FONIC.txt
echo "4932345678901,FONIC" >> payment_type_FONIC.txt
echo "4932345678902,FONIC" >> payment_type_FONIC.txt
echo "4932345678903,FONIC" >> payment_type_FONIC.txt

echo "############################"
echo "preparing payment type lkp.."
for i in $(echo POSTPAID PREPAID FONIC)
do
  rm -fr payment_type_${i}.csv 
  cnt=0
  max_cnt=$(wc -l payment_type_${i}.txt| awk '{print $1}')
  while [ "$cnt" -ne "$max_cnt" ]
  do
  #  echo "cnt=$cnt"
    cnt=$(( $cnt + 1 ))
    myline=$(head -${cnt} payment_type_${i}.txt|tail -1)
    echo "p,n,$myline" >> payment_type_${i}.csv
  done
  rm -fr payment_type_${i}.txt
done
echo "############################"

}

##################################
function feed_in1() {

# we feed in the throttle 100 postaid, prepaid and fonic models.
for i in $(echo POSTPAID PREPAID FONIC)
#for i in $(echo PREPAID)
do
  echo "############################"
  echo "feeding in payment type (${i}).."
  $DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/${i}_THROTTLE_EVENT/THROTTLE_EVENT_QUERY/PAIDTYPE_SOURCE_LOOKUP" -b 1 -t csv -f payment_type_${i}.csv
  echo "fed in the following:"
  cat payment_type_${i}.csv
  echo "sleep 2"
  sleep 2
  echo "############################"
  
  echo "############################"
  echo "feeding in pcrf stream (${i}).."
  $DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/${i}_THROTTLE_EVENT/THROTTLE_EVENT_QUERY/PCRF_DATA_USAGE_STREAM" -b 1 -t csv -f pcrf_stream.csv
  echo "fed in the following:"
  cat pcrf_stream.csv
  echo "sleep 2"
  sleep 2
  echo "############################"
done

# we feed in the postpaid second step model.
echo "############################"
echo "feeding in pcrf stream..(POSTPAID_SECOND_STEP)"
$DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/PCRF_DATA_USAGE_STREAM" -b 1 -t csv -f pcrf_stream.csv
echo "fed in the following:"
cat pcrf_stream.csv
echo "sleep 2"
sleep 2
echo "############################"

echo "############################"
echo "feeding in camp stream..(POSTPAID_SECOND_STEP)"
$DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/CAMPAIGN_CONTACT_STREAM" -b 1 -t csv -f camp_stream.csv
echo "fed in the following:"
cat camp_stream.csv
echo "sleep 2"
sleep 2
echo "############################"

###############################################################################
}
###############################################################################
###############################################################################
function setup_input_data2() {

rm -fr pcrf_stream2.txt
Time11=$(date --date='51 hours ago' +"%Y-%m-%d %T")
echo "2,$Time11,,,4912345678901,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_110_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream2.txt
echo "2,$Time11,,,4912345678902,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_110_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream2.txt
echo "2,$Time11,,,4912345678903,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_110_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream2.txt

echo "2,$Time11,,,4922345678901,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_143_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream2.txt
echo "2,$Time11,,,4922345678902,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_143_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream2.txt
echo "2,$Time11,,,4922345678903,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_143_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream2.txt

echo "2,$Time11,,,4932345678901,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_143_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream2.txt
echo "2,$Time11,,,4932345678902,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_143_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream2.txt
echo "2,$Time11,,,4932345678903,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_143_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1" >> pcrf_stream2.txt

rm -fr camp_stream2.txt
echo "11,1,4912345678901,Q_110_local_Month,2,3,2014-06-07 10:51:21,2014-05-24 10:51:21" >> camp_stream2.txt

echo "12,1,4922345678901,Q_110_local_Month,2,3,2014-06-07 10:51:21,2014-05-24 10:51:21" >> camp_stream2.txt

echo "13,1,4932345678901,Q_110_local_Month,2,3,2014-06-07 10:51:21,2014-05-24 10:51:21" >> camp_stream2.txt

echo "############################"
echo "preparing pcrf stream2.."
rm -fr pcrf_stream2.csv
cnt=0
max_cnt=$(wc -l pcrf_stream2.txt| awk '{print $1}')
while [ "$cnt" -ne "$max_cnt" ]
do
#  echo "cnt=$cnt"
  cnt=$(( $cnt + 1 ))
  myline=$(head -${cnt} pcrf_stream2.txt|tail -1)
  echo "i,n,$myline,${cnt}" >> pcrf_stream2.csv
done
echo "############################"


echo "############################"
echo "preparing camp stream2.."
rm -fr camp_stream2.csv
cnt=0
max_cnt=$(wc -l camp_stream2.txt| awk '{print $1}')
while [ "$cnt" -ne "$max_cnt" ]
do
#  echo "cnt=$cnt"
  cnt=$(( $cnt + 1 ))
  myline=$(head -${cnt} camp_stream2.txt|tail -1)
  echo "i,n,$myline" >> camp_stream2.csv
  
done
echo "############################"

}
###############################################################################
##################################
function feed_in2() {

# we feed in the throttle 100 postaid, prepaid and fonic models.
for i in $(echo POSTPAID PREPAID FONIC)
do
  echo "############################"
  echo "feeding in payment type (${i}).."
  $DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/${i}_THROTTLE_EVENT/THROTTLE_EVENT_QUERY/PAIDTYPE_SOURCE_LOOKUP" -b 1 -t csv -f payment_type_${i}.csv
  echo "fed in the following:"
  cat payment_type_${i}.csv
  echo "sleep 2"
  sleep 2
  echo "############################"
  
  echo "############################"
  echo "feeding in pcrf stream (${i}).."
  $DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/${i}_THROTTLE_EVENT/THROTTLE_EVENT_QUERY/PCRF_DATA_USAGE_STREAM" -b 1 -t csv -f pcrf_stream2.csv
  echo "fed in the following:"
  cat pcrf_stream2.csv
  echo "sleep 2"
  sleep 2
  echo "############################"
done

# we feed in the postpaid second step model.
echo "############################"
echo "feeding in pcrf stream (POSTPAID_SECOND_STEP).."
$DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/PCRF_DATA_USAGE_STREAM" -b 1 -t csv -f pcrf_stream2.csv
echo "fed in the following:"
cat pcrf_stream2.csv
echo "sleep 2"
sleep 2
echo "############################"

echo "############################"
echo "feeding in camp stream (POSTPAID_SECOND_STEP).."
$DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/CAMPAIGN_CONTACT_STREAM" -b 1 -t csv -f camp_stream2.csv
echo "fed in the following:"
cat camp_stream2.csv
echo "sleep 2"
sleep 2
echo "############################"

###############################################################################
}
###############################################################################
echo "we test with all 4 models running at the same time"

# now we run everything..
kill_cep

setup_input_data1

start_cep_server

start_cep_model "POSTPAID_THROTTLE_EVENT"
start_cep_model "PREPAID_THROTTLE_EVENT"
start_cep_model "FONIC_THROTTLE_EVENT"
start_cep_model "POSTPAID_SECOND_STEP"

feed_in1

stop_cep_model "POSTPAID_THROTTLE_EVENT"
stop_cep_model "PREPAID_THROTTLE_EVENT"
stop_cep_model "FONIC_THROTTLE_EVENT"
stop_cep_model "POSTPAID_SECOND_STEP"

kill_cep
start_cep_server

start_cep_model "POSTPAID_THROTTLE_EVENT"
start_cep_model "PREPAID_THROTTLE_EVENT"
start_cep_model "FONIC_THROTTLE_EVENT"
start_cep_model "POSTPAID_SECOND_STEP"

setup_input_data2

start_stream_viewer "POSTPAID_THROTTLE_EVENT"
start_stream_viewer "PREPAID_THROTTLE_EVENT"
start_stream_viewer "FONIC_THROTTLE_EVENT"
start_stream_viewer "POSTPAID_SECOND_STEP"

feed_in2




