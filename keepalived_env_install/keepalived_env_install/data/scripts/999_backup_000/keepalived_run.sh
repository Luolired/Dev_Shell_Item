#!/bin/bash

#***************************************************************************
# * 
# * @file:keepalived_run.sh 
# * @author:soc
# * @date:2016-01-05 16:26 
# * @version 0.1
# * @description: keepalived_env_install 
# * @Copyright (c) 007ka all right reserved 
# * @updatelog: 
# *             1.���³����׼���߼���
#**************************************************************************/

export LANG=zh_CN.GBK

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

KEEPALIVED_PATH=/etc/keepalived
Priority_Normal_Master=120
Priority_Normal_Backup=80

#�����������������ļ�
PRO_CFG_PATH=$(dirname $0)
PRO_CFG="${PRO_CFG_PATH}/pid_backup.ini"
#Keepalived�����л����ܿ������ļ�,���ڽ��������л�,�����ڿ��л�,��������ͬ��
KEEPALIVED_SWITCH_LOCK_FILE="${PRO_CFG_PATH}/keepalived_switch.lock"
#ͬ�����ļ�,���ڲ�����ͬ��,�����������ͬ��,��������ͬ��
RSYNC_PID_LOCK_FILE="${PRO_CFG_PATH}/rsync_pid.lock"

#������·����/$������޳����/�ַ�,��֤·����ȷ��
echo $KEEPALIVED_PATH | grep -q '/$' && KEEPALIVED_PATH=$(echo $KEEPALIVED_PATH|sed 's/\/$//')

### Logding PRO_CFG
G_LOG_FILE=$(grep -Pw "^PROGRAM_PATH" $PRO_CFG |awk -F 'PROGRAM_PATH=' '{print $NF}'|awk -F '[/]+' '{print $NF}')
###LOG_PATH
###��������all��־���·��
g_s_LOG_PATH=/var/applog/${G_LOG_FILE}
mkdir -p $g_s_LOG_PATH
g_s_LOGDATE=`date +"%F"`
#ִ�нű����ɵ���־
g_s_LOGFILE="${g_s_LOG_PATH}/keepalived_run.${g_s_LOGDATE}.log"
### LOG to file  eg:g_fn_LOG "Test"
g_fn_LOG()
{
    s_Ddate=`date +"%F %H:%M:%S"`
    echo "[$s_Ddate] $*" >> $g_s_LOGFILE
}

### Print error messges eg:  _err "This is error"
function _err()
{
    echo -e "\033[1;31m[ERROR] $@\033[0m"
}

### Print notice messages eg: _info "This is Info"
function _info()
{
    echo -e "\033[1;32m[Info] $@\033[0m"
}

### ������׼�����
function _CheckAccess()
{
	_info "Welcome ��ʼ����������������!"
	g_fn_LOG "Welcome ��ʼ����������������!"
	[ `whoami` = "root" ] || {
	#[ `whoami` = "apps" ] || {
	        _err "�û���root,�˳�!"
		g_fn_LOG "[ERROR] �û���root,�˳�!"
	        exit $STATE_CRITICAL
	}
	
	### ����ǰPID����¼
	Local_ip_last=$(ip addr | grep 'inet' | grep "10\.2" | grep -vw 'secondary' | awk -F['/'' '.]+ 'NR==1 {print $6}')
	if [ -z $Local_ip_last ]
	then
        	_err "Local_ip_last not found!please check bond0"
        	exit 1
	fi
	Local_Pid_Dir=/var/applog/${Local_ip_last}_pid
	Before_Run_Pid_Total=$(find ${Local_Pid_Dir} -type f -name "*.pid"  |wc -l)
	_info "�ֱ���$Local_ip_last PIDĿ¼�����г�����Ϊ:${Before_Run_Pid_Total}"	
	g_fn_LOG "�ֱ���$Local_ip_last PIDĿ¼�����г�����Ϊ:${Before_Run_Pid_Total}"	

	### Check $KEEPALIVED_PATH
	if [ ! -d $KEEPALIVED_PATH ];then
	        _err "$KEEPALIVED_PATH is not a directory,please check"
	        g_fn_LOG "[ERROR] $KEEPALIVED_PATH is not a directory,please check"
	        exit $STATE_CRITICAL
	else
		### keepalived.conf �����ļ����
		if [ -f ${KEEPALIVED_PATH}/keepalived.conf ];then
			grep -q "nopreempt" ${KEEPALIVED_PATH}/keepalived.conf || {
				_err "keepalived.conf û�����÷���ռ������"
				g_fn_LOG "[ERROR] keepalived.conf û�����÷���ռ������"
				exit $STATE_CRITICAL
			}
		fi
		### *_backup_* Ŀ¼��׼����� 
		if [[ "$(find $KEEPALIVED_PATH -type d -name "*backup*" |wc -l)" != "1" ]];then
	        	_err "Keepalived �Ǳ�׼����װ,��֪ͨҵ���鲿��install.sh $KEEPALIVED_PATH��û��һ��_backup_Ŀ¼"
	        	g_fn_LOG "[ERROR] Keepalived �Ǳ�׼����װ,��֪ͨҵ���鲿��install.sh $KEEPALIVED_PATH��û��һ��_backup_Ŀ¼"
	       		 exit $STATE_CRITICAL
		else
			keepalived_sys_dir=$(grep "_backup_" ${KEEPALIVED_PATH}/keepalived.conf | grep -v '#'|head -n1 | awk -F '/' '{print $5}')
			PRO_CFG_PATH=$(find /etc/keepalived/ -type d -name "*backup*" |head -n1)
			#Keepalived�����л����ܿ������ļ����ļ����ڽ������л�,�������򲻽����л�
			KEEPALIVED_SWITCH_LOCK_FILE="${PRO_CFG_PATH}/keepalived_switch.lock"
			#ͬ����״̬�ļ�,�ļ����ڽ�����ͬ��,��������ͬ��
			RSYNC_PID_LOCK_FILE="${PRO_CFG_PATH}/rsync_pid.lock"
			
			### Check notify_master notify_backup notify_stop 
			notify_master_shell=$(grep "_backup_" ${KEEPALIVED_PATH}/keepalived.conf |grep -v "#"| grep notify_master |sed 's/\"//g'|awk '{print $2}')
			if [ -f "$notify_master_shell" ];then
				grep -q "KEEPALIVED_SWITCH_LOCK_FILE" $notify_master_shell && _info "1.notify_master �¼��ű�OK������" || {
					_err "keepalived.conf notify_master �ű������������л���"
					g_fn_LOG "[ERROR] keepalived.conf notify_master �ű������������л���"
					exit $STATE_CRITICAL
				}
			else
				_err "keepalived.conf notify_master �ű�������"
				g_fn_LOG "[ERROR] keepalived.conf notify_master �ű�������"
				exit $STATE_CRITICAL
			fi
			notify_backup_shell=$(grep "_backup_" ${KEEPALIVED_PATH}/keepalived.conf |grep -v "#"| grep notify_backup | sed 's/\"//g'|awk '{print $2}')
			if [ -f "$notify_backup_shell" ];then
                                grep -q "KEEPALIVED_SWITCH_LOCK_FILE" $notify_backup_shell && _info "2.notify_backup �¼��ű�OK������" || {
                                        _err "keepalived.conf notify_backup �ű������������л���"
                                        g_fn_LOG "[ERROR] keepalived.conf notify_backup �ű������������л���"
                                        exit $STATE_CRITICAL
                                }
                        else
                                _err "keepalived.conf notify_backup �ű�������"
                                g_fn_LOG "[ERROR] keepalived.conf notify_backup �ű�������"
                                exit $STATE_CRITICAL
                        fi
			notify_stop_shell=$(grep "_backup_" ${KEEPALIVED_PATH}/keepalived.conf | grep -v "#"|grep notify_stop|sed 's/\"//g' |awk '{print $2}')
			if [ -f "$notify_stop_shell" ];then
                                grep -q "KEEPALIVED_SWITCH_LOCK_FILE" $notify_stop_shell && _info "3.notify_stop  �¼��ű�OK������" || {
                                        _err "keepalived.conf notify_stop �ű������������л���"
                                        g_fn_LOG "[ERROR] keepalived.conf notify_stop �ű������������л���"
                                        exit $STATE_CRITICAL          
                                }
                        else
                                _err "keepalived.conf notify_stop �ű�������"
                                g_fn_LOG "[ERROR] keepalived.conf notify_stop �ű�������"
                                exit $STATE_CRITICAL
                        fi
			### ���Inotifyʵʱ���ͬ��PID�ű�
			if [ $(pgrep -u apps -f "rsync_pid.sh"|wc -l) -eq 2 ];then
				if [ -f "$RSYNC_PID_LOCK_FILE" ];then
					_err "$RSYNC_PID_LOCK_FILE ͬ����������,����ϵҵ����ά"
					g_fn_LOG "[ERROR] $RSYNC_PID_LOCK_FILE ͬ����������,����ϵҵ����ά"
					exit $STATE_CRITICAL
				else
					_info "4.rsync_pid.sh ͬ������OK������"
				fi
			else
				_err "rsync_pid.sh ͬ��PID�ű�δ����,����ϵҵ��������"
				g_fn_LOG "[ERROR] rsync_pid.sh ͬ��PID�ű�δ����,����ϵҵ��������"
				exit $STATE_CRITICAL
			fi
			### �ж��Ƿ��Ѿ�������keepalived
			if [ $(pgrep -u root -f "/usr/sbin/keepalived"|wc -l) -eq 3 ];then
			#if [ $(pgrep -u apps -f "/usr/sbin/keepalived"|wc -l) -eq 3 ];then
				_err "keepalived �Ѿ�����,���˳��ű�"
				g_fn_LOG "[ERROR] keepalived �Ѿ�����,���˳��ű�"
				exit $STATE_WARNING
			fi
			### �״���������Ҫ��֤���ļ��Ĵ���
			touch $KEEPALIVED_SWITCH_LOCK_FILE &> /dev/null	 
			g_fn_LOG "$KEEPALIVED_SWITCH_LOCK_FILE �״��������ļ��Ĵ���OK"
		fi
	fi
	g_fn_LOG "=============== _CheckAccess ��� keepalived_run End ======================"
}

function Master()
{
	grep -q "priority ${Priority_Normal_Master}" ${KEEPALIVED_PATH}/keepalived.conf || {
		_err "��ѡ��Master��ɫ����,��keepalived.conf priority����ȴ��Master���ȼ�${Priority_Normal_Master},����"
		g_fn_LOG "[ERROR] ��ѡ��Master��ɫ����,��keepalived.conf priority����ȴ��Master���ȼ�${Priority_Normal_Master},����"
		exit $STATE_CRITICAL
	}
	echo -e "\n\033[1;35mȷ��ִ����������,��ȷ��Y|N:(\033[0m\033[33m\033[01mQ\033[0m\033[1;35m�˳�)��\033[0m\033[33m\033[01m\c"
        read INPUT_Temp_confirm
	echo -e "\033[0m"
	case "$INPUT_Temp_confirm" in
		Y|y)
			if [ -f "$KEEPALIVED_SWITCH_LOCK_FILE" ];then
				_info "/etc/init.d/keepalived start"
				g_fn_LOG "/etc/init.d/keepalived start"
				/etc/init.d/keepalived start
				
				### �ж��Ƿ��Ѿ�������keepalived
				#cp /home/apps/state.txt /etc/keepalived/
				echo -e "\033[1;31m[ �Ե�Ƭ��,��������ҪԤ�к�ѡȡMaster.... ^_^ @Create_by:SOC ]  \033[0m" | awk  'END{a=length($0);i=1;printf "\n\t";while(i<=a){printf substr($0,i,1) "\a";i++;system("sleep  0.1")};printf "\n\n" }'
				sleep 2
                	        if [ $(pgrep -u root -f "/usr/sbin/keepalived"|wc -l) -eq 3 ];then
					if [ -f ${KEEPALIVED_PATH}/state.txt ];then
						State_ROLE=$(tail -n 1 ${KEEPALIVED_PATH}/state.txt|awk '{print $NF}')
						if [[ "$State_ROLE" == "master" ]];then
							After_Run_Pid_Total=$(find ${Local_Pid_Dir} -type f -name "*.pid"  |wc -l)
							g_fn_LOG "�ֱ���$Local_ip_last PIDĿ¼�����г�����Ϊ:${After_Run_Pid_Total}"
							if [ "$Before_Run_Pid_Total" -eq "$After_Run_Pid_Total" ];then
								_info "ף��:�����ɹ�"
								echo -e "\n\033[1;35m �����Ϻ�,���Ƴ���,��ȷ��Y|N:(\033[0m\033[33m\033[01mQ\033[0m\033[1;35m�˳�)��\033[0m\033[33m\033[01m\c"
							        read INPUT_Temp_confirm
        							echo -e "\033[0m"
      								case "$INPUT_Temp_confirm" in
               								Y|y)
										rm $KEEPALIVED_SWITCH_LOCK_FILE 
										#rm $KEEPALIVED_SWITCH_LOCK_FILE &> /dev/null
										_info "���Ƴ����,�����л���ЧSuccess Keepalived �������в���ִ�����!!!"
										g_fn_LOG "[SUCCESS] ���Ƴ����,�����л���ЧSuccess Keepalived �������в���ִ�����!!!"
									;;
									q|N|n|Q)
                	  							_info "����:��ע���Ƴ���$KEEPALIVED_SWITCH_LOCK_FILE GoodBye !"
                	  							g_fn_LOG "����:��ע���Ƴ���$KEEPALIVED_SWITCH_LOCK_FILE GoodBye !"
                	      							exit $STATE_OK
                	        					;;
           							     	*)
										_err "ȷ��ָ�����,����Ϊ:Y|N"
										exit $STATE_UNKNOWN
									;;
								esac

							else
								_err "ע��:���������PID������һ��,���ʵ"
								exit $STATE_WARNING
							fi	
						else
							_err "����:������,������ɫ��һ��,�����̼��/var/log/syslog,����ϵҵ����!!!"
							g_fn_LOG "[ERROR] ����:������,������ɫ��һ��,�����̼��/var/log/syslog,����ϵҵ����!!!"
							exit $STATE_CRITICAL
						fi
					else
						_err "����:������${KEEPALIVED_PATH}/state.txt δ����,δ���õ�notify_backup,�����̼��/var/log/syslog"
						g_fn_LOG "[ERROR] ����:������${KEEPALIVED_PATH}/state.txt δ����,δ���õ�notify_backup,�����̼��/var/log/syslog"
						exit $STATE_CRITICAL	
					fi
				else
                	                _err "keepalived ����ʧ��,����/var/log/syslog"
                	                g_fn_LOG "[ERROR] keepalived ����ʧ��,����/var/log/syslog"
                	                exit $STATE_WARNING
                	        fi
			else	
				_err "$KEEPALIVED_SWITCH_LOCK_FILE ���ȼ��������� touch $KEEPALIVED_SWITCH_LOCK_FILE"
				g_fn_LOG "$KEEPALIVED_SWITCH_LOCK_FILE ���ȼ��������� touch $KEEPALIVED_SWITCH_LOCK_FILE"
				exit 1
			fi
			;;
		q|N|n|Q)
			_info "GoodBye !"
			exit 0
			;;
		*)
			_err "ȷ��ָ�����,����Ϊ:Y|N"
			exit 1
			;;
	esac
	g_fn_LOG "=============== Master ִ��keepalived_run End ======================"
}

function Backup()
{
	grep -q "priority ${Priority_Normal_Backup}" ${KEEPALIVED_PATH}/keepalived.conf || {
		_err "��ѡ��Backup��ɫ����,��keepalived.conf priority����ȴ��Backup���ȼ�${Priority_Normal_Backup},����"
		g_fn_LOG "[ERROR] ��ѡ��Backup��ɫ����,��keepalived.conf priority����ȴ��Backup���ȼ�${Priority_Normal_Backup},����"
		exit $STATE_CRITICAL
	}
	echo -e "\n\033[1;35mȷ��ִ����������,��ȷ��Y|N:(\033[0m\033[33m\033[01mQ\033[0m\033[1;35m�˳�)��\033[0m\033[33m\033[01m\c"
        read INPUT_Temp_confirm
	echo -e "\033[0m"
	case "$INPUT_Temp_confirm" in
		Y|y)
			if [ -f "$KEEPALIVED_SWITCH_LOCK_FILE" ];then
				_info "/etc/init.d/keepalived start"
				/etc/init.d/keepalived start
				
				#cp /home/apps/state.txt /etc/keepalived/
				### �ж��Ƿ��Ѿ�������keepalived
				echo -e "\033[1;31m[ �Ե�Ƭ��,��������ҪԤ�к�ѡȡMaster.... ^_^ @Create_by:SOC ]  \033[0m" | awk  'END{a=length($0);i=1;printf "\n\t";while(i<=a){printf substr($0,i,1) "\a";i++;system("sleep  0.1")};printf "\n\n" }'
				sleep 2
                	        if [ $(pgrep -u root -f "/usr/sbin/keepalived"|wc -l) -eq 3 ];then
					if [ -f ${KEEPALIVED_PATH}/state.txt ];then
						State_ROLE=$(tail -n 1 ${KEEPALIVED_PATH}/state.txt|awk '{print $NF}')
						if [[ "$State_ROLE" == "backup" ]];then
							After_Run_Pid_Total=$(find ${Local_Pid_Dir} -type f -name "*.pid"  |wc -l)
							g_fn_LOG "�ֱ���$Local_ip_last PIDĿ¼�����г�����Ϊ:${After_Run_Pid_Total}"
							if [ "$Before_Run_Pid_Total" -eq "$After_Run_Pid_Total" ];then
								_info "ף��:�����ɹ�"
								echo -e "\n\033[1;35m �����Ϻ�,���Ƴ���,��ȷ��Y|N:(\033[0m\033[33m\033[01mQ\033[0m\033[1;35m�˳�)��\033[0m\033[33m\033[01m\c"
							        read INPUT_Temp_confirm
        							echo -e "\033[0m"
      								case "$INPUT_Temp_confirm" in
               								Y|y)
										rm $KEEPALIVED_SWITCH_LOCK_FILE
										#rm $KEEPALIVED_SWITCH_LOCK_FILE &> /dev/null
										_info "���Ƴ����,�����л���Ч Success Keepalived �������в���ִ�����!!!"
										g_fn_LOG "[SUCCEESS] ���Ƴ����,�����л���Ч Success Keepalived �������в���ִ�����!!!"
									;;
									q|N|n|Q)
                	  							_info "����:��ע���Ƴ���$KEEPALIVED_SWITCH_LOCK_FILE GoodBye !"
                	  							g_fn_LOG "����:��ע���Ƴ���$KEEPALIVED_SWITCH_LOCK_FILE GoodBye !"
                	      							exit $STATE_OK
                	        					;;
           							     	*)
										_err "ȷ��ָ�����,����Ϊ:Y|N"
										exit $STATE_UNKNOWN
									;;
								esac

							else
								_err "ע��:���������PID������һ��,���ʵ"
								g_fn_LOG "[ERROR] ע��:���������PID������һ��,���ʵ"
								exit $STATE_WARNING
							fi	
						else
							_err "����:������,������ɫ��һ��,�����̼��/var/log/syslog,����ϵҵ����!!!"
							g_fn_LOG "[ERROR] ����:������,������ɫ��һ��,�����̼��/var/log/syslog,����ϵҵ����!!!"
							exit $STATE_CRITICAL
						fi	
					else
						_err "����:������${KEEPALIVED_PATH}/state.txt δ����,δ���õ�notify_backup,�����̼��/var/log/syslog"
						g_fn_LOG "[ERROR] ����:������${KEEPALIVED_PATH}/state.txt δ����,δ���õ�notify_backup,�����̼��/var/log/syslog"
						exit $STATE_CRITICAL
					fi
				else
                	                _err "keepalived ����ʧ��,����/var/log/syslog"
                	                g_fn_LOG "[ERROR] keepalived ����ʧ��,����/var/log/syslog"
                	                exit $STATE_WARNING
                	        fi
			else
				_err "$KEEPALIVED_SWITCH_LOCK_FILE ���ȼ��������� touch $KEEPALIVED_SWITCH_LOCK_FILE"
				g_fn_LOG "[ERROR] $KEEPALIVED_SWITCH_LOCK_FILE ���ȼ��������� touch $KEEPALIVED_SWITCH_LOCK_FILE"
				exit $STATE_CRITICAL
			fi
			;;
		q|N|n|Q)
			_info "GoodBye !"
			exit 0
			;;
		*)
			_err "ȷ��ָ�����,����Ϊ:Y|N"
			exit 1
			;;
	esac
	g_fn_LOG "=============== Backup ִ��keepalived_run End ======================"
}

#��ȡ������Ϣ
Help()
{
        echo -e "\033[0m"
        echo -e "\033[1;35m===============�Զ�����װKeepalived �ű����Ҫ��======================\033[1m"
        echo -e "\033[1;35m=============ִ�����ȷ�QQ��Ϣ֪ͨҵ����,׼������keepalived=============\033[1m"
        echo -e "\033[0;35m=== ���﷨: `basename $0` ������          ��������: \033[0m"
        echo -e "\033[0;32m[Info]\t ==== `basename $0` ��ѡ����� #��ȡ����====   \033[0m"
        echo -e "\033[0;32m[Info]\t ==== `basename $0` master     #Master��ɫ��������====  \033[0m"
        echo -e "\033[0;32m[Info]\t ==== `basename $0` backup     #Backup��ɫ��������====  \033[0m"
        echo -e "\033[0;32m[Info]\t ==== `basename $0` -h|--help  #��ȡ����====             \033[0m"
        echo -e "\033[0;32m[Info]\t ==== `basename $0` -v|-V      #��ȡ�汾��Ϣ====         \033[0m"
        echo -e "\033[1;35m========================================================================\033[1m"
        echo -e "\033[0m"
}

function main(){
#��ȡ����ֵ
TMP_ROLE=$1
if [ "$TMP_ROLE" = "" ];then
        Help
        exit 0
else	
	g_fn_LOG "===============Welcome ��ʼִ��keepalived_run======================"
	_CheckAccess 
        case "$TMP_ROLE" in
        master|Master|MASTER)
                Master
                exit 0;;
        backup|Backup|BACKUP)
                Backup
                exit 0;;
        -h|--help|help)
                Help
                exit 0;;
        -V|-v)
                _info "Create Time:2016-01-27,Author:007ka-soc,V1.0"
                _info "Modified Time:2016-01-27,V1.1"
                exit 0;;
        *)
                _err "Error input argument $1"
                _info "eg:${KEEPALIVED_PATH}/`basename $0` master|backup|help"
                exit 0;;
        esac
fi

}

main $1
