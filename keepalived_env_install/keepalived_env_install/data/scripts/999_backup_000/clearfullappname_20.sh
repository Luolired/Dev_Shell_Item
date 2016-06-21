#!/bin/bash

#***************************************************************************
# * 
# * @file:clearfullappname.sh 
# * @author:Luolired@163.com 
# * @date:2016-01-05 16:26 
# * @version 0.3
# * @description:崻�����Quitָ���޳���Ȼ���ڵ�¼���û�
# *     1.�ű���׼��
# * @Copyright (c) 007ka all right reserved 
# * @updatelog: 
# *             1.���³����׼���߼���
# *             2.�Ż���־�����ָ��
# *             3.Keepalived�����л����ܿ�����
#**************************************************************************/ 

export LANG=zh_CN.GBK

#�����������������ļ�
PRO_CFG_PATH=$(dirname $0)
PRO_CFG="${PRO_CFG_PATH}/pid_backup.ini"
#Keepalived�����л����ܿ������ļ�,���ڽ��������л�,�����ڿ��л�,��������ͬ��
KEEPALIVED_SWITCH_LOCK_FILE="${PRO_CFG_PATH}/keepalived_switch.lock"

### Logding PRO_CFG
G_MOVE_IP=$(grep -Pw "^G_MOVE_IP" $PRO_CFG |awk -F 'G_MOVE_IP=' '{print $NF}')
G_VIP_IP=$(grep -Pw "^G_VIP_IP" $PRO_CFG |awk -F 'G_VIP_IP=' '{print $NF}')
G_LOG_FILE=$(grep -Pw "^PROGRAM_PATH" $PRO_CFG |awk -F 'PROGRAM_PATH=' '{print $NF}'|awk -F '[/]+' '{print $NF}')
G_LOCAL_IP=$(ip addr | grep 'inet' | grep "10\.2" | grep -vw 'secondary' | awk -F ['/ ']+ 'NR==1 {print $3}')

###LOG_PATH
###��������all��־���·��
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

#��ȡ����ip��ַ���һ��
G_LOCAL_IP_LAST=$(echo ${G_LOCAL_IP} |awk -F '.' '{print $NF}')
G_MOVE_IP_LAST=$(echo ${G_MOVE_IP} |awk -F '.' '{print $NF}')

#����pid�ļ��洢·��
LOCAL_DIR=/var/applog/${G_LOCAL_IP_LAST}_pid/
#����pid�洢·��
RSYNC_DIR=/var/applog/${G_MOVE_IP_LAST}_pid/

if [ -f "$KEEPALIVED_SWITCH_LOCK_FILE" ];then
        echo -e "\033[1;31m[ERROR] Keepalived�����л����ܿ���������,���˳�,����Ҫ���Ƴ���,����clearfullappname\033[0m"
        g_fn_LOG "${KEEPALIVED_SWITCH_LOCK_FILE} Keepalived�����л����ܿ���������,���˳�,����Ҫ���Ƴ���,����clearfullappname"
        exit 1                                                                                             
fi  

#����������������fullappname�����ж���˿ڣ���ȫ������
#������ж˿�,������˿��븴������5��
for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.212 -w1 -p6004 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do 
	/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.212 -p6004 -w0 -e "$i Quit"
	g_fn_LOG "10.20.10.212 -p6004 ${i} �����"
	echo "10.20.10.212 -p6004 �����"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.212 -w1 -p6004 �������"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.212 -w1 -p6006 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.212 -p6006 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.212 -p6006 ${i} �����"
        echo "10.20.10.212 -p6006 �����"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.212 -w1 -p6006 �������"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -w1 -p6007 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -p6007 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.000 -p6007 ${i} �����"
        echo "10.20.10.000 -p6007 �����"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.000 -w1 -p6007 �������"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -w1 -p6008 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -p6008 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.000 -p6008 ${i} �����"
        echo "10.20.10.000 -p6008 �����"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.000 -w1 -p6008 �������"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.212 -w1 -p6019 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.212 -p6019 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.212 -p6019 ${i} �����"
        echo "10.20.10.212 -p6019 �����"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.212 -w1 -p6019 �������"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -w1 -p6040 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -p6040 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.000 -p6040 ${i} �����"
        echo "10.20.10.000 -p6040 �����"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.000 -w1 -p6040 �������"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -w1 -p6050 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.000 -p6050 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.000 -p6050 ${i} �����"
        echo "10.20.10.000 -p6050 �����"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.000 -w1 -p6050 �������"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.213 -w1 -p7020 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.213 -p7020 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.213 -p7020 ${i} �����"
        echo "10.20.10.213 -p7020 �����"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.213 -w1 -p7020 �������"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.213 -w1 -p7021 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.213 -p7021 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.213 -p7021 ${i} �����"
        echo "10.20.10.213 -p7021 �����"
done
g_fn_LOG "MsgSrvClient  -h 10.20.10.213 -w1 -p7021 �������"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.213 -w1 -p7022 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.213 -p7022 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.213 -p7022 ${i} �����"
        echo "10.20.10.213 -p7022 �����"
done
g_fn_LOG "MsgSrvClient  -h 10.20.10.213 -w1 -p7022 �������"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.134 -w1 -p6005 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.134 -p6005 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.134 -p6005 ${i} �����"
        echo "10.20.10.134 -p6005 �����"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.134 -w1 -p6005 �������"

for i in `/usr/local/007ka/bin/MsgSrvClient -h 10.20.10.134 -w1 -p6010 -e ". _PrintApp"|grep -v 'bad cmd'|grep ${G_MOVE_IP} | awk -F'|' {'print $2'}|awk {'print $1'}`
do
        /usr/local/007ka/bin/MsgSrvClient -h 10.20.10.134 -p6010 -w0 -e "$i Quit"
        g_fn_LOG "10.20.10.134 -p6010 ${i} �����"
        echo "10.20.10.134 -p6010 �����"
done
g_fn_LOG "MsgSrvClient -h 10.20.10.134 -w1 -p6010 �������"

exit 0
