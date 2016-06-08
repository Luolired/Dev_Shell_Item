#ping_sec
ping_sec 每秒ping不同地址，而且每天生成一份日志文件
  【需求】：检测合作伙伴到我司服务器网络通信质量情况的检测
  
  【复杂度】：一星
  
  【关键节点】：
  ```
    LOG_FILE="${LOG_PATH}/ping-call.${g_s_LOGDATE}.log"
          PARTNER_IP=$( cat $g_s_Work_Inc|grep -v "^#"|awk -F "[=== ]+" '{print $2}'|sed -n "$i"p)
          pkill -f "/bin/ping -i 1 $PARTNER_IP" || sleep 1
          /bin/ping -i 1 $PARTNER_IP | awk '{print strftime("%Y%m%d %T",systime()),"src '$g_s_SRC_IP'" , "dst '$PARTNER_IP'"  "\t" $0}' >> $LOG_FILE &
  ```
  
  ![image](https://github.com/Luolired/Dev_Shell_Item/blob/master/ping_sec/pinglog.jpg)
