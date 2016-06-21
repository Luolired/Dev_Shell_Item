#!/bin/bash

#***************************************************************************
# * 
# * @file:clearfullappname.sh 
# * @author:Luolired@163.com 
# * @date:2016-01-05 16:26 
# * @version 0.3
# * @description:宕机后发送Quit指令剔除仍然还在登录的用户
# *     1.脚本标准化
# * @Copyright (c) 007ka all right reserved 
# * @updatelog: 
# *             1.更新程序标准化逻辑性
# *             2.优化日志的输出指引
# *             3.Keepalived主备切换功能开启锁
#**************************************************************************/ 

export LANG=zh_CN.GBK

#程序启动配置配置文件
PRO_CFG_PATH=$(dirname $0)
PRO_CFG="${PRO_CFG_PATH}/pid_backup.ini"
#Keepalived主备切换功能开启锁文件,存在将不进行切换,不存在可切换,即加锁不同步
KEEPALIVED_SWITCH_LOCK_FILE="${PRO_CFG_PATH}/keepalived_switch.lock"

### Logding PRO_CFG
G_MOVE_IP=$(grep -Pw "^G_MOVE_IP" $PRO_CFG |awk -F 'G_MOVE_IP=' '{print $NF}')
G_VIP_IP=$(grep -Pw "^G_VIP_IP" $PRO_CFG |awk -F 'G_VIP_IP=' '{print $NF}')
G_LOG_FILE=$(grep -Pw "^PROGRAM_PATH" $PRO_CFG |awk -F 'PROGRAM_PATH=' '{print $NF}'|awk -F '[/]+' '{print $NF}')
G_LOCAL_IP=$(ip addr | grep 'inet' | grep "10\.2" | grep -vw 'secondary' | awk -F ['/ ']+ 'NR==1 {print $3}')

###LOG_PATH
###程序运行all日志输出路径
g_s_LOG_PATH=/var/applog/${G_LOG_FILE}

mkdir -p $g_s_LOG_PATH
g_s_LOGDATE=`date +"%F"`
g_s_LOGFILE="${g_s_LOG_PATH}/clearfullappname.${g_s_LOGDATE}.log"
### LOG to file  eg:g_fn_LOG "Test"
g_fn_LOG()
{
    s_Ddate=`date +"%F %H:%M:%S"`
    echo "[$s_Ddate] $*" >> $g_s_LOGFILE
}

if [ -z $G_LOCAL_IP ]
then
        echo "G_LOCAL_IP not found!please check bond0"
        exit 1
fi

#获取本机ip地址最后一段
G_LOCAL_IP_LAST=$(echo ${G_LOCAL_IP} |awk -F '.' '{print $NF}')
G_MOVE_IP_LAST=$(echo ${G_MOVE_IP} |awk -F '.' '{print $NF}')

#本机pid文件存储路径
LOCAL_DIR=/var/applog/${G_LOCAL_IP_LAST}_pid/
#备份pid存储路径
RSYNC_DIR=/var/applog/${G_MOVE_IP_LAST}_pid/

if [ -f "$KEEPALIVED_SWITCH_LOCK_FILE" ];then
        echo -e "\033[1;31m[ERROR] Keepalived主备切换功能开启锁存在,将退出,若需要请移除锁,方可clearfullappname\033[0m"
        g_fn_LOG "${KEEPALIVED_SWITCH_LOCK_FILE} Keepalived主备切换功能开启锁存在,将退出,若需要请移除锁,方可clearfullappname"
        exit 1                                                                                             
fi  

#清除主机程序残留的fullappname，如有多个端口，请全部定义
#清除所有端口,若多个端口请复制以下5行
for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.212 -w1 -p6004 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do 
	/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.212 -p6004 -w0 -e "$i Quit"
	g_fn_LOG "10.20.10.212 -p6004 ${i} 已清除"
	echo "10.20.10.212 -p6004 已清除"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.212 -w1 -p6004 检索完毕"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.212 -w1 -p6006 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.212 -p6006 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.212 -p6006 ${i} 已清除"
        echo "10.20.10.212 -p6006 已清除"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.212 -w1 -p6006 检索完毕"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -w1 -p6007 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -p6007 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.000 -p6007 ${i} 已清除"
        echo "10.20.10.000 -p6007 已清除"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.000 -w1 -p6007 检索完毕"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -w1 -p6008 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -p6008 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.000 -p6008 ${i} 已清除"
        echo "10.20.10.000 -p6008 已清除"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.000 -w1 -p6008 检索完毕"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.212 -w1 -p6019 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.212 -p6019 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.212 -p6019 ${i} 已清除"
        echo "10.20.10.212 -p6019 已清除"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.212 -w1 -p6019 检索完毕"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -w1 -p6040 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -p6040 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.000 -p6040 ${i} 已清除"
        echo "10.20.10.000 -p6040 已清除"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.000 -w1 -p6040 检索完毕"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -w1 -p6050 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -p6050 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.000 -p6050 ${i} 已清除"
        echo "10.20.10.000 -p6050 已清除"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.000 -w1 -p6050 检索完毕"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.213 -w1 -p7020 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.213 -p7020 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.213 -p7020 ${i} 已清除"
        echo "10.20.10.213 -p7020 已清除"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.213 -w1 -p7020 检索完毕"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.213 -w1 -p7021 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.213 -p7021 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.213 -p7021 ${i} 已清除"
        echo "10.20.10.213 -p7021 已清除"
done
g_fn_LOG "MsgSrvClient  -h 10.20.10.213 -w1 -p7021 检索完毕"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.213 -w1 -p7022 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.213 -p7022 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.213 -p7022 ${i} 已清除"
        echo "10.20.10.213 -p7022 已清除"
done
g_fn_LOG "MsgSrvClient  -h 10.20.10.213 -w1 -p7022 检索完毕"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.134 -w1 -p6005 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.134 -p6005 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.134 -p6005 ${i} 已清除"
        echo "10.20.10.134 -p6005 已清除"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.134 -w1 -p6005 检索完毕"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.134 -w1 -p6010 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.134 -p6010 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.134 -p6010 ${i} 已清除"
        echo "10.20.10.134 -p6010 已清除"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.134 -w1 -p6010 检索完毕"

exit 0
