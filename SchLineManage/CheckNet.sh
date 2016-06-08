#!/bin/bash
###############################################################
#  AUTHOR：luc                                                #
#  DATE：2015-07-06                                           #
#  VERSION：CheckNet.sh_20150706_lastest                      #
#  FUNCTION：每隔一分钟分别检测拨号器当前所连接的MASTER和MON  #
#            的链路状态，经过比较若不是最优链路并且达到3次则  #
#            智能切换到最优链路（直连、维用、汕头）。         #
#  THINKS：比较丢包率（通与不通）和返回时间（选出最优）       #
#          ping -c1 -s 2048 ip                                #
#          1、丢包率为100%则立即切换（无需再达到3次才切换）   #
#          2、丢包率为0%则比较时间（需达到3次再进行切换）     #
###############################################################


configPath="/usr/local/007ka/etc/schedule.ini" #拨号器配置文件
current_master=""       #当前MASTER地址
current_master_port=""  #当前MASTER端口
current_mon=""          #当前MON地址
current_mon_port=""     #当前MON端口
linenumMaster=0         #当前IPTABLES中配置的MASTER的行号
linenumMon=0            #当前IPTABLES中配置的MON的行号
linenumMonV=0           #当前IPTABLES中配置的MON的行号
BuffSize=2048           #测试链路的PING包的大小
countMax=3              #非最优链路阀值
countMaster=0           #记录当前MASTER非最优链路次数
nowjmpMaster=0          #记录当前MASTER链路是否DOWN
jmpaddrMaster=""        #MASTER跳转地址
jmpportMaster=""        #MASTER跳转端口
countMon=0              #记录当前MON非最优链路次数
countMonV=0             #记录当前MON非最优链路次数
nowjmpMon=0             #记录当前MON链路是否DOWN
jmpaddrMon=""           #MON跳转地址
jmpportMon=""           #MON跳转端口
timeResult=()           #记录每条链路PING包返回时间值
lostPackage=()          #记录每天链路PING包的丢包率
tiaozhuanMaster=0       #判断当前MASTER是不是跳转线路
tiaozhuanMon=0          #判断当前MON是不是跳转线路
checkflag=0		#定时检测时间清理日志文件标志
mastercount=0           #MASTER切换次数
moncount=0              #MON切换次数

#自动清理前一个月的日志文件
remove_logfile(){
{
date_day=$(date +%d)
if (( $date_day==27 ))
then
        dir="/usr/local/007ka/SchLineManage/lu-test/log"
        log_date_file=$(date -d "-1 month" +%Y%m) #获取到一个月之前的月份目录
        wc_file=$(ls $dir/*$log_date_file* | wc -l)
        if (( $wc_file!=0 ))
        then
                rm -f $dir/*$log_date_file*
        fi
fi
} &> /dev/null
}

#从配置文件中获取MASTER和MON的地址以及端口
master_mon_ip[0]=$(awk -F "[=:]" '/SCH_MASTER_ADDR/{print $2}' $configPath)
master_mon_ip[1]=$(awk -F "[=:]" '/SCH_MON_SRV_ADDR/{print $2}' $configPath)
master_mon_port[0]=$(awk -F "[=:]" '/SCH_MASTER_ADDR/{print $3}' $configPath)
master_mon_port[1]=$(awk -F "[=:]" '/SCH_MON_SRV_ADDR/{print $3}' $configPath)

#获取拨号器所在的系统
system_num=$(ls -lh $configPath | awk -F '.' '{print $4}')
#从jmpIP.config.??中获取跳转地址和端口
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

#以“直连、维用、互盟”顺序存在数组中
master_ip=(${master_mon_ip[0]} ${jmp_master_ip[@]})
master_port=(${master_mon_port[0]} ${jmp_master_port[@]})
mon_ip=(${master_mon_ip[1]} ${jmp_mon_ip[@]})
mon_port=(${master_mon_port[1]} ${jmp_mon_port[@]})
mon_ip_v=(${master_mon_ip[1]} ${jmp_mon_ip[0]} ${jmp_mon_ip[2]})
mon_port_v=(${master_mon_port[1]} ${jmp_mon_port[0]} ${jmp_mon_port[2]})

#检测MASTER和MON当前所连接的链路
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
                                echo "$NowTime SCH_MASTER 直连 ${master_mon_ip[0]}:${master_mon_port[0]}" >> log/CheckNet.$(date +%Y%m%d).log
				echo "$NowTime SCH_MASTER 0 $mastercount ${master_mon_ip[0]}:${master_mon_port[0]} $sch_master_addr" > master.txt
                                current_master=${master_mon_ip[0]}
                                current_master_port=${master_mon_port[0]}
                        else
                                tiaozhuanMaster=1
				first=$(echo ${iptables_ip} | awk -F "." '{print $1}')
				if (( $first==58 && ${iptables_ip_port}==${master_port[1]} ))
				then
					echo "$NowTime SCH_MASTER 1 $mastercount $iptables_ip:$iptables_ip_port $sch_master_addr" > master.txt
                                	echo "$NowTime SCH_MASTER 跳线 维用 $iptables_ip:$iptables_ip_port" >> log/CheckNet.$(date +%Y%m%d).log
				elif (( $first==183 && ${iptables_ip_port}==${master_port[3]} ))
				then
					echo "$NowTime SCH_MASTER 3 $mastercount $iptables_ip:$iptables_ip_port $sch_master_addr" > master.txt
                                	echo "$NowTime SCH_MASTER 跳线 深信服 $iptables_ip:$iptables_ip_port" >> log/CheckNet.$(date +%Y%m%d).log
				else
					echo "$NowTime SCH_MASTER 2 $mastercount $iptables_ip:$iptables_ip_port $sch_master_addr" > master.txt
                                	echo "$NowTime SCH_MASTER 跳线 互盟 $iptables_ip:$iptables_ip_port" >> log/CheckNet.$(date +%Y%m%d).log
				fi
                                current_master=$iptables_ip
                                current_master_port=$iptables_ip_port
                        fi
                else
                        if [[ "$iptables_ip" == "" ]]
                        then
                                tiaozhuanMon=0
                                echo "$NowTime SCH_MON 直连 ${master_mon_ip[1]}:${master_mon_port[1]}" >> log/CheckNet.$(date +%Y%m%d).log
				echo "$NowTime SCH_MON 0 $moncount ${master_mon_ip[1]}:${master_mon_port[1]} $sch_mon_srv_addr" > mon.txt
                                current_mon=${master_mon_ip[1]}
                                current_mon_port=${master_mon_port[1]}
                        else
                                tiaozhuanMon=1
				first=$(echo ${iptables_ip} | awk -F "." '{print $1}')
				if (( $first==58 && ${iptables_ip_port}==${mon_port[1]} ))
                                then
                                	echo "$NowTime SCH_MON 1 $moncount $iptables_ip:$iptables_ip_port $sch_mon_srv_addr" > mon.txt
                               		echo "$NowTime SCH_MON 跳线 维用 $iptables_ip:$iptables_ip_port" >> log/CheckNet.$(date +%Y%m%d).log
				elif (( $first==183 && ${iptables_ip_port}==${mon_port[3]} ))
				then
					echo "$NowTime SCH_MON 3 $moncount $iptables_ip:$iptables_ip_port $sch_mon_srv_addr" > mon.txt
                                        echo "$NowTime SCH_MON 跳线 深信服 $iptables_ip:$iptables_ip_port" >> log/CheckNet.$(date +%Y%m%d).log	
				else
					echo "$NowTime SCH_MON 2 $moncount $iptables_ip:$iptables_ip_port $sch_mon_srv_addr" > mon.txt
                                     	echo "$NowTime SCH_MON 跳线 互盟 $iptables_ip:$iptables_ip_port" >> log/CheckNet.$(date +%Y%m%d).log
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

#检测MASTER
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
                        	echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 直连" >> /tmp/b.txt
                        	echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 维用" >> /tmp/b.txt
                        	echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 互盟" >> /tmp/b.txt
                        	echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 深信服" >> /tmp/b.txt
                	else
                        	echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 直连" >> /tmp/b.txt
                        	echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 维用" >> /tmp/b.txt
                        	echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 深信服" >> /tmp/b.txt
                        	echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 互盟" >> /tmp/b.txt
                	fi
		elif (( $midMaster == 2 ))
		then
			if (( $middleMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 深信服" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 维用" >> /tmp/b.txt
                        fi
		else
			if (( $middleMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 互盟" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 维用" >> /tmp/b.txt
                        fi
		fi
        elif (( $midMaster == 0 ))
        then
                if (( $minMaster == 1 ))
                then
			if (( $middleMaster == 2 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 深信服" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 互盟" >> /tmp/b.txt
                        fi
                elif (( $minMaster == 2 ))
		then
			if (( $middleMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 深信服" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 维用" >> /tmp/b.txt
                        fi
		else
			if (( $middleMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 互盟" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 维用" >> /tmp/b.txt
                        fi
                fi
	elif (( $middleMaster == 0 ))
        then
                if (( $minMaster == 1 ))
                then
                        if (( $midMaster == 2 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 深信服" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 互盟" >> /tmp/b.txt
                        fi
                elif (( $minMaster == 2 ))
                then
                        if (( $midMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 深信服" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 维用" >> /tmp/b.txt
                        fi
                else
                        if (( $midMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 互盟" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 维用" >> /tmp/b.txt
                        fi
                fi
        else
		if (( $minMaster == 1 ))
                then
                        if (( $midMaster == 2 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 直连" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 直连" >> /tmp/b.txt
                        fi
                elif (( $minMaster == 2 ))
                then
                        if (( $midMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 直连" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 直连" >> /tmp/b.txt
                        fi
                else
                        if (( $midMaster == 1 ))
                        then
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 直连" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMaster]} ${master_ip[$minMaster]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$midMaster]} ${master_ip[$midMaster]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$middleMaster]} ${master_ip[$middleMaster]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$maxMaster]} ${master_ip[$maxMaster]} 直连" >> /tmp/b.txt
                        fi
                fi
        fi
        /usr/bin/paste /tmp/a.txt /tmp/b.txt | awk 'BEGIN{printf "%-15s%-10s%-20s%-10s\n","返回时间","丢包率","IP地址","机房"}{b[y++]=$2;c[z++]=$3;d[t++]=$4;e[k++]=$5}END{for(i in b)printf "%-15s%-10s%-20s%-10s\n",b[i]"ms",c[i]"%",d[i],e[i]}' > /tmp/c.txt
        rm -f /tmp/b.txt &> /dev/null
        if (( $minMaster == $current_t ))
        then
                if [[ "${timeResult[$minMaster]}" != "0.0" ]]
                then
                        echo "$NowTime SCH_MASTER 当前 $current_master is the best" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        if [[ "${timeResult[$midMaster]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMaster=1
                                jmpaddrMaster=${master_ip[$midMaster]}
                                jmpportMaster=${master_port[$midMaster]}
			elif [[ "${timeResult[$middleMaster]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMaster=1
                                jmpaddrMaster=${master_ip[$middleMaster]}
                                jmpportMaster=${master_port[$middleMaster]}
                        elif [[ "${timeResult[$maxMaster]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMaster=1
                                jmpaddrMaster=${master_ip[$maxMaster]}
                                jmpportMaster=${master_port[$maxMaster]}
                        else
                                echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
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
                                echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                ((countMaster++))
                                if (( $countMaster == $countMax ))
                                then
                                        jmpaddrMaster=${master_ip[$minMaster]}
                                        jmpportMaster=${master_port[$minMaster]}
                                fi
                        else
                                echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                        fi
                else
                        if [[ "${timeResult[$middleMaster]}" == "0.0" ]]
                        then
				if [[ "${timeResult[$maxMaster]}" == "0.0" ]]
				then
                                	echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                	cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                	echo "$NowTime SCH_MASTER all is down" >> log/CheckNet.$(date +%Y%m%d).log
				else
					echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                	cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                	echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                	nowjmpMaster=1
                                	jmpaddrMaster=${master_ip[$maxMaster]}
                                	jmpportMaster=${master_port[$maxMaster]}
				fi
                        else
                                echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is down" >> log/CheckNet.$(date +%Y%m%d).log
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
                                echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                ((countMaster++))
                                if (( $countMaster == $countMax ))
                                then
                                        jmpaddrMaster=${master_ip[$minMaster]}
                                        jmpportMaster=${master_port[$minMaster]}
                                fi
                        else
				if [[ "${timeResult[$midMaster]}" != "0.0" ]]
				then
					echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                	cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                	echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                	((countMaster++))
                                	if (( $countMaster == $countMax ))
                                	then
                                        	jmpaddrMaster=${master_ip[$midMaster]}
                                        	jmpportMaster=${master_port[$midMaster]}
                                	fi
				else
                                	echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
				fi
                        fi
                else
                	if [[ "${timeResult[$maxMaster]}" == "0.0" ]]
                        then
                        	echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER all is down" >> log/CheckNet.$(date +%Y%m%d).log
                        else
                                echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMaster=1
                                jmpaddrMaster=${master_ip[$maxMaster]}
                                jmpportMaster=${master_port[$maxMaster]}
                        fi
                fi
        else
		if [[ "${timeResult[$maxMaster]}" == "0.0" ]]
                then
                	echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                        echo "$NowTime SCH_MASTER all is down" >> log/CheckNet.$(date +%Y%m%d).log
                else
			if [[ "${timeResult[$minMaster]}" == "0.0" ]]
			then
				if [[ "${timeResult[$midMaster]}" == "0.0" ]]
				then
					if [[ "${timeResult[$middleMaster]}" == "0.0" ]]
					then	
                        			echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
					else
						echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                        	cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                        	echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                        	((countMaster++))
                                        	if (( $countMaster == $countMax ))
                                        	then
                                                	jmpaddrMaster=${master_ip[$middleMaster]}
                                                	jmpportMaster=${master_port[$middleMaster]}
                                        	fi
					fi
				else
					echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                        echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                        ((countMaster++))
                                        if (( $countMaster == $countMax ))
                                        then
                                        	jmpaddrMaster=${master_ip[$midMaster]}
                                                jmpportMaster=${master_port[$midMaster]}
                                        fi
                                fi
			else
				echo "$NowTime SCH_MASTER 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MASTER 当前 $current_master:$current_master_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
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
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 深信服" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 互盟" >> /tmp/b.txt
                        fi
                elif (( $midMon == 2 ))
                then
                        if (( $middleMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 深信服" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 维用" >> /tmp/b.txt
                        fi
                else
                        if (( $middleMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 互盟" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 维用" >> /tmp/b.txt
                        fi
                fi
        elif (( $midMon == 0 ))
        then
                if (( $minMon == 1 ))
                then
                        if (( $middleMon == 2 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 深信服" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 互盟" >> /tmp/b.txt
                        fi
                elif (( $minMon == 2 ))
                then
                        if (( $middleMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 深信服" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 维用" >> /tmp/b.txt
                        fi
                else
                        if (( $middleMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 互盟" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 维用" >> /tmp/b.txt
                        fi
                fi
        elif (( $middleMon == 0 ))
        then
                if (( $minMon == 1 ))
                then
                        if (( $midMon == 2 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 深信服" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 互盟" >> /tmp/b.txt
                        fi
                elif (( $minMon == 2 ))
                then
                        if (( $midMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 深信服" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 维用" >> /tmp/b.txt
                        fi
                else
                        if (( $midMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 互盟" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 直连" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 维用" >> /tmp/b.txt
                        fi
                fi
        else
                if (( $minMon == 1 ))
                then
                        if (( $midMon == 2 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 直连" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 直连" >> /tmp/b.txt
                        fi
                elif (( $minMon == 2 ))
                then
                        if (( $midMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 直连" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 直连" >> /tmp/b.txt
                        fi
                else
                        if (( $midMon == 1 ))
                        then
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 直连" >> /tmp/b.txt
                        else
                                echo "${lostPackage[$minMon]} ${mon_ip[$minMon]} 深信服" >> /tmp/b.txt
                                echo "${lostPackage[$midMon]} ${mon_ip[$midMon]} 互盟" >> /tmp/b.txt
                                echo "${lostPackage[$middleMon]} ${mon_ip[$middleMon]} 维用" >> /tmp/b.txt
                                echo "${lostPackage[$maxMon]} ${mon_ip[$maxMon]} 直连" >> /tmp/b.txt
                        fi
                fi
        fi
        /usr/bin/paste /tmp/a.txt /tmp/b.txt | awk 'BEGIN{printf "%-15s%-10s%-20s%-10s\n","返回时间","丢包率","IP地址","机房"}{b[y++]=$2;c[z++]=$3;d[t++]=$4;e[k++]=$5}END{for(i in b)printf "%-15s%-10s%-20s%-10s\n",b[i]"ms",c[i]"%",d[i],e[i]}' > /tmp/c.txt
        rm -f /tmp/b.txt &> /dev/null
        if (( $minMon == $current_t ))
        then
                if [[ "${timeResult[$minMon]}" != "0.0" ]]
                then
                        echo "$NowTime SCH_MON current $current_mon:$current_mon_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        if [[ "${timeResult[$midMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip[$midMon]}
                                jmpportMon=${mon_port[$midMon]}
                        elif [[ "${timeResult[$middleMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip[$middleMon]}
                                jmpportMon=${mon_port[$middleMon]}
                        elif [[ "${timeResult[$maxMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip[$maxMon]}
                                jmpportMon=${mon_port[$maxMon]}
                        else
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
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
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                ((countMon++))
                                if (( $countMon == $countMax ))
                                then
                                        jmpaddrMon=${mon_ip[$minMon]}
                                        jmpportMon=${mon_port[$minMon]}
                                fi
                        else
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                        fi
                else
                        if [[ "${timeResult[$middleMon]}" == "0.0" ]]
                        then
                                if [[ "${timeResult[$maxMon]}" == "0.0" ]]
                                then
                                        echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                        echo "$NowTime SCH_MON all is down" >> log/CheckNet.$(date +%Y%m%d).log
                                else
                                        echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                        echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                        nowjmpMon=1
                                        jmpaddrMon=${mon_ip[$maxMon]}
                                        jmpportMon=${mon_port[$maxMon]}
                                fi
                        else
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
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
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                ((countMon++))
                                if (( $countMon == $countMax ))
                                then
                                        jmpaddrMon=${mon_ip[$minMon]}
                                        jmpportMon=${mon_port[$minMon]}
                                fi
                        else
                                if [[ "${timeResult[$midMon]}" != "0.0" ]]
                                then
                                        echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                        echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                        ((countMon++))
                                        if (( $countMon == $countMax ))
                                        then
                                                jmpaddrMon=${mon_ip[$midMon]}
                                                jmpportMon=${mon_port[$midMon]}
                                        fi
                                else
                                        echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                                fi
                        fi
                else
                        if [[ "${timeResult[$maxMon]}" == "0.0" ]]
                        then
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON all is down" >> log/CheckNet.$(date +%Y%m%d).log
                        else
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip[$maxMon]}
                                jmpportMon=${mon_port[$maxMon]}
                        fi
                fi
        else
                if [[ "${timeResult[$maxMon]}" == "0.0" ]]
                then
                        echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                        echo "$NowTime SCH_MON all is down" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        if [[ "${timeResult[$minMon]}" == "0.0" ]]
                        then
                                if [[ "${timeResult[$midMon]}" == "0.0" ]]
                                then
                                        if [[ "${timeResult[$middleMon]}" == "0.0" ]]
                                        then
                                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                                        else
                                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                                ((countMon++))
                                                if (( $countMon == $countMax ))
                                                then
                                                        jmpaddrMon=${mon_ip[$middleMon]}
                                                        jmpportMon=${mon_port[$middleMon]}
                                                fi
                                        fi
                                else
                                        echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                        echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                        ((countMon++))
                                        if (( $countMon == $countMax ))
                                        then
                                                jmpaddrMon=${mon_ip[$midMon]}
                                                jmpportMon=${mon_port[$midMon]}
                                        fi
                                fi
                        else
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
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

#处理特殊情况
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
                        echo "${lostPackage[$minMon]} ${mon_ip_v[$minMon]} 直连" >> /tmp/b.txt
                        echo "${lostPackage[$middleMon]} ${mon_ip_v[$middleMon]} 维用" >> /tmp/b.txt
                        echo "${lostPackage[$maxMon]} ${mon_ip_v[$maxMon]} 深信服" >> /tmp/b.txt
                else
                        echo "${lostPackage[$minMon]} ${mon_ip_v[$minMon]} 直连" >> /tmp/b.txt
                        echo "${lostPackage[$middleMon]} ${mon_ip_v[$middleMon]} 深信服" >> /tmp/b.txt
                        echo "${lostPackage[$maxMon]} ${mon_ip_v[$maxMon]} 维用" >> /tmp/b.txt
                fi
        elif (( $middleMon == 0 ))
        then
                if (( $minMon == 1 ))
                then
                        echo "${lostPackage[$minMon]} ${mon_ip_v[$minMon]} 维用" >> /tmp/b.txt
                        echo "${lostPackage[$middleMon]} ${mon_ip_v[$middleMon]} 直连" >> /tmp/b.txt
                        echo "${lostPackage[$maxMon]} ${mon_ip_v[$maxMon]} 深信服" >> /tmp/b.txt
                else
                        echo "${lostPackage[$minMon]} ${mon_ip_v[$minMon]} 深信服" >> /tmp/b.txt
                        echo "${lostPackage[$middleMon]} ${mon_ip_v[$middleMon]} 直连" >> /tmp/b.txt
                        echo "${lostPackage[$maxMon]} ${mon_ip_v[$maxMon]} 维用" >> /tmp/b.txt
                fi
        else
                if (( $minMon == 1 ))
                then
                        echo "${lostPackage[$minMon]} ${mon_ip_v[$minMon]} 维用" >> /tmp/b.txt
                        echo "${lostPackage[$middleMon]} ${mon_ip_v[$middleMon]} 深信服" >> /tmp/b.txt
                        echo "${lostPackage[$maxMon]} ${mon_ip_v[$maxMon]} 直连" >> /tmp/b.txt
                else
                        echo "${lostPackage[$minMon]} ${mon_ip_v[$minMon]} 深信服" >> /tmp/b.txt
                        echo "${lostPackage[$middleMon]} ${mon_ip_v[$middleMon]} 维用" >> /tmp/b.txt
                        echo "${lostPackage[$maxMon]} ${mon_ip_v[$maxMon]} 直连" >> /tmp/b.txt
                fi
        fi
        /usr/bin/paste /tmp/a.txt /tmp/b.txt | awk 'BEGIN{printf "%-15s%-10s%-20s%-10s\n","返回时间","丢包率","IP地址","机房"}{b[y++]=$2;c[z++]=$3;d[t++]=$4;e[k++]=$5}END{for(i in b)printf "%-15s%-10s%-20s%-10s\n",b[i]"ms",c[i]"%",d[i],e[i]}' > /tmp/c.txt
        rm -f /tmp/b.txt &> /dev/null
        if (( $minMon == $current_t ))
        then
                if [[ "${timeResult[$minMon]}" != "0.0" ]]
                then
                        echo "$NowTime SCH_MON 当前 $current_mon is the best" >> log/CheckNet.$(date +%Y%m%d).log
                else
                        if [[ "${timeResult[$middleMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip_v[$middleMon]}
                                jmpportMon=${mon_port_v[$middleMon]}
                        elif [[ "${timeResult[$maxMon]}" != "0.0" ]]
                        then
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip_v[$maxMon]}
                                jmpportMon=${mon_port_v[$maxMon]}
                        else
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
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
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
                                ((countMon++))
                                if (( $countMon == $countMax ))
                                then
                                        jmpaddrMon=${mon_ip_v[$minMon]}
                                        jmpportMon=${mon_port_v[$minMon]}
                                fi
                        else
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                        fi
                else
                        if [[ "${timeResult[$maxMon]}" == "0.0" ]]
                        then
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON all is down" >> log/CheckNet.$(date +%Y%m%d).log
                        else
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is down" >> log/CheckNet.$(date +%Y%m%d).log
                                nowjmpMon=1
                                jmpaddrMon=${mon_ip_v[$maxMon]}
                                jmpportMon=${mon_port_v[$maxMon]}
                        fi
                fi
        else
                if [[ "${timeResult[$middleMon]}" != "0.0" ]]
                then
                        echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                        cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                        echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is not the best" >> log/CheckNet.$(date +%Y%m%d).log
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
                                echo "$NowTime SCH_MON 所有线路状态如下：" >> log/CheckNet.$(date +%Y%m%d).log
                                cat /tmp/c.txt >> log/CheckNet.$(date +%Y%m%d).log
                                echo "$NowTime SCH_MON all is down" >> log/CheckNet.$(date +%Y%m%d).log
                        else
                                echo "$NowTime SCH_MON 当前 $current_mon:$current_mon_port is the best" >> log/CheckNet.$(date +%Y%m%d).log
                        fi
                fi
        fi
}

#修改iptables实现智能切换
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

#处理特殊情况
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

#主函数
main(){
        while true
        do
                NowTime=$(date  +"%Y-%m-%d %T")
		CheckTime=$(date +%H)
		#每天晚上22点调用一次remove_logfile函数，检测当天是不是每月的27号，若是则清理前一个月的日志文件
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

