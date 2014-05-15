#! /bin/bash

# This script monitors the memory usage.

while ( true ); do

        mypid=$(ps aux|grep -i dfesp_xml_server|grep $LOGNAME|grep -v grep|awk '
{print $2}')

        if [ $(echo ${mypid}|wc -w) -eq 0 ]
        then
            echo $(date +'%Y%m%d%H%M%S')': ' >> memlog.log
            sleep 60
        else
            echo $(date +'%Y%m%d%H%M%S')': '$(ps -p $mypid -o "pid vsz rss size
pmem pcpu comm") | tail -1 >> memlog.log
            sleep 60
        fi

done
