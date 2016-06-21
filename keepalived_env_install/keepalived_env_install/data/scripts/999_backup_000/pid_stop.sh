#!/bin/bash

#***************************************************************************
# * 
# * @file:pid_stop.sh 
# * @author:soc
# * @date:2016-01-05 16:26 
# * @version 0.5
# * @description:#�ڵ��˳�ʱ���õĽű�
# *     1.notify_stop "/etc/keepalived/scripts/pid_stop.sh"
# * @Copyright (c) 007ka all right reserved 
# * @updatelog: 
# *             1.���³����׼���߼���
# *             2.stop ����/����Ӧ�ú���
# *             3.����ͬ����״̬��ʶ����������ͬ������
# *             4.����Keepalived�����л����ܿ����������Գ�ʼ��������ռ�����࿪��Stopԭ��ҵ��
#**************************************************************************/ 

export LANG=zh_CN.GBK

#�����������������ļ�
PRO_CFG_PATH=$(dirname $0)
PRO_CFG="${PRO_CFG_PATH}/pid_backup.ini"
#Keepalived�����л����ܿ������ļ�,���ڽ��������л�,�����ڿ��л�,��������ͬ��
KEEPALIVED_SWITCH_LOCK_FILE="${PRO_CFG_PATH}/keepalived_switch.lock"
#ͬ�����ļ�,���ڲ�����ͬ��,�����������ͬ��,��������ͬ��
RSYNC_PID_LOCK_FILE="${PRO_CFG_PATH}/rsync_pid.lock"

### Logding PRO_CFG
G_MOVE_IP=$(grep -Pw "^G_MOVE_IP" $PRO_CFG |awk -F 'G_MOVE_IP=' '{print $NF}')
G_VIP_IP=$(grep -Pw "^G_VIP_IP" $PRO_CFG |awk -F 'G_VIP_IP=' '{print $NF}')
G_LOG_FILE=$(grep -Pw "^PROGRAM_PATH" $PRO_CFG |awk -F 'PROGRAM_PATH=' '{print $NF}'|awk -F '[/]+' '{print $NF}')
G_LOCAL_IP=$(ip addr | grep 'inet' | grep "10\.2" | grep -vw 'secondary' | awk -F ['/ ']+ 'NR==1 {print $3}')
PROGRAM_PATH=$(grep -Pw "^PROGRAM_PATH" $PRO_CFG |awk -F 'PROGRAM_PATH=' '{print $NF}')

#������·����/$������޳����/�ַ�,��֤·����ȷ��
echo $PROGRAM_PATH | grep -q '/$' && PROGRAM_PATH=$(echo $PROGRAM_PATH|sed 's/\/$//')

if [ -z $G_LOCAL_IP ]
then
        echo "$G_LOCAL_IP not found!please check bond0"
        exit 1
fi

###LOG_PATH
###��������all��־���·��
g_s_LOG_PATH=/var/applog/${G_LOG_FILE}

mkdir -p $g_s_LOG_PATH
g_s_LOGDATE=`date +"%F"`
#ִ�нű����ɵ���־all
g_s_LOGFILE="${g_s_LOG_PATH}/pid_stop.${g_s_LOGDATE}.log"
### LOG to file  eg:g_fn_LOG "Test"
g_fn_LOG()
{
    s_Ddate=`date +"%F %H:%M:%S"`
    echo "[$s_Ddate] $*" >> $g_s_LOGFILE
}

#��ȡ����ip��ַ���һ��
G_LOCAL_IP_LAST=$(echo ${G_LOCAL_IP} |awk -F '.' '{print $NF}')
#��ȡ�Զ�ip��ַ���һ��
G_MOVE_IP_LAST=$(echo ${G_MOVE_IP} |awk -F '.' '{print $NF}')

#����pid�ļ��洢·��
LOCAL_DIR=/var/applog/${G_LOCAL_IP_LAST}_pid/
#Ϊ��������������ϵ�ĶԶ�PID�ļ�Ŀ¼
MOVE_DIR=/var/applog/${G_MOVE_IP_LAST}_pid/

#�ر�Stop����Ӧ��
Stop_Local_Prog()
{
	g_fn_LOG "$G_LOCAL_IP �ڵ��˳�ʱ���õĽű� һ���رձ������� Start"
        #��ǰ������ͬ��
	touch $RSYNC_PID_LOCK_FILE &> /dev/null
        if [ -f $RSYNC_PID_LOCK_FILE ];then
                g_fn_LOG "[SUCCESS] $RSYNC_PID_LOCK_FILE PIDʵʱͬ�������ɹ�,������ͬ��!!!"
        else
                g_fn_LOG "[ERROR] $RSYNC_PID_LOCK_FILE PIDʵʱͬ������ʧ��,�Կ�ͬ��"
        fi
        if [ ! -d $LOCAL_DIR ];then
                echo -e "\n\033[33m\033[01m$LOCAL_DIR does not exist!\033[0m"
                g_fn_LOG "$LOCAL_DIR does not exist!"
                exit 1
        else
       		 for i in `find $LOCAL_DIR -name "*.pid"`
       		 do
       		         RUN_FILE=`cat $i |grep PATH|cut -d= -f2|sed 's/$/\/run.sh/'`
       		         if [ ! -e $RUN_FILE ];then
       		                 echo -e "\n\033[33m\033[01m$RUN_FILE does not exist!\033[0m"
       		                 g_fn_LOG "\n$RUN_FILE does not exist!"
       		         else
       		                 #echo "$RUN_FILE stop"
       		                 $RUN_FILE stop
       		                 if [ $? -eq 0 ];then
       		                         g_fn_LOG "$RUN_FILE stop ִ�гɹ�"
       		                 else
       		                         g_fn_LOG "$RUN_FILE stop ִ��ʧ��"
       		                 fi
       		         fi
       		 	echo -e '\n'
       		 done
        fi
	g_fn_LOG "$G_LOCAL_IP �ڵ��˳�ʱ���õĽű� һ���رձ������� End"
}

#�رնԶ˻�Ӧ��
Stop_Move_Prog()
{
        g_fn_LOG "$G_LOCAL_IP �ڵ��˳�ʱ���õĽű� һ���رնԶ˻�$G_MOVE_IP���� Start"
	#��ǰ������ͬ��
        touch $RSYNC_PID_LOCK_FILE &> /dev/null
        if [ -f $RSYNC_PID_LOCK_FILE ];then
                g_fn_LOG "[SUCCESS] $RSYNC_PID_LOCK_FILE PIDʵʱͬ�������ɹ�,������ͬ��!!!"
        else
                g_fn_LOG "[ERROR] $RSYNC_PID_LOCK_FILE PIDʵʱͬ������ʧ��,�Կ�ͬ��"
        fi
	if [ ! -d $MOVE_DIR ];then
                echo -e "\n\033[33m\033[01m$MOVE_DIR does not exist!\033[0m"
                g_fn_LOG "$MOVE_DIR does not exist!"
                exit 1
        else
                 for i in `find $MOVE_DIR -name "*.pid"`
                 do
                         RUN_FILE=`cat $i |grep PATH|cut -d= -f2|sed 's/$/\/run.sh/'`
                         if [ ! -e $RUN_FILE ];then
                                 echo -e "\n\033[33m\033[01m$RUN_FILE does not exist!\033[0m"
                                 g_fn_LOG "\n$RUN_FILE does not exist!"
                         else
                                 #echo "$RUN_FILE stop"
                                 $RUN_FILE stop
                                 if [ $? -eq 0 ];then
                                         g_fn_LOG "$RUN_FILE stop �Զ˳���ر�ִ�гɹ�"
                                 else
                                         g_fn_LOG "$RUN_FILE stop �Զ˳���ر�ִ��ʧ��"
                                 fi
                         fi
                        echo -e '\n'
                 done
        fi
        g_fn_LOG "$G_LOCAL_IP �ڵ��˳�ʱ���õĽű� һ���رնԶ˻�$G_MOVE_IP���� End"
}

main(){
	g_fn_LOG "========================================================================"
	if [ ! -f "$KEEPALIVED_SWITCH_LOCK_FILE" ];then
		#��������,����ִ���л�,����Ϊ�ڵ��˳�ʱ���õĽű�
		#notify_stop "/etc/keepalived/scripts/pid_stop.sh"
		#һ��һ����ִ��Stop_Local_Prog;��������һ������ִ��Stop_Move_Prog
		Stop_Local_Prog
		#Stop_Move_Prog
	else		
		echo -e "\033[1;31m[ERROR] Keepalived�����л����ܿ���������,����Ҫ���Ƴ���,����Stop_Local_Prog\033[0m"  
                g_fn_LOG "[ERROR] ${KEEPALIVED_SWITCH_LOCK_FILE} Keepalived�����л����ܿ���������,����Ҫ���Ƴ���,����Stop_Local_Prog"
		exit 1
	fi
	g_fn_LOG "========================================================================"
	exit 0
}
main
