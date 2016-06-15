#!/bin/bash

# ***************************************************************************
# * 
# * @file:check_web_netstat.sh 
# * @author:Luolired 007ka
# * @date:2016-03-24 09:47 
# * @version 1.0  
# * @description: check_web_netstat.sh Shell script 
# *  Checks #netstat nat |grep :$port |wc -l  and generates WARNING or CRITICAL states
# * @usrage:command[appname]=/etc/nagios/nrpe.d/check_web_netstat.sh $Port $G_Warning_Netstat_Num $G_Critical_Netstat_Num
# * @Copyright (c) 007ka all right reserved 
# * @
#**************************************************************************/ 

export LANG=zh_CN.GBK

#set -x
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

G_Check_Port=$1
G_Warning_Netstat_Num=$2
G_Critical_Netstat_Num=$3

#当前访问量
#netstat -nat |awk '{print $4}'|egrep "[0-9]:80$"
G_Actual_Num=$(netstat -nat |awk '{print $4}'|egrep "[0-9]:${G_Check_Port}$"|wc -l)

if [ "$#" -lt 3 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	echo "PROCS UNKNOWN: args with not recognition commands:$@,Usage:$0 [Check_Port] [Warning_Num] [Critical_Num]" >&2
	exit $STATE_WARNING
else
	#端口和阀值检测
	if [ $(expr match "$G_Check_Port" "[0-9][0-9]*$") -eq "0" -o $(expr match "$G_Warning_Netstat_Num" "[0-9][0-9]*$") -eq "0" -o $(expr match "$G_Critical_Netstat_Num" "[0-9][0-9]*$") -eq "0" ];then
	        echo " PROCS UNKNOWN: args error $G_Check_Port $G_Warning_Netstat_Num $G_Critical_Netstat_Num need Arabic numerals!"
        	exit $STATE_CRITICAL
	fi
fi

#当前访问量大于最大报警阀值
if [ "$G_Actual_Num" -gt "${G_Critical_Netstat_Num}" ];then
	#在访问端口里找出访问数最多的定义为攻击IP
	Access_Max_Ip=$(netstat -nat |awk -F '[ :]+' '$5~/^'$G_Check_Port'$/{++array[$6]};END{for(key in array){print key,array[key] |"sort -nr -k2 | head -n 1"}}')
	echo "PROCS CRITICAL:${G_Check_Port} Port Cureent_Netstat_Num:${G_Actual_Num} larger than that:${G_Critical_Netstat_Num},${Access_Max_Ip} maybed attacked our web!!!"
	exit $STATE_CRITICAL
else
	if [ "$G_Actual_Num" -gt "${G_Warning_Netstat_Num}" ];then
		Access_Max_Ip=$(netstat -nat |awk -F '[ :]+' '$5~/^'$G_Check_Port'$/{++array[$6]};END{for(key in array){print key,array[key] |"sort -nr -k2 | head -n 1"}}')
		echo "PROCS WARGING:${G_Check_Port} Port Cureent_Netstat_Num:${G_Actual_Num} larger than that:${G_Warning_Netstat_Num},${Access_Max_Ip} maybed attacked our web!!!"
		exit $STATE_WARNING
	else
		echo "PROCS OK:${G_Check_Port} Port Cureent_Netstat_Num:${G_Actual_Num} less than that:${G_Warning_Netstat_Num}"
		exit $STATE_OK
	fi
fi
