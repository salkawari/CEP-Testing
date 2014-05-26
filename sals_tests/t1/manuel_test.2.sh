##################################
function setup_input_data() {
# here we create the input data we want to work with.

# pcrf stream..
rm -fr pcrf_stream.txt
Time1=$(date --date='52 hours ago' +"%Y-%m-%d %T")
Time2=$(date --date='25 hours ago' +"%Y-%m-%d %T")
Time3=$(date --date='2 seconds ago' +"%Y-%m-%d %T")
Quota_Next_Reset_Time1=$(date --date='16 days' +"%Y-%m-%d %T")
echo "2,$Time1,,,4912345678901,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_110_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,0" >> pcrf_stream.txt
echo "2,$Time2,,,4912345678902,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_110_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,0" >> pcrf_stream.txt
echo "2,$Time3,,,4912345678903,,,,,,,,,0,,,,,,1.2.3.4,,,,,,,Q_110_local_Month,6,12,,,1024,$Quota_Next_Reset_Time1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,0" >> pcrf_stream.txt

# camp stream..
rm -fr camp_stream.txt
echo "1,1,4912345678901,Q_110_local_Month,2,3,2014-06-07 10:51:21,2014-05-24 10:51:21" >> camp_stream.txt
echo "2,1,4912345678902,Q_110_local_Month,2,3,2014-06-07 10:51:21,2014-05-24 10:51:21" >> camp_stream.txt
echo "3,1,4912345678903,Q_110_local_Month,2,3,2014-06-07 10:51:21,2014-05-24 10:51:21" >> camp_stream.txt

}
##################################
function kill_cep() {
  for i in $(ps aux |grep -i dfesp_xml_server|grep -v grep|awk '{print $2}')
  do
    if [ $(echo $i|wc -w) -ne 0 ]
    then
      echo "killing cep server $i"
      kill -9 $i
    fi
  done

  for i in $(ps aux |grep -i streamviewer|grep -v grep|awk '{print $2}')
  do
    if [ $(echo $i|wc -w) -ne 0 ]
    then
      echo "killing cep streamviewer $i"
      kill -9 $i
    fi
  done
}
##################################

kill_cep
setup_input_data

echo "############################"
echo "starting the cep server"
$DFESP_HOME/bin/dfesp_xml_server -pubsub 55555 -server 55556 -loglevel debug &
echo "sleep 2"
sleep 2
echo "############################"

echo "############################"
echo "starting POSTPAID_SECOND_STEP_load"
$DFESP_HOME/bin/dfesp_xml_client -server localhost:55556 -file POSTPAID_SECOND_STEP_load.xml &
echo "sleep 2"
sleep 2
echo "############################"

echo "############################"
echo "starting POSTPAID_SECOND_STEP_start"
$DFESP_HOME/bin/dfesp_xml_client -server localhost:55556 -file POSTPAID_SECOND_STEP_start.xml &
echo "sleep 2"
sleep 2
echo "############################"

echo "############################"
echo "starting stream viewer.."
java -classpath $DFESP_HOME/lib/dfx-esp-streamviewer.jar:$DFESP_HOME/lib/dfx-esp-api.jar streamviewer.StreamViewer dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/PCRF_DATA_USAGE_STREAM dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/CAMPAIGN_CONTACT_STREAM dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/POSTPAID_THROTTLE_FILTER dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/PCRF_GATHER_24_HOURS_EVENT dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/PCRF_GATHER_24_HOURS_EVENT dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/PCRF_LAST_EVENT dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/CAMPAIGN_CONTACT_STREAM_ADD_LAST_EVENT dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/FILTER_TO_LAZY -initialX 1 -initialY 1 -height 800 -width 600 -height 750 -width 1400 &
echo "sleep 6"
sleep 6
echo "############################"

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
echo "############################"

echo "############################"
echo "feeding in pcrf stream.."
$DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/PCRF_DATA_USAGE_STREAM" -b 1 -t csv -f pcrf_stream.csv
echo "sleep 2"
sleep 2
echo "############################"

echo "############################"
echo "feeding in camp stream.."
$DFESP_HOME/bin/dfesp_fs_adapter -Q -k pub -h "dfESP://localhost:55555/POSTPAID_SECOND_STEP/SECOND_STEP_EVENT_QUERY/CAMPAIGN_CONTACT_STREAM" -b 1 -t csv -f camp_stream.csv
echo "sleep 2"
sleep 2
echo "############################"


