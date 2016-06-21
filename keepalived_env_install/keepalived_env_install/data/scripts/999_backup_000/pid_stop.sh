#!/bin/bash

#***************************************************************************
# * 
# * @file:pid_stop.sh 
# * @author:soc
# * @date:2016-01-05 16:26 
# * @version 0.5
# * @description:#节点退出时调用的脚本
# *     1.notify_stop "/etc/keepalived/scripts/pid_stop.sh"
# * @Copyright (c) 007ka all right reserved 
# * @updatelog: 
# *             1.更新程序标准化逻辑性
# *             2.stop 本机/本机应用函数
# *             3.增加同步锁状态标识，用以区分同步开启
# *             4.增加Keepalived主备切换功能开启锁，用以初始化启动抢占操作多开或Stop原有业务
#**************************************************************************/ 

export LANG=zh_CN.GBK

#程序启动配置配置文件
PRO_CFG_PATH=$(dirname $0)
PRO_CFG="${PRO_CFG_PATH}/pid_backup.ini"
#Keepalived主备切换功能开启锁文件,存在将不进行切换,不存在可切换,即加锁不同步
KEEPALIVED_SWITCH_LOCK_FILE="${PRO_CFG_PATH}/keepalived_switch.lock"
#同步锁文件,存在不进行同步,不存在则进行同步,即加锁不同步
RSYNC_PID_LOCK_FILE="${PRO_CFG_PATH}/rsync_pid.lock"

### Logding PRO_CFG
G_MOVE_IP=$(grep -Pw "^G_MOVE_IP" $PRO_CFG |awk -F 'G_MOVE_IP=' '{print $NF}')
G_VIP_IP=$(grep -Pw "^G_VIP_IP" $PRO_CFG |awk -F 'G_VIP_IP=' '{print $NF}')
G_LOG_FILE=$(grep -Pw "^PROGRAM_PATH" $PRO_CFG |awk -F 'PROGRAM_PATH=' '{print $NF}'|awk -F '[/]+' '{print $NF}')
G_LOCAL_IP=$(ip addr | grep 'inet' | grep "10\.2" | grep -vw 'secondary' | awk -F ['/ ']+ 'NR==1 {print $3}')
PROGRAM_PATH=$(grep -Pw "^PROGRAM_PATH" $PRO_CFG |awk -F 'PROGRAM_PATH=' '{print $NF}')

#若配置路径是/$则进行剔除最后/字符,保证路径正确性
echo $PROGRAM_PATH | grep -q '/$' && PROGRAM_PATH=$(echo $PROGRAM_PATH|sed 's/\/$//')

if [ -z $G_LOCAL_IP ]
then
        echo "$G_LOCAL_IP not found!please check bond0"
        exit 1
fi

###LOG_PATH
###程序运行all日志输出路径
g_s_LOG_PATH=/var/applog/${G_LOG_FILE}

mkdir -p $g_s_LOG_PATH
g_s_LOGDATE=`date +"%F"`
#执行脚本生成的日志all
g_s_LOGFILE="${g_s_LOG_PATH}/pid_stop.${g_s_LOGDATE}.log"
### LOG to file  eg:g_fn_LOG "Test"
g_fn_LOG()
{
    s_Ddate=`date +"%F %H:%M:%S"`
    echo "[$s_Ddate] $*" >> $g_s_LOGFILE
}

#获取本机ip地址最后一段
G_LOCAL_IP_LAST=$(echo ${G_LOCAL_IP} |awk -F '.' '{print $NF}')
#获取对端ip地址最后一段
G_MOVE_IP_LAST=$(echo ${G_MOVE_IP} |awk -F '.' '{print $NF}')

#本机pid文件存储路径
LOCAL_DIR=/var/applog/${G_LOCAL_IP_LAST}_pid/
#为主备机服务器关系的对端PID文件目录
MOVE_DIR=/var/applog/${G_MOVE_IP_LAST}_pid/

#关闭Stop本机应用
Stop_Local_Prog()
{
	g_fn_LOG "$G_LOCAL_IP 节点退出时调用的脚本 一键关闭本机程序 Start"
        #提前加锁不同步
	touch $RSYNC_PID_LOCK_FILE &> /dev/null
        if [ -f $RSYNC_PID_LOCK_FILE ];then
                g_fn_LOG "[SUCCESS] $RSYNC_PID_LOCK_FILE PID实时同步加锁成功,开启不同步!!!"
        else
                g_fn_LOG "[ERROR] $RSYNC_PID_LOCK_FILE PID实时同步加锁失败,仍可同步"
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
       		                         g_fn_LOG "$RUN_FILE stop 执行成功"
       		                 else
       		                         g_fn_LOG "$RUN_FILE stop 执行失败"
       		                 fi
       		         fi
       		 	echo -e '\n'
       		 done
        fi
	g_fn_LOG "$G_LOCAL_IP 节点退出时调用的脚本 一键关闭本机程序 End"
}

#关闭对端机应用
Stop_Move_Prog()
{
        g_fn_LOG "$G_LOCAL_IP 节点退出时调用的脚本 一键关闭对端机$G_MOVE_IP程序 Start"
	#提前加锁不同步
        touch $RSYNC_PID_LOCK_FILE &> /dev/null
        if [ -f $RSYNC_PID_LOCK_FILE ];then
                g_fn_LOG "[SUCCESS] $RSYNC_PID_LOCK_FILE PID实时同步加锁成功,开启不同步!!!"
        else
                g_fn_LOG "[ERROR] $RSYNC_PID_LOCK_FILE PID实时同步加锁失败,仍可同步"
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
                                         g_fn_LOG "$RUN_FILE stop 对端程序关闭执行成功"
                                 else
                                         g_fn_LOG "$RUN_FILE stop 对端程序关闭执行失败"
                                 fi
                         fi
                        echo -e '\n'
                 done
        fi
        g_fn_LOG "$G_LOCAL_IP 节点退出时调用的脚本 一键关闭对端机$G_MOVE_IP程序 End"
}

main(){
	g_fn_LOG "========================================================================"
	if [ ! -f "$KEEPALIVED_SWITCH_LOCK_FILE" ];then
		#锁不存在,可以执行切换,下面为节点退出时调用的脚本
		#notify_stop "/etc/keepalived/scripts/pid_stop.sh"
		#一对一主备执行Stop_Local_Prog;多主共用一个备则执行Stop_Move_Prog
		Stop_Local_Prog
		#Stop_Move_Prog
	else		
		echo -e "\033[1;31m[ERROR] Keepalived主备切换功能开启锁存在,若需要请移除锁,方可Stop_Local_Prog\033[0m"  
                g_fn_LOG "[ERROR] ${KEEPALIVED_SWITCH_LOCK_FILE} Keepalived主备切换功能开启锁存在,若需要请移除锁,方可Stop_Local_Prog"
		exit 1
	fi
	g_fn_LOG "========================================================================"
	exit 0
}
main
