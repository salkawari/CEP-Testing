###############################################################################






function ret_line() {
local line_type=$1
local line_num=$2

if [ "$line_type" == "PCRF_EDR" ]
then
  if [ "$line_num" == "1" ]
  then
    echo "$g_TriggerType,$g_Time,,,$g_msisdn,,,,,";
  elif [ "$line_num" == "2" ]
  then
    echo ",,,$g_SGSNAddress,,,,,,$g_UEIP";
  elif [ "$line_num" == "3" ]
  then
    echo ",,,,,,$g_Quota_Name,$g_Quota_Status,$g_Quota_Consumption,";
  elif [ "$line_num" == "4" ]
  then
    echo ",$g_Quota_Usage,$g_Quota_Next_Reset_Time,,,,,,,";
  elif [ "$line_num" == "5" ]
  then
    echo ",,,,,,,,,";
  elif [ "$line_num" == "6" ]
  then
    echo ",,,,,,,,,";
  elif [ "$line_num" == "7" ]
  then
    echo ",,,,,,,$g_Quota_Value,,";
  fi
fi
}

###############################################################################
function get_flowtype_lower() {
SINGLE_FLOW_TYPE=$(cat SINGLE_FLOW_TYPE.conf|grep -v "#")
echo ${SINGLE_FLOW_TYPE,,}
}

###############################################################################
function get_flowtype_upper() {
SINGLE_FLOW_TYPE=$(cat SINGLE_FLOW_TYPE.conf|grep -v "#")
echo $SINGLE_FLOW_TYPE | tr '[:lower:]' '[:upper:]'
}

###############################################################################
function copy_paymenttypes() {
my_loc=$(pwd)
cd start_stop_dir
postpaid_lkp_dir=$(cat START_STOP_CONFIG.txt|grep -i "postpaid_lkp_dir"|cut -d'=' -f2)
prepaid_lkp_dir=$(cat START_STOP_CONFIG.txt|grep -i "prepaid_lkp_dir"|cut -d'=' -f2)
fonic_lkp_dir=$(cat START_STOP_CONFIG.txt|grep -i "fonic_lkp_dir"|cut -d'=' -f2)

paymenttype_lkp_dir=$(echo "$postpaid_lkp_dir/../lookup_paymenttype")

echo "postpaid_lkp_dir=$postpaid_lkp_dir"
echo "prepaid_lkp_dir=$prepaid_lkp_dir" 
echo "fonic_lkp_dir=$fonic_lkp_dir"
echo "paymenttype_lkp_dir=$paymenttype_lkp_dir"


if [ ! -d "${postpaid_lkp_dir}" ]
then
  mkdir -p $postpaid_lkp_dir
fi

if [ ! -d "${prepaid_lkp_dir}" ]
then
  mkdir -p $prepaid_lkp_dir
fi

if [ ! -d "${fonic_lkp_dir}" ]
then
  mkdir -p $fonic_lkp_dir
fi

echo "cp $paymenttype_lkp_dir/* $postpaid_lkp_dir"
cp $paymenttype_lkp_dir/* $postpaid_lkp_dir
ls -l $postpaid_lkp_dir

echo "cp $paymenttype_lkp_dir/* $prepaid_lkp_dir"
cp $paymenttype_lkp_dir/* $prepaid_lkp_dir
ls -l $postpaid_lkp_dir

echo "cp $paymenttype_lkp_dir/* $fonic_lkp_dir"
cp $paymenttype_lkp_dir/* $fonic_lkp_dir
ls -l $postpaid_lkp_dir

cd $my_loc
}

###############################################################################
