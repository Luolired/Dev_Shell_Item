#!/usr/bin/env python
# -*- coding: gbk -*-
# ************************************************************************ 
# * 
# * @file:Agent_007ka.py 
# * @author:Luolired@163.com 
# * @date:2016-08-24 14:17 
# * @version 1.0  
# * @description: Ansible Dev Agent Module Python Script 采集模块
# * @Copyright (c) 007ka all right reserved 
# * @UpdateLog:
# *         1.JSON在线编辑器,校验json结果关系:http://www.json.org.cn/tools/JSONEditorOnline/index.htm
# *         2.解决循环只执行第一个(subprocess.PIPE)
# *         3.解决循环查询时查询结果均为空(没有去除\n,导致查询条件默认都带\n)
# *         4.增加判断查询行结果判断是否为空if strip()
#************************************************************************* 

import os,sys,re,copy
import datetime,commands
import json,socket,subprocess

date=str(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
localIP=socket.gethostbyname(socket.gethostname())
sys_id=localIP.split('.')[1]
outIp="163.177.76.147"
vip=commands.getoutput('ip addr | grep "bond0:vip" | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"')
sla_leave=1
route=commands.getoutput("ip route |grep 'default' |head -n 1 |awk '{print $3}'")
hostname=commands.getoutput('hostname')
hostclass=commands.getoutput('hostname|egrep -o "app|web"')
keepalived_state=commands.getoutput("tail -n 1 /etc/keepalived/state.txt | awk '{print $NF}'")
backupip=commands.getoutput("grep -r 'G_MOVE_IP=10.' /etc/keepalived/* | head -n 1 |awk -F '=' '{print $NF}'")
rsync_state=commands.getoutput('if ps -ef |grep "rsync_007ka"|grep -q "inotifywait";then echo "Source";else echo "Backce";fi')
inode_usage=commands.getoutput('df -i | grep "/$" | grep -oE "[0-9]{1,3}%"')
disk_usage=commands.getoutput('df -h | grep "/$" | grep -oE "[0-9]{1,3}%"')
swap_free=commands.getoutput("free -m | grep Swap |awk '{print int($4/$2*100)\"%\"}'")

#正在运行apps用户进程总数
runing_online_num=commands.getoutput('ps aux|grep ^apps|grep -vw "grep\|vim\|vi\|mv\|cp\|scp\|cat\|dd\|tail\|head\|script\|ls\|echo\|sys_log\|logger\|tar\|rsync\|ssh\|new_sysmon\|inotifywait"|grep "/usr/local/007ka/"|wc -l')
#ps得到运行进程详情
psaux_data=subprocess.Popen("ps aux |grep ^apps",shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
#所有应用程序目录名称
all_program=subprocess.Popen('find /usr/local/007ka/ -type f -name "run.sh" -o -name "run_*.sh" | grep -v "/usr/local/007ka/bin"|grep -v "new_sysmon" | sed -e "s/\/run.*.sh//"| uniq', shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
global g_list_psaux_data,g_list_all_program
prgram_data_all=[]
#【注意】因为subprocess.PIPE为缓存，读取一次变释放，为了能for循环读取，需要存入变量中
g_list_psaux_data=copy.deepcopy(psaux_data.stdout.readlines())
g_list_all_program=copy.deepcopy(all_program.stdout.readlines())

for line in g_list_all_program:
    #【注意】:只要是调用shell命令,请务必删除默认自带回车.line.strip('\n')
    tmp_proname=str(line.strip('\n').split('/')[-1])
    #在ps中查处包含程序关键字的行,相当于:ps aux |grep tmp_proname |awk '{print $2}'
    program_line= ''.join([x for x in g_list_psaux_data if x.find(tmp_proname,re.M)!=-1])
    if program_line.strip():
        tmp_pid=program_line.split()[1]
        dict_program={
            "Name": tmp_proname,
            "pid": tmp_pid,
            "SysId": sys_id
        }
        #列表里是字典
        prgram_data_all.append(dict_program)
        #print dict_program
        #print prgram_data_all

#retval = psaux_data.wait()
#retval = all_program.wait()

#输出json结果
print json.dumps({
    "Name": date,
    "Sys_Id": sys_id,
    "In_Ipaddress": localIP,
    "Out_Ipaddress": outIp,
    "Vip": vip,
    "Route": route,
    "HostName": hostname,
    "HostClass": hostclass,
    "Keepalived_State": keepalived_state,
    "BackupIp": backupip,
    "Rsync_State": rsync_state,
    "SLA_Leave": sla_leave,
    "Disk_Total": {
        "Inode_Usage": inode_usage,
        "Disk_Usage": disk_usage,
        "Swap_Free": swap_free
    },
    "Runing_Online_Num": runing_online_num,
    "Program_Data": prgram_data_all
})
