#ping_sec
ping_sec 每秒ping不同地址，而且每天生成一份日志文件

  【需求】：检测合作伙伴到我司服务器网络通信质量情况的检测
  
  【复杂度】：一星
  
  【关键节点】：定时任务切割天日志 0 0 * * * /usr/local/007ka/new_sysmon/pinglog.sh &>/dev/null
  ```
    LOG_FILE="${LOG_PATH}/ping-call.${g_s_LOGDATE}.log"
          PARTNER_IP=$( cat $g_s_Work_Inc|grep -v "^#"|awk -F "[=== ]+" '{print $2}'|sed -n "$i"p)
          pkill -f "/bin/ping -i 1 $PARTNER_IP" || sleep 1
          /bin/ping -i 1 $PARTNER_IP | awk '{print strftime("%Y%m%d %T",systime()),"src '$g_s_SRC_IP'" , "dst '$PARTNER_IP'"  "\t" $0}' >> $LOG_FILE &
  ```
  lizx01@20app125p:/usr/local/007ka/new_sysmon/inc$ vi DevOps_pinglog.ini 
  
    ##代理商信息表
    
    #格式eg:partner_id===partner_ip
    
    2000000057===218.17.225.81
    
    2000000091===inteface.sdlhkj.cn
    
    2000000228===211.139.145.140
    
    2000000046===119.90.40.54

  
  ![image](https://github.com/Luolired/Dev_Shell_Item/blob/master/ping_sec/pinglog.jpg)
