#!/bin/bash
#***************************************************************************
# * 
# * @file:pinglog.sh 
# * @author:soc
# * @date:2016-04-13 10:48 
# * @version 0.5
# * @description: �����δ����̽��г�ping����,��¼�ҷ����Է������̵�����״��
# * @Copyright (c) 007ka all right reserved 
# * @updatelog: 
# *             1.���³����׼���߼���
# *             2.�Ż���־�����
# *		        3.���ҷ����Է������̵�����״���������־��
# *		        4.��pinglog.sh�ű����뵽��ʱ������,eg : 0 0 * * * PATH_to/pinglog.sh
#**************************************************************************

export LANG=zh_CN.GBK


STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

##ԴIP��ַ
g_s_SRC_IP=$(ip addr | grep 'inet' | grep "10\.2" | grep -vw 'secondary' | awk -F['/'' '.]+ 'NR==1 {print $3"."$4"."$5"."$6}')


###��������all��־���·��
g_s_LOG_PATH=/var/applog/ping

###�����ļ�·��
g_s_Work_Inc="/usr/local/007ka/new_sysmon/partner_info.ini"

if [ ! -f $g_s_Work_Inc ];then
	echo "$g_s_Work_Inc �����ڣ�"
	exit $STATE_CRITICAL
fi
	

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

### LOG to file  eg:g_fn_LOG "Test"
g_fn_LOG()
{
    s_Ddate=`date +"%F %H:%M:%S"`
    echo "[$s_Ddate] $*" >> $g_s_LOGFILE
}
g_s_LOGDATE=`date +"%F"`


###check the run user
###��⵱ǰ�û��Ƿ�Ϊapps���������˳�ִ��

if [ `whoami` == "apps" ];then

	g_s_PARTNER_ID_NUM=$(cat $g_s_Work_Inc|grep -v "^#"|awk -F "[=== ]+" '{print $1}'|wc -l)

	for i in `seq $g_s_PARTNER_ID_NUM`
	do
		if [ ! -d $g_s_LOG_PATH ];then
			mkdir -p $g_s_LOG_PATH
		fi
		PARTNER_NAME=$(cat $g_s_Work_Inc|grep -v "^#"|awk -F "[=== ]+" '{print $1}'|sed -n "$i"p)
		LOG_PATH="${g_s_LOG_PATH}/${PARTNER_NAME}"
		mkdir -p $LOG_PATH &>/dev/null

		LOG_FILE="${LOG_PATH}/ping-call.${g_s_LOGDATE}.log"
		PARTNER_IP=$( cat $g_s_Work_Inc|grep -v "^#"|awk -F "[=== ]+" '{print $2}'|sed -n "$i"p) 
		pkill -f "/bin/ping -i 1 $PARTNER_IP" || sleep 1
		/bin/ping -i 1 $PARTNER_IP | awk '{print strftime("%Y%m%d %T",systime()),"src '$g_s_SRC_IP'" , "dst '$PARTNER_IP'"  "\t" $0}' >> $LOG_FILE &
	done
else
	_err "��apps�û�,�˳�ִ��"
	exit $STATE_WARNING
fi
