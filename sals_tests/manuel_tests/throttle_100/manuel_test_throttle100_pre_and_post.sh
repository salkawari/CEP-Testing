. ./helper.sh
##################################
function setup_input_data() {
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

echo "############################"
echo "preparing pcrf stream.."
rm -fr pcrf_stream.csv
touch pcrf_stream.csv
cnt=0
max_cnt=$(wc -l pcrf_stream.txt| awk '{print $1}')
while [ "$cnt" -ne "$max_cnt" ]
do
#  echo "cnt=$cnt"
  cnt=$(( $cnt + 1 ))
  myline=$(head -${cnt} pcrf_stream.txt|tail -1)
  echo "i,n,$myline,${cnt}" >> pcrf_stream.csv
done
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

echo "############################"
echo "preparing payment type lkp.."
for i in $(echo POSTPAID PREPAID)
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
  touch payment_type_${i}.csv.done
done
echo "############################"

}

##################################
function feed_in() {

for i in $(echo POSTPAID PREPAID)
do
  echo "############################"
  echo "feeding in payment type ${i}).."
  $DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/${i}_THROTTLE_EVENT/THROTTLE_EVENT_QUERY/PAIDTYPE_SOURCE_LOOKUP" -b 1 -t csv -f payment_type_${i}.csv
  echo "sleep 2"
  sleep 2
  echo "############################"
  
  echo "############################"
  echo "feeding in pcrf stream (${i}).."
  $DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/${i}_THROTTLE_EVENT/THROTTLE_EVENT_QUERY/PCRF_DATA_USAGE_STREAM" -b 1 -t csv -f pcrf_stream.csv
  echo "sleep 2"
  sleep 2
  echo "############################"
done
###############################################################################
}

# now we run everything..
kill_cep

setup_input_data

start_cep_server

start_cep_model "POSTPAID_THROTTLE_EVENT"
start_cep_model "PREPAID_THROTTLE_EVENT"

start_stream_viewer "POSTPAID_THROTTLE_EVENT"
start_stream_viewer "PREPAID_THROTTLE_EVENT"

feed_in


