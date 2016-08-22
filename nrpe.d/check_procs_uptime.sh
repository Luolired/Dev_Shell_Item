#!/bin/bash
# ***************************************************************************
# * 
# * @file:check_proc_uptime.sh
# * @author:Luolired@163.com 
# * @date:2016-08-16 20:53 
# * @version 1.0
# * @description:本脚本用于检测应用程序或服务运行时间,从侧面来推断程序是否频繁重启或首次启动
# * @Copyright (c) 007ka all right reserved 
# * @updatelog:
# *             1.遍历整个ps结果,无须挨个添加注册,检查程序的启动时间,判断为是否是首次启动或者频繁重启
# *             2.修复致命bug,根据实际响应进行匹配获取对应单位天、小时、分钟
# * @example:command[check_procs_uptime]=/etc/nagios/nrpe.d/check_procs_uptime.sh 5 
#**************************************************************************/ 

export LANG=zh_CN.GBK

#set -x
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

Tmp_Check_Procs_Result=/tmp/check_procs_uptime.tmp

if [ "$1" == "" ]
then
	echo -e "\n Syntax: $0 processos Critical \nex.: $0  tomcat.classificados 90 \n Check process uptime and alerts if was restared\n"
	exit $STATE_UNKNOWN
fi

#阀值
CRIT=$1
i=1
PROGRAM_USER=apps

#待检测的结果,输出到临时变量
ps axo user,pid,etime,command | grep ^${PROGRAM_USER} |grep "/usr/local/007ka"| grep -vw "grep\|vim\|vi\|mv\|cp\|scp\|cat\|dd\|tail\|head\|script\|ls\|echo\|sys_log\|logger\|tar\|rsync\|ssh\|run\|sup_run\|inotifywait\|new_sysmon" > $Tmp_Check_Procs_Result
Check_Procs_Total=$(cat $Tmp_Check_Procs_Result | wc -l)

if [ $Check_Procs_Total -gt 0 ]
then
	#apps     35628  6-22:49:41 java -server -Xms128m -Xmx128m -jar /usr/local/007ka/TelecomExchangeCard/TelecomExchangeCard.jar
	cat $Tmp_Check_Procs_Result | while read line
	do
		TIME=$(echo $line | awk '{print $3}')
		# FORMAT 28-03:27:2
		if [[ $TIME == *"-"* ]]
		then
			D=`echo $TIME|awk -F"-" '{ print $1 }'`
			H=`echo $TIME|awk -F":" '{ print $1 }'|awk -F"-" '{ print $NF }'`
			M=`echo $TIME|awk -F":" '{ print $2 }'`
		elif [[ $TIME == *":"*":"* ]]
		then		
			#apps     62835    01:43:46 java -server -Xms64m -Xmx64m -jar 
			D=0
			H=`echo $TIME|awk -F":" '{ print $1 }'`
			M=`echo $TIME|awk -F":" '{ print $2 }'`
		else
			#apps     25531       29:54 java -server -Xms128m -Xmx128m -jar
			D=0
			H=0
			M=`echo $TIME|awk -F":" '{ print $1 }'`
		fi
		#echo "Day:$D Hour:$H Min:$M"
		 
		# CONVERT DAYS TO MIN
		D=`expr $D \* 1440`
		# CONVERT HOURS TO MIN
		H=`expr $H \* 60`
		CTIME=`expr $M + $H`
		if [ ! -z "$D" ]; then
			CTIME=`expr $CTIME + $D`
		fi
		#echo $CTIME
		# CLEANUP
		TIME=`echo ${TIME} | sed -e 's/^[ \t]*//'`
		
		if [ "$CTIME" -lt "$CRIT" ];then
			Program_line=$(echo $line | awk '{print $NF}')
			Program_pid=$(echo $line | awk '{print $2}')
			echo "CRITICAL - Process $Program_pid $Program_line uptime is $TIME (dias-hrs) little $CRIT min|uptime=$CTIME"
			exit $STATE_CRITICAL
		else
			if [ $i -eq $Check_Procs_Total ];then 
				#检测到为最后一个
				echo "OK Process all_total:$i uptime is larger than $CRIT min,Process all not restart"
				exit $STATE_OK
			fi
		fi
		let i++
	done
else
	echo "WARANG - Nagios plugins $0 is Not Check Result:$Tmp_Check_Procs_Result,Please Check"
	exit $STATE_WARNING
fi
rm -rf $Tmp_Check_Procs_Result &>/dev/null
