#!/bin/bash

#***************************************************************************
# * 
# * @file:rsync_pid.sh
# * @author:soc
# * @date:2016-01-25 16:26 
# * @version 0.2
# * @description: Inotifyʵʱ���ͬ��PID�ű�
# *     1.������PidĿ¼��ͬ��
# * @Copyright (c) 007ka all right reserved 
# * @updatelog: 
# *             1.���³����׼���߼���,PIDͬ��
#*************************************************************************** 

export LANG=zh_CN.GBK

#�����������������ļ�
PRO_CFG_PATH=$(dirname $0)
PRO_CFG="${PRO_CFG_PATH}/pid_backup.ini"
RSYNC_PID_LOCK_FILE="${PRO_CFG_PATH}/rsync_pid.lock"

### Logding PRO_CFG
G_MOVE_IP=$(grep -Pw "^G_MOVE_IP" $PRO_CFG |awk -F 'G_MOVE_IP=' '{print $NF}')
G_Central_IP=$(grep -Pw "^G_Central_IP" $PRO_CFG |awk -F 'G_Central_IP=' '{print $NF}')
G_VIP_IP=$(grep -Pw "^G_VIP_IP" $PRO_CFG |awk -F 'G_VIP_IP=' '{print $NF}')
G_LOG_FILE=$(grep -Pw "^PROGRAM_PATH" $PRO_CFG |awk -F 'PROGRAM_PATH=' '{print $NF}'|awk -F '[/]+' '{print $NF}')
G_LOCAL_IP=$(ip addr | grep 'inet' | grep "10\.2" | grep -vw 'secondary' | awk -F ['/ ']+ 'NR==1 {print $3}')
PROGRAM_PATH=$(grep -Pw "^PROGRAM_PATH" $PRO_CFG |awk -F 'PROGRAM_PATH=' '{print $NF}')

#������·����/$������޳����/�ַ�,��֤·����ȷ��
echo $PROGRAM_PATH | grep -q '/$' && PROGRAM_PATH=$(echo $PROGRAM_PATH|sed 's/\/$//')

if [ -z $G_LOCAL_IP ]
then
        echo "G_LOCAL_IP not found!please check bond0"
        exit 1
fi

###LOG_PATH
###��������all��־���·��
g_s_LOG_PATH=/var/applog/${G_LOG_FILE}

mkdir -p $g_s_LOG_PATH
g_s_LOGDATE=`date +"%F"`
#ִ�нű����ɵ���־
g_s_LOGFILE="${g_s_LOG_PATH}/rsync_pid.${g_s_LOGDATE}.log"
### LOG to file  eg:g_fn_LOG "Test"
g_fn_LOG()
{
    s_Ddate=`date +"%F %H:%M:%S"`
    echo "[$s_Ddate] $*" >> $g_s_LOGFILE
}

[ `whoami` = "apps" ] || {
        echo "�û���apps,�˳�!"
        exit 1
}

#��ȡ����ip��ַ���һ��
G_LOCAL_IP_LAST=$(echo ${G_LOCAL_IP} |awk -F '.' '{print $NF}')

#����pid�ļ��洢·��
LOCAL_DIR=/var/applog/${G_LOCAL_IP_LAST}_pid
#�������ǰ��ͬ��һ��
g_fn_LOG "| ��ʼ���ǰ�ĵ�һ��ͬ�� First"
rsync -vzrtopgHl --progress --delete ${LOCAL_DIR} apps@${G_MOVE_IP}:/var/applog >> $g_s_LOGFILE
rsync -vzrtopgHl --progress --delete ${LOCAL_DIR} apps@${G_Central_IP}:/var/applog >> $g_s_LOGFILE

g_fn_LOG "| ��ʼ��� ${LOCAL_DIR} �仯 Welcome"
#ͬ�����ļ��������򲻽���ͬ��,��������ͬ��,��ֻͬ��*.pid�ļ�
/usr/bin/inotifywait -mrq --timefmt '%y-%m-%d %H:%M' --format '%T %w%f %e' --exclude '(^.+\.[^pid]$|.*/*\.swp|.*/*\.svn|.*/*\.log|.*/*\.swx|.*/*\.col|.*/*\.bak|.*/*~|.*/log/.*|.*/hist.log/.*|.*/logs/.*)' -e close_write,delete,create,attrib,move ${LOCAL_DIR} |while read file
do
	if [ ! -f ${RSYNC_PID_LOCK_FILE} ];then
                g_fn_LOG "| EVENT $file ��ص��ļ��б仯,��ͬ����������,׼����ʼͬ��"
                for Tmp_Ip in $G_MOVE_IP $G_Central_IP
                do
                        g_fn_LOG "| START SEND TO ${Tmp_Ip}"
                        rsync -vzrtopgHl --progress --delete ${LOCAL_DIR} apps@${Tmp_Ip}:/var/applog >> $g_s_LOGFILE
			#rsync -vzrtopgHl --progress --rsync-path="mkdir -p ${LOCAL_DIR} && rsync" --delete ${LOCAL_DIR}/*.pid apps@${Tmp_Ip}:${LOCAL_DIR} >> $g_s_LOGFILE
                        g_fn_LOG "| END SEND TO ${Tmp_Ip}"
                done
	else
        	g_fn_LOG "| ${RSYNC_PID_LOCK_FILE} ͬ�����ļ�����,���˳�ͬ�� GoodBye"
        	exit 1
	fi
done
exit 0
