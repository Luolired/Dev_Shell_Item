#!/bin/bash
#***************************************************************************
# * 
# * @file:DevOps_pinglog.sh 
# * @author:lizx01
# * @date:2016-04-13 10:48 
# * @version 1.2
# * @description: 对上游代理商进行常ping操作,记录我方到对方代理商的网络状况
# * @Copyright (c) 007ka all right reserved 
# * @updatelog: 
# *             1.更新程序标准化逻辑性
# *             2.优化日志的输出
# *	        3.把我方到对方代理商的网络状况输出到日志中
# * 	        4.把DevOps_pinglog.sh nohup /usr/local/007ka/new_sysmon/DevOps_pinglog.sh &> /dev/null &
# * 	        5.把配置文件读成数组
# * 	        6.所有代理商合并成一个日志文件,便于对比分析出本服务器出口网络质量
#**************************************************************************

export LANG=zh_CN.GBK

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

##源IP地址
g_s_SRC_IP=$(ip addr | grep 'inet' | grep "10\.1" | grep -vw 'secondary' | awk -F['/'' '.]+ 'NR==1 {print $3"."$4"."$5"."$6}')

username=apps

###程序运行all日志输出路径
g_s_LOG_PATH=/var/applog/ping

###配置文件路径
g_s_Work_Inc="/usr/local/007ka/new_sysmon/inc/DevOps_pinglog.ini"

### Print error messges eg:  _err "This is error"
function _err()
{
	#echo -e "\033[1;31m[ERROR] $@\033[0m" >&2
	echo -e "\033[1;31m[ERROR] $@\033[0m"
}

### Print notice messages eg: _info "This is Info"
function _info()
{
	#echo -e "\033[1;32m[Info] $@\033[0m" >&2
	echo -e "\033[1;32m[Info] $@\033[0m"
}

if [ ! -f $g_s_Work_Inc ];then
	_err "$g_s_Work_Inc 不存在！"
	exit $STATE_CRITICAL
fi

if [ ! -d $g_s_LOG_PATH ];then
	mkdir -p $g_s_LOG_PATH
fi

### LOG to file  eg:g_fn_LOG "Test"
g_fn_LOG()
{
    s_Ddate=`date +"%F %H:%M:%S"`
    echo "[$s_Ddate] $*" >> $g_s_LOGFILE
}

### 使用引导help
if [ "$#" -eq 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        _info "=========================== Welcome ===================================="
        echo 
        _err "用途:脚本实现本机对多个代理商分别进行常ping操作,记录我方出口到各个代理商的网络状况"
        echo 
        _info "用法(7个参数)：#nohup $0 &> /dev/null &"
        _info "Usage: #nohup $0 &> /dev/null & " >&2
        echo 
        _info "Create Time:2016-12-14,Author:lizx 007ka-soc,V1.0"
        _info "Modified Time:2016-12-14,V1.2 Updatelog:1.日志集中输出到:$g_s_LOG_PATH/ 2.日志每天轮询"
        _info "=========================== Welcome ===================================="
        exit 1
fi

###check the run user
###检测当前用户是否为$username，不是则退出执行
if [ `whoami` == "$username" ];then
    #代理商数组
    ARRAY_PARTNER_MERID=($(cat $g_s_Work_Inc|grep -v "^#"|awk -F '[=]+' '{print $1}'))
    ARRAY_PARTNER_IPADDRESS=($(cat $g_s_Work_Inc|grep -v "^#"|awk -F '[=]+' '{print $2}'))
    while true
    do
        g_s_LOG_FILE="${g_s_LOG_PATH}/ping_back_log-all.$(date +"%F").log"
        for (( i=0;i<"${#ARRAY_PARTNER_MERID[*]}";i++ )) 
        do  
            #_info "${ARRAY_PARTNER_MERID[i]},${ARRAY_PARTNER_IPADDRESS[i]}"
            #pkill -f "/bin/ping -c 1 -w 1 ${ARRAY_PARTNER_IPADDRESS[i]}" || sleep 1
            echo "$(date +'%F %T') src:$g_s_SRC_IP dst:${ARRAY_PARTNER_MERID[i]}===${ARRAY_PARTNER_IPADDRESS[i]} $( /bin/ping -c 1 -w 1 ${ARRAY_PARTNER_IPADDRESS[i]} | sed -n '2p' )" >> $g_s_LOG_FILE &
        done
	sleep 2
    done
else
	_err "非$username用户,退出执行"
	exit $STATE_WARNING
fi
