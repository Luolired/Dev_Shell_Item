# check_web_netstat 
## Nagios插件检测端口被攻击扫描，发现攻击ip
    【需求】：Nagios插件 端口连入数超过区间阀值报警，并提供攻击源Ip
    【复杂度】：一星
    【技巧】：在正则表达式awk匹配区间里使用端口变量
    【关键语句】
        Access_Max_Ip=$(netstat -nat |awk -F '[ :]+' '$5~/^'$G_Check_Port'$/{++array[$6]};END{for(key in array){print key,array[key] |"sort -nr -k2 | head -n 1"}}')

    
        $ /etc/nagios/nrpe.d/check_web_netstat.sh 80 500 800
        PROCS OK:80 Port Cureent_Netstat_Num:261 less than that:500
        $ /etc/nagios/nrpe.d/check_web_netstat.sh 80 200 800
        PROCS WARGING:80 Port Cureent_Netstat_Num:271 larger than that:200,124.127.181.102 34 maybed attacked our web!!!
        $ /etc/nagios/nrpe.d/check_web_netstat.sh 80 100 150
        PROCS CRITICAL:80 Port Cureent_Netstat_Num:248 larger than that:150,124.127.181.102 32 maybed attacked our web!!!
    
![image](https://github.com/Luolired/Dev_Shell_Item/blob/master/Check_web_netstat/888.jpg）
