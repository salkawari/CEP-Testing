###############################################################################
function check_espdata() {

my_loc=$(pwd)

#if [ $(ls -rtl /opt/app/sas|grep ESPData|grep ^d|wc -w) -ne "0" ]
#then
#  echo "dropping folder /opt/app/sas/ESPData"
#  cd /opt/app/sas
#  rm -fr ESPData
#fi
#
#if [ $(ls -rtl /opt/app/sas|grep ESPData|grep ^l|wc -w) -ne "0" ]
#then
#  echo "creating soft link ESPData for /opt/app/sas/ESPData"
#  cd /opt/app/sas
#  ln -s custom/data ESPData
#fi
#

if [ $(ls -rtl /opt/app/sas|grep SASHome94|grep ^d|wc -w) -ne "0" ]
then
  echo "dropping folder /opt/app/sas/SASHome94"
  cd /opt/app/sas
  rm -fr SASHome94
  ln -s $HOME/Desktop/dev SASHome94
fi

if [ $(ls -rtl /opt/app/sas|grep SASHome94|grep ^l|wc -w) -ne "0" ]
then
  echo "creating soft link SASHome94 for ${HOME}/Desktop/dev"
  cd /opt/app/sas
  ln -s $HOME/Desktop/dev SASHome94
fi

if [ $(ls -rtl /opt/app/sas/SASHome94 |grep esp-2.2|wc -w) -eq "0" ]
then
  echo "creating soft link esp-2.2 for /opt/app/sas/SASHome94/2.2-pre"
  cd /opt/app/sas/SASHome94
  ln -s 2.2-pre esp-2.2
fi

cd /opt/app/sas
mkdir -p home/sas/cep-log

cd $my_loc
}
###############################################################################
function ret_line() {
local line_type=$1
local line_num=$2

if [ "$line_type" == "PCRF_EDR" ]
then
  if [ "$line_num" == "1" ]
  then
    echo "$g_TriggerType,$g_Time,$g_SubscriberIdentifier,,$g_msisdn,,,,,";
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
    echo ",,,,,,,$g_Quota_Value";
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
cd start_stop_dir_1key
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
echo "ls -l $postpaid_lkp_dir"
ls -l $postpaid_lkp_dir

echo "cp $paymenttype_lkp_dir/* $prepaid_lkp_dir"
cp $paymenttype_lkp_dir/* $prepaid_lkp_dir
echo "ls -l $prepaid_lkp_dir"
ls -l $prepaid_lkp_dir

echo "cp $paymenttype_lkp_dir/* $fonic_lkp_dir"
cp $paymenttype_lkp_dir/* $fonic_lkp_dir
echo "ls -l $fonic_lkp_dir"
ls -l $fonic_lkp_dir

cd $my_loc
}

###############################################################################
