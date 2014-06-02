PAYMENT_TYPE=PREPAID
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

## these are the ${PAYMENT_TYPE} entries..
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

# payment type for ${PAYMENT_TYPE}..
rm -fr payment_type_${PAYMENT_TYPE}.txt
echo "4922345678901,${PAYMENT_TYPE}" >> payment_type_${PAYMENT_TYPE}.txt
echo "4922345678902,${PAYMENT_TYPE}" >> payment_type_${PAYMENT_TYPE}.txt
echo "4922345678903,${PAYMENT_TYPE}" >> payment_type_${PAYMENT_TYPE}.txt


echo "############################"
echo "preparing payment type lkp.."
rm -fr payment_type_${PAYMENT_TYPE}.csv 
cnt=0
max_cnt=$(wc -l payment_type_${PAYMENT_TYPE}.txt| awk '{print $1}')
while [ "$cnt" -ne "$max_cnt" ]
do
#  echo "cnt=$cnt"
  cnt=$(( $cnt + 1 ))
  myline=$(head -${cnt} payment_type_${PAYMENT_TYPE}.txt|tail -1)
  echo "p,n,$myline" >> payment_type_${PAYMENT_TYPE}.csv
done
touch payment_type_${PAYMENT_TYPE}.csv.done
echo "############################"

}

##################################
function feed_in() {

echo "############################"
echo "feeding in payment type ${PAYMENT_TYPE}).."
$DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/${PAYMENT_TYPE}_THROTTLE_EVENT/THROTTLE_EVENT_QUERY/PAIDTYPE_SOURCE_LOOKUP" -b 1 -t csv -f payment_type_${PAYMENT_TYPE}.csv
echo "sleep 2"
sleep 2
echo "############################"

echo "############################"
echo "feeding in pcrf stream (${PAYMENT_TYPE}).."
$DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/${PAYMENT_TYPE}_THROTTLE_EVENT/THROTTLE_EVENT_QUERY/PCRF_DATA_USAGE_STREAM" -b 1 -t csv -f pcrf_stream.csv
echo "sleep 2"
sleep 2
echo "############################"
###############################################################################
}

# now we run everything..
kill_cep

setup_input_data

start_cep_server

start_cep_model "${PAYMENT_TYPE}_THROTTLE_EVENT"

start_stream_viewer "${PAYMENT_TYPE}_THROTTLE_EVENT"

feed_in


