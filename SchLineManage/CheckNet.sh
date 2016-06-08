#!/bin/bash
###############################################################
#  AUTHOR��luc                                                #
#  DATE��2015-07-06                                           #
#  VERSION��CheckNet.sh_20150706_lastest                      #
#  FUNCTION��ÿ��һ���ӷֱ��Ⲧ������ǰ�����ӵ�MASTER��MON  #
#            ����·״̬�������Ƚ�������������·���Ҵﵽ3����  #
#            �����л���������·��ֱ����ά�á���ͷ����         #
#  THINKS���Ƚ϶����ʣ�ͨ�벻ͨ���ͷ���ʱ�䣨ѡ�����ţ�       #
#          ping -c1 -s 2048 ip                                #
#          1��������Ϊ100%�������л��������ٴﵽ3�β��л���   #
#          2��������Ϊ0%��Ƚ�ʱ�䣨��ﵽ3���ٽ����л���     #
###############################################################


configPath="/usr/local/007ka/etc/schedule.ini" #�����������ļ�
current_master=""       #��ǰMASTER��ַ
current_master_port=""  #��ǰMASTER�˿�
current_mon=""          #��ǰMON��ַ
current_mon_port=""     #��ǰMON�˿�
linenumMaster=0         #��ǰIPTABLES�����õ�MASTER���к�
linenumMon=0            #��ǰIPTABLES�����õ�MON���к�
linenumMonV=0           #��ǰIPTABLES�����õ�MON���к�
BuffSize=2048           #������·��PING���Ĵ�С
countMax=3              #��������·��ֵ
countMaster=0           #��¼��ǰMASTER��������·����
nowjmpMaster=0          #��¼��ǰMASTER��·�Ƿ�DOWN
jmpaddrMaster=""        #MASTER��ת��ַ
jmpportMaster=""        #MASTER��ת�˿�
countMon=0              #��¼��ǰMON��������·����
countMonV=0             #��¼��ǰMON��������·����
nowjmpMon=0             #��¼��ǰMON��·�Ƿ�DOWN
jmpaddrMon=""           #MON��ת��ַ
jmpportMon=""           #MON��ת�˿�
timeResult=()           #��¼ÿ����·PING������ʱ��ֵ
lostPackage=()          #��¼ÿ����·PING���Ķ�����
tiaozhuanMaster=0       #�жϵ�ǰMASTER�ǲ�����ת��·
tiaozhuanMon=0          #�жϵ�ǰMON�ǲ�����ת��·
checkflag=0		#��ʱ���ʱ��������־�ļ���־
mastercount=0           #MASTER�л�����
moncount=0              #MON�л�����

#�Զ�����ǰһ���µ���־�ļ�
remove_logfile(){
{
date_day=$(date +%d)
if (( $date_day==27 ))
then
        dir="/usr/local/007ka/SchLineManage/lu-test/log"
        log_date_file=$(date -d "-1 month" +%Y%m) #��ȡ��һ����֮ǰ���·�Ŀ¼
        wc_file=$(ls $dir/*$log_date_file* | wc -l)
        if (( $wc_file!=0 ))
        then
                rm -f $dir/*$log_date_file*
        fi
fi
} &> /dev/null
}

#�������ļ��л�ȡMASTER��MON�ĵ�ַ�Լ��˿�
master_mon_ip[0]=$(awk -F "[=:]" '/SCH_MASTER_ADDR/{print $2}' $configPath)
master_mon_ip[1]=$(awk -F "[=:]" '/SCH_MON_SRV_ADDR/{print $2}' $configPath)
master_mon_port[0]=$(awk -F "[=:]" '/SCH_MASTER_ADDR/{print $3}' $configPath)
master_mon_port[1]=$(awk -F "[=:]" '/SCH_MON_SRV_ADDR/{print $3}' $configPath)

#��ȡ���������ڵ�ϵͳ
system_num=$(ls -lh $configPath | awk -F '.' '{print $4}')
#��jmpIP.config.??�л�ȡ��ת��ַ�Ͷ˿�
x=1
y=0
z=0
for line in $(cat jmpIp.config.$system_num | egrep -v "^#")
do
        if (( $x%2 != 0 ))
        then
                jmp_master_ip[$y]=$(echo $line | awk -F ":" '{print $1}')
                jmp_master_port[$y]=$(echo $line | awk -F ":" '{print $2}')
                ((y++))
        else
                jmp_mon_ip[$z]=$(echo $line | awk -F ":" '{print $1}')
                jmp_mon_port[$z]=$(echo $line | awk -F ":" '{print $2}')
                ((z++))
        fi
        ((x++))
done

#�ԡ�ֱ����ά�á����ˡ�˳�����������
master_ip=(${master_mon_ip[0]} ${jmp_master_ip[@]})
master_port=(${master_mon_port[0]} ${jmp_master_port[@]})
mon_ip=(${master_mon_ip[1]} ${jmp_mon_ip[@]})
mon_port=(${master_mon_port[1]} ${jmp_mon_port[@]})
mon_ip_v=(${master_mon_ip[1]} ${jmp_mon_ip[0]} ${jmp_mon_ip[2]})
mon_port_v=(${master_mon_port[1]} ${jmp_mon_port[0]} ${jmp_mon_port[2]})

#���MASTER��MON��ǰ�����ӵ���·
xianlu_check(){
	mastercount=$(cat log/CheckNet.$(date +%Y%m%d).log | grep "SCH_MASTER" | grep "iptables" | wc -l)
	moncount=$(cat log/CheckNet.$(date +%Y%m%d).log | grep "SCH_MON" | grep "iptables" | wc -l)
	sch_master_addr=$(awk -F "[=]" '/SCH_MASTER_ADDR/{print $2}' $configPath)
	sch_mon_srv_addr=$(awk -F "[=]" '/SCH_MON_SRV_ADDR/{print $2}' $configPath)
        k=0
        for i in $(echo ${master_mon_ip[@]})
        do
                iptables_ip=$(/sbin/iptables -t nat -L OUTPUT -n | grep "$i" | grep "dpt:${master_mon_port[$k]}" | awk -F ':' '{print $3}')
                iptables_ip_port=$(/sbin/iptables -t nat -L OUTPUT -n | grep "$i" | grep "dpt:${master_mon_port[$k]}" | awk -F ':' '{print $4}')
                if (( $k==0 ))
                then
                        if [[ "$iptables_ip" == "" ]]
                        then
                                tiaozhuanMaster=0
                                echo "$NowTime SCH_MASTER ֱ�� ${master_mon_ip[0]}:${master_mon_port[0]}" >> log/CheckNet.$(date +%Y%m%d).log
				echo "$NowTime SCH_MASTER 0 $mastercount ${master_mon_ip[0]}:${master_mon_port[0]} $sch_master_addr" > master.txt
                                current_master=${master_mon_ip[0]}
                                current_master_port=${master_mon_port[0]}
                        else
                                tiaozhuanMaster=1
				first=$(echo ${iptables_ip} | awk -F "." '{print $1}')
				if (( $first==58 && ${iptables_ip_port}==${master_port[1]} ))
				then
					echo "$NowTime SCH_MASTER 1 $mastercount $iptables_ip:$iptables_ip_port $sch_master_addr" > master.txt
                                	echo "$NowTime SCH_MASTER ���� ά�� $iptables_ip:$iptables_ip_port" >> log/CheckNet.$(date +%Y%m%d).log
				elif (( $first==183 && ${iptables_ip_port}==${master_port[3]} ))
				then
					echo "$NowTime SCH_MASTER 3 $mastercount $iptables_ip:$iptables_ip_port $sch_master_addr" > master.txt
                                	echo "$NowTime SCH_MASTER ���� ���ŷ� $iptables_ip:$iptables_ip_port" >> log/CheckNet.$(date +%Y%m%d).log
				else
					echo "$NowTime SCH_MASTER 2 $mastercount $iptables_ip:$iptables_ip_port $sch_master_addr" > master.txt
                                	echo "$NowTime SCH_MASTER ���� ���� $iptables_ip:$iptables_ip_port" >> log/CheckNet.$(date +%Y%m%d).log
				fi
                                current_master=$iptables_ip
                                current_master_port=$iptables_ip_port
                        fi
                else
                        if [[ "$iptables_ip" == "" ]]
                        then
                                tiaozhuanMon=0
                                echo "$NowTime SCH_MON ֱ�� ${master_mon_ip[1]}:${master_mon_port[1]}" >> log/CheckNet.$(date +%Y%m%d).log
				echo "$NowTime SCH_MON 0 $moncount ${master_mon_ip[1]}:${master_mon_port[1]} $sch_mon_srv_addr" > mon.txt
                                current_mon=${master_mon_ip[1]}
                                current_mon_port=${master_mon_port[1]}
                        else
                                tiaozhuanMon=1
				first=$(echo ${iptables_ip} | awk -F "." '{print $1}')
				if (( $first==58 && ${iptables_ip_port}==${mon_port[1]} ))
                                then
                                	echo "$NowTime SCH_MON 1 $moncount $iptables_ip:$iptables_ip_port $sch_mon_srv_addr" > mon.txt
                               		echo "$NowTime SCH_MON ���� ά�� $iptables_ip:$iptables_ip_port" >> log/CheckNet.$(date +%Y%m%d).log
				elif (( $first==183 && ${iptables_ip_port}==${mon_port[3]} ))
				then
					echo "$NowTime SCH_MON 3 $moncount $iptables_ip:$iptables_ip_port $sch_mon_srv_addr" > mon.txt
                                        echo "$NowTime SCH_MON ���� ���ŷ� $iptables_ip:$iptables_ip_port" >> log/CheckNet.$(date +%Y%m%d).log	
				else
					echo "$NowTime SCH_MON 2 $moncount $iptables_ip:$iptables_ip_port $sch_mon_srv_addr" > mon.txt
                                     	echo "$NowTime SCH_MON ���� ���� $iptables_ip:$iptables_ip_port" >> log/CheckNet.$(date +%Y%m%d).log
                                fi
                                current_mon=$iptables_ip
                                current_mon_port=$iptables_ip_port
                        fi
                fi
                ((k++))
        done
	cat master.txt mon.txt > $(hostname | awk '{print $1+0}').txt
cd /usr/local/007ka/SchLineManage/lu-test/
ftp -n << EOF
open 111.111.111.111
user anonymous aaa
cd pub/schduel_txt2
passive
bin
put $(hostname | awk '{print $1+0}').txt
bye
EOF
}

#���MASTER
ping_master(){
        t=0
        for j in $(echo ${master_ip[@]})
        do
                ping -c1 -s $BuffSize $j > /tmp/ping.txt
                lostPackage[$t]=$(cat /tmp/ping.txt | awk -F "[% ]" '/%/{print $6}')
                timeResult[$t]=$(cat /tmp/ping.txt | awk -F "[= ]" '/time=/{print $10}')
                if [[ "$j" == "$current_master" ]]
                then
                        current_t=$t
                        if (( ${lostPackage[$t]} == 100 ))
                        then
                                timeResult[$t]=0.0
                        fi
                elif (( ${lostPackage[$t]} == 100 ))
                then
                        timeResult[$t]=0.0
                fi
                ((t++))
        done

        awk -v o=${timeResult[0]} -v p=${timeResult[1]} -v q=${timeResult[2]} -v r=${timeResult[3]} 'BEGIN{b[0]=o;b[1]=p;b[2]=q;b[3]=r;for(i in b){print i,b[i] | "sort -n -k2";}}' > /tmp/a.txt
        minMaster=$(cat /tmp/a.txt | awk '{if(NR==1)print $1}')
        midMaster=$(cat /tmp/a.txt | awk '{if(NR==2)print $1}')
        middleMaster=$(cat /tmp/a.txt | awk '{if(NR==3)print $1}')
        maxMaster=$(cat /tmp/a.txt | awk '{if(NR==4)print $1}')
        if (( $minMaster == 0 ))
        then
                if (( $midMaster == 1 ))
                then
			if (( $middleMaster == 2 ))
			then
                        	echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ֱ��" >> /tmp/b.txt
                        	echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ά��" >> /tmp/b.txt
                        	echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ����" >> /tmp/b.txt
                        	echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ���ŷ�" >> /tmp/b.txt
                	else
                        	echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ֱ��" >> /tmp/b.txt
                        	echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ά��" >> /tmp/b.txt
                        	echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ���ŷ�" >> /tmp/b.txt
                        	echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ����" >> /tmp/b.txt
                	fi
		elif (( $midMaster == 2 ))
		then
			if (( $middleMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ���ŷ�" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ά��" >> /tmp/b.txt
                        fi
		else
			if (( $middleMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ����" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ά��" >> /tmp/b.txt
                        fi
		fi
        elif (( $midMaster == 0 ))
        then
                if (( $minMaster == 1 ))
                then
			if (( $middleMaster == 2 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ���ŷ�" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ����" >> /tmp/b.txt
                        fi
                elif (( $minMaster == 2 ))
		then
			if (( $middleMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ���ŷ�" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ά��" >> /tmp/b.txt
                        fi
		else
			if (( $middleMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ����" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ά��" >> /tmp/b.txt
                        fi
                fi
	elif (( $middleMaster == 0 ))
        then
                if (( $minMaster == 1 ))
                then
                        if (( $midMaster == 2 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ���ŷ�" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ����" >> /tmp/b.txt
                        fi
                elif (( $minMaster == 2 ))
                then
                        if (( $midMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ���ŷ�" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ά��" >> /tmp/b.txt
                        fi
                else
                        if (( $midMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ����" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ά��" >> /tmp/b.txt
                        fi
                fi
        else
		if (( $minMaster == 1 ))
                then
                        if (( $midMaster == 2 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ֱ��" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ֱ��" >> /tmp/b.txt
                        fi
                elif (( $minMaster == 2 ))
                then
                        if (( $midMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ֱ��" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ֱ��" >> /tmp/b.txt
                        fi
                else
                        if (( $midMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ֱ��" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} ֱ��" >> /tmp/b.txt
                        fi
                fi
        fi
        /usr/bin/paste /tmp/a.txt /tmp/b.txt | awk 'BEGIN{printf "%-15s%-10s%-20s%-10s\n","����ʱ��","������","IP��ַ","����"}{b[y++]=$2;c[z++]=$3;d[t++]=$4;e[k++]=$5}END{for(i in b)printf "%-15s%-10s%-20s%-10s\n",b[i]"ms",c[i]"%",d[i],e[i]}' > /tmp/c.txt
        rm -f /tmp/b.txt &> /dev/null
        if (( $minMaster == $current_t ))
        then
                if [[ "${timeResult[$minMaster]}" != "0.0" ]]
                then
                        echo "$NowTime SCH_MASTER ��ǰ $current_master is the best" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        if [[ "${timeResult[$midMaster]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMaster=1
                                jmpaddrMaster=${master_ip[$midMaster]}
                                jmpportMaster=${master_port[$midMaster]}
			elif [[ "${timeResult[$middleMaster]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMaster=1
                                jmpaddrMaster=${master_ip[$middleMaster]}
                                jmpportMaster=${master_port[$middleMaster]}
                        elif [[ "${timeResult[$maxMaster]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMaster=1
                                jmpaddrMaster=${master_ip[$maxMaster]}
                                jmpportMaster=${master_port[$maxMaster]}
                        else
                                echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER all is down" >> log/CheckNet.$(date +%Y%m%d).log
                        fi
                fi
        elif (( $midMaster == $current_t ))
        then
                if [[ "${timeResult[$midMaster]}" != "0.0" ]]
                then
                        if [[ "${timeResult[$minMaster]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                ((countMaster++))
                                if (( $countMaster == $countMax ))
                                then
                                        jmpaddrMaster=${master_ip[$minMaster]}
                                        jmpportMaster=${master_port[$minMaster]}
                                fi
                        else
                                echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                        fi
                else
                        if [[ "${timeResult[$middleMaster]}" == "0.0" ]]
                        then
				if [[ "${timeResult[$maxMaster]}" == "0.0" ]]
				then
                                	echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                	cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                	echo "$NowTime SCH_MASTER all is down" >> log/CheckNet.$(date +%Y%m%d).log
				else
					echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                	cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                	echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                	nowjmpMaster=1
                                	jmpaddrMaster=${master_ip[$maxMaster]}
                                	jmpportMaster=${master_port[$maxMaster]}
				fi
                        else
                                echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMaster=1
                                jmpaddrMaster=${master_ip[$middleMaster]}
                                jmpportMaster=${master_port[$middleMaster]}
                        fi
                fi
	elif (( $middleMaster == $current_t ))
        then
                if [[ "${timeResult[$middleMaster]}" != "0.0" ]]
                then
                        if [[ "${timeResult[$minMaster]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                ((countMaster++))
                                if (( $countMaster == $countMax ))
                                then
                                        jmpaddrMaster=${master_ip[$minMaster]}
                                        jmpportMaster=${master_port[$minMaster]}
                                fi
                        else
				if [[ "${timeResult[$midMaster]}" != "0.0" ]]
				then
					echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                	cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                	echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                	((countMaster++))
                                	if (( $countMaster == $countMax ))
                                	then
                                        	jmpaddrMaster=${master_ip[$midMaster]}
                                        	jmpportMaster=${master_port[$midMaster]}
                                	fi
				else
                                	echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
				fi
                        fi
                else
                	if [[ "${timeResult[$maxMaster]}" == "0.0" ]]
                        then
                        	echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER all is down" >> log/CheckNet.$(date +%Y%m%d).log
                        else
                                echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMaster=1
                                jmpaddrMaster=${master_ip[$maxMaster]}
                                jmpportMaster=${master_port[$maxMaster]}
                        fi
                fi
        else
		if [[ "${timeResult[$maxMaster]}" == "0.0" ]]
                then
                	echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                        echo "$NowTime SCH_MASTER all is down" >> log/CheckNet.$(date +%Y%m%d).log
                else
			if [[ "${timeResult[$minMaster]}" == "0.0" ]]
			then
				if [[ "${timeResult[$midMaster]}" == "0.0" ]]
				then
					if [[ "${timeResult[$middleMaster]}" == "0.0" ]]
					then	
                        			echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
					else
						echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                        	cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                        	echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                        	((countMaster++))
                                        	if (( $countMaster == $countMax ))
                                        	then
                                                	jmpaddrMaster=${master_ip[$middleMaster]}
                                                	jmpportMaster=${master_port[$middleMaster]}
                                        	fi
					fi
				else
					echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                        echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                        ((countMaster++))
                                        if (( $countMaster == $countMax ))
                                        then
                                        	jmpaddrMaster=${master_ip[$midMaster]}
                                                jmpportMaster=${master_port[$midMaster]}
                                        fi
                                fi
			else
				echo "$NowTime SCH_MASTER ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER ��ǰ $current_master:$current_master_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                ((countMaster++))
                                if (( $countMaster == $countMax ))
                                then
                                	jmpaddrMaster=${master_ip[$midMaster]}
                                        jmpportMaster=${master_port[$midMaster]}
                                fi
                        fi
                fi
        fi
}

ping_mon(){
        t=0
        for j in $(echo ${mon_ip[@]})
        do
                ping -c1 -s $BuffSize $j > /tmp/ping.txt
                lostPackage[$t]=$(cat /tmp/ping.txt | awk -F "[% ]" '/%/{print $6}')
                timeResult[$t]=$(cat /tmp/ping.txt | awk -F "[= ]" '/time=/{print $10}')
                if [[ "$j" == "$current_mon" ]]
                then
                        current_t=$t
                        if (( ${lostPackage[$t]} == 100 ))
                        then
                                timeResult[$t]=0.0
                        fi
                elif (( ${lostPackage[$t]} == 100 ))
                then
                        timeResult[$t]=0.0
                fi
                ((t++))
        done

        awk -v o=${timeResult[0]} -v p=${timeResult[1]} -v q=${timeResult[2]} -v r=${timeResult[3]} 'BEGIN{b[0]=o;b[1]=p;b[2]=q;b[3]=r;for(i in b){print i,b[i] | "sort -n -k2";}}' > /tmp/a.txt
        minMon=$(cat /tmp/a.txt | awk '{if(NR==1)print $1}')
        midMon=$(cat /tmp/a.txt | awk '{if(NR==2)print $1}')
        middleMon=$(cat /tmp/a.txt | awk '{if(NR==3)print $1}')
        maxMon=$(cat /tmp/a.txt | awk '{if(NR==4)print $1}')
        if (( $minMon == 0 ))
        then
                if (( $midMon == 1 ))
                then
                        if (( $middleMon == 2 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ���ŷ�" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ����" >> /tmp/b.txt
                        fi
                elif (( $midMon == 2 ))
                then
                        if (( $middleMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ���ŷ�" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ά��" >> /tmp/b.txt
                        fi
                else
                        if (( $middleMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ����" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ά��" >> /tmp/b.txt
                        fi
                fi
        elif (( $midMon == 0 ))
        then
                if (( $minMon == 1 ))
                then
                        if (( $middleMon == 2 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ���ŷ�" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ����" >> /tmp/b.txt
                        fi
                elif (( $minMon == 2 ))
                then
                        if (( $middleMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ���ŷ�" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ά��" >> /tmp/b.txt
                        fi
                else
                        if (( $middleMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ����" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ά��" >> /tmp/b.txt
                        fi
                fi
        elif (( $middleMon == 0 ))
        then
                if (( $minMon == 1 ))
                then
                        if (( $midMon == 2 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ���ŷ�" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ����" >> /tmp/b.txt
                        fi
                elif (( $minMon == 2 ))
                then
                        if (( $midMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ���ŷ�" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ά��" >> /tmp/b.txt
                        fi
                else
                        if (( $midMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ����" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ֱ��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ά��" >> /tmp/b.txt
                        fi
                fi
        else
                if (( $minMon == 1 ))
                then
                        if (( $midMon == 2 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ֱ��" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ֱ��" >> /tmp/b.txt
                        fi
                elif (( $minMon == 2 ))
                then
                        if (( $midMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ֱ��" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ֱ��" >> /tmp/b.txt
                        fi
                else
                        if (( $midMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ֱ��" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} ���ŷ�" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} ����" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} ά��" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} ֱ��" >> /tmp/b.txt
                        fi
                fi
        fi
        /usr/bin/paste /tmp/a.txt /tmp/b.txt | awk 'BEGIN{printf "%-15s%-10s%-20s%-10s\n","����ʱ��","������","IP��ַ","����"}{b[y++]=$2;c[z++]=$3;d[t++]=$4;e[k++]=$5}END{for(i in b)printf "%-15s%-10s%-20s%-10s\n",b[i]"ms",c[i]"%",d[i],e[i]}' > /tmp/c.txt
        rm -f /tmp/b.txt &> /dev/null
        if (( $minMon == $current_t ))
        then
                if [[ "${timeResult[$minMon]}" != "0.0" ]]
                then
                        echo "$NowTime SCH_MON current $current_mon:$current_mon_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        if [[ "${timeResult[$midMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip[$midMon]}
                                jmpportMon=${mon_port[$midMon]}
                        elif [[ "${timeResult[$middleMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip[$middleMon]}
                                jmpportMon=${mon_port[$middleMon]}
                        elif [[ "${timeResult[$maxMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip[$maxMon]}
                                jmpportMon=${mon_port[$maxMon]}
                        else
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON all is down" >> log/CheckNet.$(date +%Y%m%d).log
                        fi
                fi
        elif (( $midMon == $current_t ))
        then
                if [[ "${timeResult[$midMon]}" != "0.0" ]]
                then
                        if [[ "${timeResult[$minMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                ((countMon++))
                                if (( $countMon == $countMax ))
                                then
                                        jmpaddrMon=${mon_ip[$minMon]}
                                        jmpportMon=${mon_port[$minMon]}
                                fi
                        else
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                        fi
                else
                        if [[ "${timeResult[$middleMon]}" == "0.0" ]]
                        then
                                if [[ "${timeResult[$maxMon]}" == "0.0" ]]
                                then
                                        echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                        echo "$NowTime SCH_MON all is down" >> log/CheckNet.$(date +%Y%m%d).log
                                else
                                        echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                        echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                        nowjmpMon=1
                                        jmpaddrMon=${mon_ip[$maxMon]}
                                        jmpportMon=${mon_port[$maxMon]}
                                fi
                        else
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip[$middleMon]}
                                jmpportMon=${mon_port[$middleMon]}
                        fi
                fi
        elif (( $middleMon == $current_t ))
        then
                if [[ "${timeResult[$middleMon]}" != "0.0" ]]
                then
                        if [[ "${timeResult[$minMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                ((countMon++))
                                if (( $countMon == $countMax ))
                                then
                                        jmpaddrMon=${mon_ip[$minMon]}
                                        jmpportMon=${mon_port[$minMon]}
                                fi
                        else
                                if [[ "${timeResult[$midMon]}" != "0.0" ]]
                                then
                                        echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                        echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                        ((countMon++))
                                        if (( $countMon == $countMax ))
                                        then
                                                jmpaddrMon=${mon_ip[$midMon]}
                                                jmpportMon=${mon_port[$midMon]}
                                        fi
                                else
                                        echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                                fi
                        fi
                else
                        if [[ "${timeResult[$maxMon]}" == "0.0" ]]
                        then
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON all is down" >> log/CheckNet.$(date +%Y%m%d).log
                        else
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip[$maxMon]}
                                jmpportMon=${mon_port[$maxMon]}
                        fi
                fi
        else
                if [[ "${timeResult[$maxMon]}" == "0.0" ]]
                then
                        echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                        echo "$NowTime SCH_MON all is down" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        if [[ "${timeResult[$minMon]}" == "0.0" ]]
                        then
                                if [[ "${timeResult[$midMon]}" == "0.0" ]]
                                then
                                        if [[ "${timeResult[$middleMon]}" == "0.0" ]]
                                        then
                                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                                        else
                                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                                ((countMon++))
                                                if (( $countMon == $countMax ))
                                                then
                                                        jmpaddrMon=${mon_ip[$middleMon]}
                                                        jmpportMon=${mon_port[$middleMon]}
                                                fi
                                        fi
                                else
                                        echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                        echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                        ((countMon++))
                                        if (( $countMon == $countMax ))
                                        then
                                                jmpaddrMon=${mon_ip[$midMon]}
                                                jmpportMon=${mon_port[$midMon]}
                                        fi
                                fi
                        else
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                ((countMon++))
                                if (( $countMon == $countMax ))
                                then
                                        jmpaddrMon=${mon_ip[$midMon]}
                                        jmpportMon=${mon_port[$midMon]}
                                fi
                        fi
                fi
        fi
}

#�����������
ping_mon_v(){
        t=0
        for j in $(echo ${mon_ip_v[@]})
        do
                ping -c1 -s $BuffSize $j > /tmp/ping.txt
                lostPackage[$t]=$(cat /tmp/ping.txt | awk -F "[% ]" '/%/{print $6}')
                timeResult[$t]=$(cat /tmp/ping.txt | awk -F "[= ]" '/time=/{print $10}')
                if [[ "$j" == "$current_mon" ]]
                then
                        current_t=$t
                        if (( ${lostPackage[$t]} == 100 ))
                        then
                                timeResult[$t]=0.0
                        fi
                elif (( ${lostPackage[$t]} == 100 ))
                then
                        timeResult[$t]=0.0
                fi
                ((t++))
        done

        awk -v o=${timeResult[0]} -v p=${timeResult[1]} -v q=${timeResult[2]} 'BEGIN{b[0]=o;b[1]=p;b[2]=q;for(i in b){print i,b[i] | "sort -n -k2";}}' > /tmp/a.txt
        minMon=$(cat /tmp/a.txt | awk '{if(NR==1)print $1}')
        middleMon=$(cat /tmp/a.txt | awk '{if(NR==2)print $1}')
        maxMon=$(cat /tmp/a.txt | awk '{if(NR==3)print $1}')
        if (( $minMon == 0 ))
        then
                if (( $middleMon == 1 ))
                then
                        echo "${lostPackage[$minMon]} ${mon_ip_v[$minMon]} ֱ��" >> /tmp/b.txt
                        echo "${lostPackage[$middleMon]} ${mon_ip_v[$middleMon]} ά��" >> /tmp/b.txt
                        echo "${lostPackage[$maxMon]} ${mon_ip_v[$maxMon]} ���ŷ�" >> /tmp/b.txt
                else
                        echo "${lostPackage[$minMon]} ${mon_ip_v[$minMon]} ֱ��" >> /tmp/b.txt
                        echo "${lostPackage[$middleMon]} ${mon_ip_v[$middleMon]} ���ŷ�" >> /tmp/b.txt
                        echo "${lostPackage[$maxMon]} ${mon_ip_v[$maxMon]} ά��" >> /tmp/b.txt
                fi
        elif (( $middleMon == 0 ))
        then
                if (( $minMon == 1 ))
                then
                        echo "${lostPackage[$minMon]} ${mon_ip_v[$minMon]} ά��" >> /tmp/b.txt
                        echo "${lostPackage[$middleMon]} ${mon_ip_v[$middleMon]} ֱ��" >> /tmp/b.txt
                        echo "${lostPackage[$maxMon]} ${mon_ip_v[$maxMon]} ���ŷ�" >> /tmp/b.txt
                else
                        echo "${lostPackage[$minMon]} ${mon_ip_v[$minMon]} ���ŷ�" >> /tmp/b.txt
                        echo "${lostPackage[$middleMon]} ${mon_ip_v[$middleMon]} ֱ��" >> /tmp/b.txt
                        echo "${lostPackage[$maxMon]} ${mon_ip_v[$maxMon]} ά��" >> /tmp/b.txt
                fi
        else
                if (( $minMon == 1 ))
                then
                        echo "${lostPackage[$minMon]} ${mon_ip_v[$minMon]} ά��" >> /tmp/b.txt
                        echo "${lostPackage[$middleMon]} ${mon_ip_v[$middleMon]} ���ŷ�" >> /tmp/b.txt
                        echo "${lostPackage[$maxMon]} ${mon_ip_v[$maxMon]} ֱ��" >> /tmp/b.txt
                else
                        echo "${lostPackage[$minMon]} ${mon_ip_v[$minMon]} ���ŷ�" >> /tmp/b.txt
                        echo "${lostPackage[$middleMon]} ${mon_ip_v[$middleMon]} ά��" >> /tmp/b.txt
                        echo "${lostPackage[$maxMon]} ${mon_ip_v[$maxMon]} ֱ��" >> /tmp/b.txt
                fi
        fi
        /usr/bin/paste /tmp/a.txt /tmp/b.txt | awk 'BEGIN{printf "%-15s%-10s%-20s%-10s\n","����ʱ��","������","IP��ַ","����"}{b[y++]=$2;c[z++]=$3;d[t++]=$4;e[k++]=$5}END{for(i in b)printf "%-15s%-10s%-20s%-10s\n",b[i]"ms",c[i]"%",d[i],e[i]}' > /tmp/c.txt
        rm -f /tmp/b.txt &> /dev/null
        if (( $minMon == $current_t ))
        then
                if [[ "${timeResult[$minMon]}" != "0.0" ]]
                then
                        echo "$NowTime SCH_MON ��ǰ $current_mon is the best" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        if [[ "${timeResult[$middleMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip_v[$middleMon]}
                                jmpportMon=${mon_port_v[$middleMon]}
                        elif [[ "${timeResult[$maxMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip_v[$maxMon]}
                                jmpportMon=${mon_port_v[$maxMon]}
                        else
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON all is down" >> log/CheckNet.$(date +%Y%m%d).log
                        fi
                fi
        elif (( $middleMon == $current_t ))
        then
                if [[ "${timeResult[$middleMon]}" != "0.0" ]]
                then
                        if [[ "${timeResult[$minMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                ((countMon++))
                                if (( $countMon == $countMax ))
                                then
                                        jmpaddrMon=${mon_ip_v[$minMon]}
                                        jmpportMon=${mon_port_v[$minMon]}
                                fi
                        else
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                        fi
                else
                        if [[ "${timeResult[$maxMon]}" == "0.0" ]]
                        then
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON all is down" >> log/CheckNet.$(date +%Y%m%d).log
                        else
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip_v[$maxMon]}
                                jmpportMon=${mon_port_v[$maxMon]}
                        fi
                fi
        else
                if [[ "${timeResult[$middleMon]}" != "0.0" ]]
                then
                        echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                        echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                        if [[ "${timeResult[$minMon]}" != "0.0" ]]
                        then
                                ((countMon++))
                                if (( $countMon == $countMax ))
                                then
                                        jmpaddrMon=${mon_ip_v[$minMon]}
                                        jmpportMon=${mon_port_v[$minMon]}
                                fi
                        else
                                ((countMon++))
                                if (( $countMon == $countMax ))
                                then
                                        jmpaddrMon=${mon_ip_v[$middleMon]}
                                        jmpportMon=${mon_port_v[$middleMon]}
                                fi
                        fi
                else
                        if [[ "${timeResult[$maxMon]}" == "0.0" ]]
                        then
                                echo "$NowTime SCH_MON ������·״̬���£�" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON all is down" >> log/CheckNet.$(date +%Y%m%d).log
                        else
                                echo "$NowTime SCH_MON ��ǰ $current_mon:$current_mon_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                        fi
                fi
        fi
}

#�޸�iptablesʵ�������л�
change_iptables(){
        linenumMaster=$(/sbin/iptables -t nat -L OUTPUT --line-num -n | grep "${master_mon_ip[0]}" | grep "dpt:${master_mon_port[0]}" | awk '{print $1}')
        linenumMon=$(/sbin/iptables -t nat -L OUTPUT --line-num -n | grep "${master_mon_ip[1]}" | grep "dpt:${master_mon_port[1]}" | awk '{print $1}')
        if [[ "$1" == "${master_ip[0]}" && "$2" == "${master_port[0]}" ]]
        then
                /sbin/iptables -t nat -D OUTPUT $linenumMaster
                (( $?==0 )) && echo "$NowTime SCH_MASTER /sbin/iptables -t nat -D OUTPUT $linenumMaster" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MASTER /sbin/iptables -t nat -D OUTPUT $linenumMaster failed" >> log/CheckNet.$(date +%Y%m%d).log
        elif [[ "$1" == "${mon_ip[0]}" && "$2" == "${mon_port[0]}" ]]
        then
                /sbin/iptables -t nat -D OUTPUT $linenumMon
                (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon failed" >> log/CheckNet.$(date +%Y%m%d).log
        elif [[ "$1" == "${master_ip[1]}" && "$2" == "${master_port[1]}" ]]
        then
                if (( $tiaozhuanMaster == 1 ))
                then
                        /sbin/iptables -t nat -D OUTPUT $linenumMaster
                        (( $?==0 )) && echo "$NowTime SCH_MASTER /sbin/iptables -t nat -D OUTPUT $linenumMaster" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MASTER /sbin/iptables -t nat -D OUTPUT $linenumMaster failed" >> log/CheckNet.$(date +%Y%m%d).log
                        /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MASTER /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MASTER /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MASTER /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MASTER /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                fi
        elif [[ "$1" == "${mon_ip[1]}" && "$2" == "${mon_port[1]}" ]]
        then
                if (( $tiaozhuanMon == 1 ))
                then
                        /sbin/iptables -t nat -D OUTPUT $linenumMon
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon failed" >> log/CheckNet.$(date +%Y%m%d).log
                        /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                fi
        elif [[ "$1" == "${master_ip[2]}" && "$2" == "${master_port[2]}" ]]
        then
                if (( $tiaozhuanMaster == 1 ))
                then
                        /sbin/iptables -t nat -D OUTPUT $linenumMaster
                        (( $?==0 )) && echo "$NowTime SCH_MASTER /sbin/iptables -t nat -D OUTPUT $linenumMaster" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MASTER /sbin/iptables -t nat -D OUTPUT $linenumMaster failed" >> log/CheckNet.$(date +%Y%m%d).log
                        /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MASTER /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MASTER /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MASTER /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MASTER /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                fi
        elif [[ "$1" == "${mon_ip[2]}" && "$2" == "${mon_port[2]}" ]]
        then
                if (( $tiaozhuanMon == 1 ))
                then
                        /sbin/iptables -t nat -D OUTPUT $linenumMon
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon failed" >> log/CheckNet.$(date +%Y%m%d).log
                        /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                fi
        elif [[ "$1" == "${master_ip[3]}" && "$2" == "${master_port[3]}" ]]
        then
                if (( $tiaozhuanMaster == 1 ))
                then
                        /sbin/iptables -t nat -D OUTPUT $linenumMaster
                        (( $?==0 )) && echo "$NowTime SCH_MASTER /sbin/iptables -t nat -D OUTPUT $linenumMaster" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MASTER /sbin/iptables -t nat -D OUTPUT $linenumMaster failed" >> log/CheckNet.$(date +%Y%m%d).log
                        /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MASTER /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MASTER /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MASTER /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MASTER /sbin/iptables -t nat -I OUTPUT -d ${master_ip[0]} -p tcp --dport ${master_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                fi
        elif [[ "$1" == "${mon_ip[3]}" && "$2" == "${mon_port[3]}" ]]
        then
                if (( $tiaozhuanMon == 1 ))
                then
                        /sbin/iptables -t nat -D OUTPUT $linenumMon
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon failed" >> log/CheckNet.$(date +%Y%m%d).log
                        /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                fi
        fi
}

#�����������
change_iptables_mon(){
        linenumMon=$(/sbin/iptables -t nat -L OUTPUT --line-num -n | grep "${master_mon_ip[1]}" | grep "dpt:${master_mon_port[1]}" | awk '{print $1}')
        if [[ "$1" == "${mon_ip_v[0]}" && "$2" == "${mon_port_v[0]}" ]]
        then
                /sbin/iptables -t nat -D OUTPUT $linenumMon
                (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon failed" >> log/CheckNet.$(date +%Y%m%d).log
        elif [[ "$1" == "${mon_ip_v[1]}" && "$2" == "${mon_port_v[1]}" ]]
        then
                if (( $tiaozhuanMon == 1 ))
                then
                        /sbin/iptables -t nat -D OUTPUT $linenumMon
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon failed" >> log/CheckNet.$(date +%Y%m%d).log
                        /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                fi
        elif [[ "$1" == "${mon_ip_v[2]}" && "$2" == "${mon_port_v[2]}" ]]
        then
                if (( $tiaozhuanMon == 1 ))
                then
                        /sbin/iptables -t nat -D OUTPUT $linenumMon
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -D OUTPUT $linenumMon failed" >> log/CheckNet.$(date +%Y%m%d).log
                        /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2
                        (( $?==0 )) && echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2" >> log/CheckNet.$(date +%Y%m%d).log || echo "$NowTime SCH_MON /sbin/iptables -t nat -I OUTPUT -d ${mon_ip[0]} -p tcp --dport ${mon_port[0]} -j DNAT --to $1:$2 failed" >> log/CheckNet.$(date +%Y%m%d).log
                fi
        fi
}

#������
main(){
        while true
        do
                NowTime=$(date  +"%Y-%m-%d %T")
		CheckTime=$(date +%H)
		#ÿ������22�����һ��remove_logfile��������⵱���ǲ���ÿ�µ�27�ţ�����������ǰһ���µ���־�ļ�
		if (( $CheckTime==22 && $checkflag==0 ))
		then
			checkflag=1
			remove_logfile
		fi
		if (( $CheckTime==23 && $checkflag==1 ))
		then
			checkflag=0
		fi
                xianlu_check
		ping_master
                if (( $nowjmpMaster == 1 ))
                then
                	countMaster=0
                       	change_iptables $jmpaddrMaster $jmpportMaster
                        nowjmpMaster=0
                elif (( $countMaster == $countMax ))
                then
                        countMaster=0
                        change_iptables $jmpaddrMaster $jmpportMaster
                fi
		if (( $system_num==20 ))
                then
                        ping_mon
                        if (( $nowjmpMon == 1 ))
                        then
                                countMon=0
                                change_iptables $jmpaddrMon $jmpportMon
				nowjmpMon=0
                        elif (( $countMon == $countMax ))
                        then
                                countMon=0
                                change_iptables $jmpaddrMon $jmpportMon
                        fi
                else
                        ping_mon_v
                        if (( $nowjmpMon == 1 ))
                        then
                        	countMon=0
                                change_iptables_mon $jmpaddrMon $jmpportMon
				nowjmpMon=0
                        elif (( $countMon == $countMax ))
                        then
                                countMon=0
                                change_iptables_mon $jmpaddrMon $jmpportMon
                        fi
                fi
                echo -ne "\n" >> log/CheckNet.$(date +%Y%m%d).log
                sleep 120
        done
}

main

