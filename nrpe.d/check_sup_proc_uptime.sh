#!/bin/bash
# ***************************************************************************
# * 
# * @file:check_sup_proc_uptime.sh
# * @author:Luolired@163.com 
# * @date:2016-03-14 20:53 
# * @version 0.2
# * @description:本脚本用于 接单耗时分析:根据007卡订单号截取日志，便于管理员分析接单超时环节
# * @Copyright (c) 007ka all right reserved 
# * @updatelog:
# *             1.更新逻辑,修复零点时刻多个文件,取find 3分钟更改过的文件最后一行即为最新的文件
# *             2.更新逻辑,修复bug SlowInt 类型本地用grep,异地ssh 则需要egrep -o "[0-9]\+
# *  [特别注意] Nagios 需要有权限执行:supervisorctl status 才可以使用本插件
# *  [特别注意] command[check_proc_uptime]=/etc/nagios/nrpe.d/check_sup_proc_uptime.sh 5
#**************************************************************************/ 

export LANG=zh_CN.GBK

#set -x
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

Sup_Clit_Cmd=/usr/bin/supervisorctl

if [ "$1" == "" ]
then
	echo -e "\n Syntax: $0 processos Critical \nex.: $0  tomcat.classificados 90 \n Check process uptime and alerts if was restared\n"
	exit $STATE_UNKNOWN
fi

#阀值
CRIT=$1
i=1
#待检测的总数
Check_Procs_Total=$(sudo $Sup_Clit_Cmd status | grep "RUNNING"|wc -l)

#HEBB2CRefund                     RUNNING    pid 63131, uptime 6 days, 3:41:03
$Sup_Clit_Cmd status | grep "RUNNING" | while read line
do
	Program_line=$(echo $line |grep "RUNNING" |awk '{print $1}')
	TIME=$(echo $line |grep "RUNNING" |awk -F 'uptime' '{print $NF}')
	# FORMAT 28-03:27:2
	# FORMAT  6 days, 3:41:03
	# GET MINUTES
	M=`echo $TIME|awk -F":" '{ print $2 }'`
	 
	# GET DAYS (ONLY IF THERE)
	if [[ $TIME == *"days,"* ]]
	then
		D=`echo $TIME|awk -F 'days' '{ print $1 }'`
		H=`echo $TIME|awk -F":" '{ print $1 }'|awk '{ print $NF }'`
		# CONVERT DAYS TO MIN
		D=`expr $D \* 1440`
	else
		H=`echo $TIME|awk -F":" '{ print $1 }'`
	fi
	 
	# CONVERT HOURS TO MIN
	H=`expr $H \* 60`
	#echo "D: $D H: $H M: $M"
	CTIME=`expr $M + $H`
	 
	if [ ! -z "$D" ]; then
	    CTIME=`expr $CTIME + $D`
	fi
	# CLEANUP
	TIME=`echo ${TIME} | sed -e 's/^[ \t]*//'`
	 
	MSG="Process $Program_line uptime is $TIME (dias-hrs) $CTIME min|uptime=$CTIME"
	if [ "$CTIME" -lt "$CRIT" ];then
		echo "CRITICAL - $MSG"
		exit $STATE_CRITICAL
	else
		if [ $i -eq $Check_Procs_Total ];then 
			#检测到为最后一个
			echo "OK Process all uptime is larger than $CRIT min."
			exit $STATE_OK
		fi
	fi
	let i++
done 
