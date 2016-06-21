#!/bin/bash

#***************************************************************************
# * 
# * @file:install.sh 
# * @author:soc
# * @date:2016-01-05 16:26 
# * @version 0.1
# * @description: keepalived_env_install 
# * @Copyright (c) 007ka all right reserved 
# * @updatelog: 
# *             1.���³����׼���߼���
#**************************************************************************/

export LANG=zh_CN.GBK

G_Central_IP_20=10.20.10.180
G_Central_IP_21=10.21.10.215
G_Central_IP_22=10.22.10.180

echo -e "\033[1;31m[ Welcome install keepalived_env ^_^ @Create_by:SOC ]  \033[0m" | awk  'END{a=length($0);i=1;printf "\n\t";while(i<=a){printf substr($0,i,1) "\a";i++;system("sleep  0.1")};printf "\n\n" }'

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

[ `whoami` = "apps" ] || {
        _err "�û���apps,�˳�!"
        exit 1
}

### pid storage file ip_last_three
G_LOCAL_IP=$(ip addr | grep 'inet' | grep "10\.2" | grep -vw 'secondary' | awk -F ['/ ']+ 'NR==1 {print $3}')
ip_last=$(ip addr | grep 'inet' | grep "10\.2" | grep -vw 'secondary' | awk -F['/'' '.]+ 'NR==1 {print $6}')
if [ -z $ip_last ]
then
        _err "ip_last not found!please check bond0"
        exit 1
fi

dpkg -l | grep -q "inotify-tools" || { 
	_err "����ϵ�쵼,#apt-get -y install inotify-tools"
	exit 1
}
dpkg -l | grep -q "keepalived" || {
	_err "����ϵ�쵼,#apt-get -y install keepalived"
	exit 1
}

### Check $PROGRAM_PATH
if [ "apps" != "$(ls -lhd /etc/keepalived | awk '{print $3}')" ];then
        _err "/etc/keepalived is not apps:apps,please check:#chmon apps:apps /etc/keepalived"
        exit 1
fi

#�����������������ļ�
PRO_CURRENT_PATH=$(dirname $0)
#��ȡ����ip��ַ���һ��
G_LOCAL_IP_LAST=$(echo ${G_LOCAL_IP} |awk -F '.' '{print $NF}')
G_LOCAL_IP_SYSID=$(echo ${G_LOCAL_IP} |awk -F '.' '{print $2}')

#����pid�ļ��洢·��
LOCAL_DIR=/var/applog/${G_LOCAL_IP_LAST}_pid/

function CheckIPAddress()
{
    tmp=0
    IP=$1
    echo "$IP" | grep -Eq '[^0-9.]|^\.|\.$' && tmp=1
    [ $(echo -e "${IP//./\n}" | wc -l) -ne 4 ] && tmp=1
    for i in ${IP//./ }
    do
        [ $((i/8)) -lt 32 ] || tmp=1
    done
    if [ "$tmp" -eq 0 ];then
        return 0
    else
        return 1
    fi
}

function CheckAccess()
{
	echo -e "\033[0m"
        echo -e "\033[1;35m===============�Զ�����װKeepalived �ű����Ҫ��======================\033[1m"
        echo -e "\033[0;35m=== ���﷨: 121_backup_122�� 	 ��������: \033[0m"
        echo -e "\033[0;32m[Info]\t 1.vrrp_instance ʵ������������Ϊ��ʶ����VI_121��1�� \033[0m"
        echo -e "\033[0;32m[Info]\t 2.virtual_router_id 121 Ψһ�����idΪ������ʶ����121 ��2�� \033[0m"
        echo -e "\033[0;32m[Info]\t 3.keepalived_env �����淶��_bachup_������121_backup_122 ��3�� \033[0m"
        echo -e "\033[0;32m[Info]\t 4.pid_backup.ini G_MOVE_IP Ϊ��������������ϵ�ĶԶ�IP��ַ ��4�� \033[0m"
        echo -e "\033[0;32m[Info]\t 5.clearfullappname.sh ��Ҫ���ݶ�Ӧϵͳ�������� ��5�� \033[0m"
        echo -e "\033[1;35m========================================================================\033[1m"
	echo -e "\033[0m"
	cd /etc/keepalived
}

function Help()
{
        echo -e "\033[1;35m===================�Զ�����װKeepalived �ű�����========================\033[1m"
        echo -e "\033[0;35m=== �������ܰ���:1.���뱾����ɫ 2.����Զ˻�IP 3.ȷ�� 4.��װ ====\033[0m"
        echo -e "\033[0;35m=== ���﷨: 121_backup_122�� Backup ��������: \033[0m"
        echo -e "\033[0;32m[Info]\t ִ������������ɫ1|2����1��  ����Ϊ��������1,��2����Ϊ����				 \033[0m"
        echo -e "\033[0;32m[Info]\t ִ������Զ˻�IP: ��10.22.10.122��  \033[0m"
        echo -e "\033[0;32m[Info]\t ִ��ȷ�ϲ���Y|N: ��Y�� 121�� 122�� 121_backup_122 \033[0m"
        echo -e "\033[1;35m========================================================================\033[1m"
	echo -e "\033[0m"
}
if [ -f "/etc/keepalived/keepalived.conf" ];then
	_err "/etc/keepalived/keepalived.conf�Ѿ�����,�����ظ���װ,����"
	CheckAccess
	exit 1
fi

Help
echo -e "\n\033[1;35m�����뱾����ɫ1Ϊ����,2Ϊ����:(\033[0m\033[33m\033[01mQ\033[0m\033[1;35m�˳�)��\033[0m\033[33m\033[01m\c"
read INPUT_Temp
echo -e "\033[0m"
case "$INPUT_Temp" in
	Master|MASTER|1)	
		echo -e "\n\033[1;35m������Զ˻�IP��ַ:(\033[0m\033[33m\033[01mQ\033[0m\033[1;35m�˳�)��\033[0m\033[33m\033[01m\c"
		read Ip_line
		echo -e "\033[0m"
		case "$Ip_line" in
		q|Q)
		        _info "GoodBye"
		        exit 0;;
		*)
		        CheckIPAddress $Ip_line
		        Result_CheckIp=$?
		        if [ "$Result_CheckIp" -eq 0 ];then
				#Ϊ��������������ϵ�ĶԶ�PID�ļ�Ŀ¼
				move_ip_last=$(echo ${Ip_line} |awk -F '.' '{print $NF}')
				rsync_dir=/var/applog/${move_ip_last}_pid/
				keepalived_sys_dir="${G_LOCAL_IP_LAST}_backup_${move_ip_last}"
				_info "${G_LOCAL_IP_SYSID}ϵͳ: ${G_LOCAL_IP_LAST}������Ŀ¼�ļ�:${keepalived_sys_dir} ����Ϊ���� "
	        	       	echo -e "\n\033[1;35mȷ�ϲ���,��ȷ��Y|N:(\033[0m\033[33m\033[01mQ\033[0m\033[1;35m�˳�)��\033[0m\033[33m\033[01m\c"
				read INPUT_Temp_confirm
				echo -e "\033[0m"
				case "$INPUT_Temp_confirm" in
					Y|y)
						cp -r "$PRO_CURRENT_PATH/data/keepalived_master.conf" /etc/keepalived/keepalived.conf
						mkdir -p /etc/keepalived/scripts
						cp -rf "$PRO_CURRENT_PATH/data/scripts/999_backup_000" /etc/keepalived/scripts/${keepalived_sys_dir}
						cd /etc/keepalived/scripts/${keepalived_sys_dir} && ln -sf clearfullappname_${G_LOCAL_IP_SYSID}.sh clearfullappname.sh
						case "${G_LOCAL_IP_SYSID}" in
							20)
								sed -i "s/g-central-ip/${G_Central_IP_20}/g" `grep -rl "g-central-ip" /etc/keepalived`
							;;
							21)
								sed -i "s/g-central-ip/${G_Central_IP_21}/g" `grep -rl "g-central-ip" /etc/keepalived`
							;;
							22)
								sed -i "s/g-central-ip/${G_Central_IP_22}/g" `grep -rl "g-central-ip" /etc/keepalived`
							;;
							*)
								_err "ϵͳ�Ų����ڷ�20|21|22,��ȷ��"
								exit 1
							;;
						esac
						sed -i "s/999/${G_LOCAL_IP_LAST}/g" `grep -rl "999" /etc/keepalived`
						sed -i "s/000/${move_ip_last}/g" `grep -rl "000" /etc/keepalived`
						sed -i "s/g-move-ip/${Ip_line}/g" `grep -rl "g-move-ip" /etc/keepalived`
						Result=$?
						if [ ${Result} -eq 0 ];then
							_info "Success,��װ�ɹ�,����"
							CheckAccess
							_info "�����Ϻ��뿪��ͬ��:/etc/keepalived/scripts/${keepalived_sys_dir}/run.sh"
							exit 0
						else
							_err "Fault,��װʧ��,����"
							exit 1
						fi
					;;
					N|n)
						_info "GoodBye !"
						exit 0
					;;
                                        *)
                                        	_err "ȷ��ָ�����,����Ϊ:Y|N"
						exit 1
					;;
                                        esac
			else
		            	_err "$Ip_line is incorrect IP format,�������IP����"
				exit 1
		        fi
		        ;;
		esac
	;;
        Backup|BACKUP|2)
		echo -e "\n\033[1;35m������Զ˻�IP��ַ:(\033[0m\033[33m\033[01mQ\033[0m\033[1;35m�˳�)��\033[0m\033[33m\033[01m\c"
                read Ip_line
                echo -e "\033[0m"
                case "$Ip_line" in
                q|Q)
                        _info "GoodBye"
                        exit 0;;
                *)
                        CheckIPAddress $Ip_line
                        Result_CheckIp=$?
                        if [ "$Result_CheckIp" -eq 0 ];then
                                #Ϊ��������������ϵ�ĶԶ�PID�ļ�Ŀ¼
                                move_ip_last=$(echo ${Ip_line} |awk -F '.' '{print $NF}')
                                rsync_dir=/var/applog/${move_ip_last}_pid/
                                keepalived_sys_dir="${move_ip_last}_backup_${G_LOCAL_IP_LAST}"
                                _info "${G_LOCAL_IP_SYSID}ϵͳ: ${G_LOCAL_IP_LAST}������Ŀ¼�ļ�:${keepalived_sys_dir} ����Ϊ����"
                                echo -e "\n\033[1;35mȷ�ϲ���,��ȷ��Y|N:(\033[0m\033[33m\033[01mQ\033[0m\033[1;35m�˳�)��\033[0m\033[33m\033[01m\c"
                                read INPUT_Temp_confirm
                                echo -e "\033[0m"
                                case "$INPUT_Temp_confirm" in
                                        Y|y)
                                                cp -r "$PRO_CURRENT_PATH/data/keepalived_backup.conf" /etc/keepalived/keepalived.conf
                                                mkdir -p /etc/keepalived/scripts
                                                cp -rf "$PRO_CURRENT_PATH/data/scripts/999_backup_000" /etc/keepalived/scripts/${keepalived_sys_dir}
						cd /etc/keepalived/scripts/${keepalived_sys_dir} && ln -sf clearfullappname_${G_LOCAL_IP_SYSID}.sh clearfullappname.sh
						case "${G_LOCAL_IP_SYSID}" in
							20)
								sed -i "s/g-central-ip/${G_Central_IP_20}/g" `grep -rl "g-central-ip" /etc/keepalived`
							;;
							21)
								sed -i "s/g-central-ip/${G_Central_IP_21}/g" `grep -rl "g-central-ip" /etc/keepalived`
							;;
							22)
								sed -i "s/g-central-ip/${G_Central_IP_22}/g" `grep -rl "g-central-ip" /etc/keepalived`
							;;
							*)
								_err "ϵͳ�Ų����ڷ�20|21|22,��ȷ��"
								exit 1
							;;
						esac
						sed -i "s/999/${move_ip_last}/g" `grep -rl "999" /etc/keepalived`
                                                sed -i "s/000/${G_LOCAL_IP_LAST}/g" `grep -rl "000" /etc/keepalived`
						sed -i "s/g-move-ip/${Ip_line}/g" `grep -rl "g-move-ip" /etc/keepalived`
                                                Result=$?
                                                if [ ${Result} -eq 0 ];then
                                                        _info "Success,��װ�ɹ�,����"
							CheckAccess
							_info "�����Ϻ��뿪��ͬ��:/etc/keepalived/scripts/${keepalived_sys_dir}/run.sh"
                                                        exit 0
                                                else
                                                        _err "Fault,��װʧ��,����"
                                                        exit 1
                                                fi
                                        ;;
                                        N|n)
                                                _info "GoodBye !"
                                                exit 0
                                        ;;
                                        *)
                                                _err "ȷ��ָ�����,����Ϊ:Y|N"
                                                exit 1
                                        ;;
                                        esac
                        else
		            	_err "$Ip_line is incorrect IP format,�������IP����"
                                exit 1
                        fi
                        ;;
                esac
        ;;
        *)
                _err "ȷ��ָ�����,����Ϊ:1|2"
                exit 1
        ;;
esac
exit 0
