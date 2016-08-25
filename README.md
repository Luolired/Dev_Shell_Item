# Dev_Shell_Item
自己开发用于生产环境中开发的shell脚本项目

## 运维鹰眼 Soc 【便捷搜索】
    生产服务器跑了4、5千应用程序，运维工作中如何从海量应用中定位到你要应用程序：地址、路径、运行pid、以及程序CMDB
    有了鹰眼一键帮你查询你需要的！
   ![image](https://github.com/Luolired/Dev_Shell_Item/blob/master/bcp/img/aaa.png)  

## bcp 带回滚的应用部署cp 【提高效率自动化部署】
    bcp复制文件到新目录，新目录若存在同名文件则备份并输出一个回滚脚本;若不存在直接复制。
    【需求】：应用程序部署环节    旧的进行备份（cp重命名），新版本进行软链接，同时自动产生版本号&回退脚本
    【复杂度】：三星

## keepalived_env_install 标准化安装keepalived环境主备配置 【一键高可用部署】
    1.交互式安装keepalived主备配置环境参数
    2.标准化开启启动规范
    3.最大的特点：具备锁机制，能无缝影响线上生产业务，运行keepalived。
    【需求】：生产服务器众多，不仅需要在每台标准化安装主备配置，而且还需要不能影响在运行生产服务（启动过程中不能notify_事件触发现有业务）
    【复杂度】：三星
    
## ping_sec 检测网络 【网络健康质量监测】
    ping_sec 每秒ping不同地址，而且每天生成一份日志文件
    【需求】：检测合作伙伴到我司服务器网络通信质量情况的检测
    【复杂度】：一星

## check_web_netstat Nagios插件检测端口被攻击扫描，发现攻击ip 【安全加固发现攻击源】
    【需求】：Nagios插件 端口连入数超过区间阀值报警，并提供攻击源Ip
    【复杂度】：一星
    【技巧】：在正则表达式awk匹配区间里使用端口变量

## SchLineManage 切换线路 【智能选择线路】
    SchLineManage 检测网络质量情况比较丢包率（通与不通）和返回时间（选出最优）线路，切换iptables映射
    【需求】：检测线路网络情况，及时切换线路iptables
    【复杂度】：三星
    【提升】：Nginx反向代理
    
## check_procs_uptime  Nagios插件检测程序或服务是否重启restart插件 【改善监控盲点】
    【需求】：Nagios插件 本脚本用于检测应用程序或服务运行时间,从侧面来推断程序是否频繁重启或首次启动
    【复杂度】：两星
    【技巧】：ps数据结果数据存入缓存+ps时间etime min 计算转换 
     1.遍历整个ps结果,无须挨个添加注册,检查程序的启动时间,判断为是否是首次启动或者频繁重启
     【升级】check_sup_proc_uptime.sh 针对supervisor 检测是否重启的插件脚本

## rsync_007ka_install  自动化安装同步007ka应用  【一键安装、自动建立实时同步关系】
    【需求】：将rsync与inotify 实时同步一键安装封装包
    【复杂度】：两星
    【技巧】：
        1.自动安装而且帮你配置好配置，你只需要告诉他从哪里同步到哪里
        2.带同步实时记录日志
        3.自动交互安装，即使你是小白不懂rsync与inotify
        4.不仅带过滤监控的文件，而且还有不同步文件的白名单如*.log\*.log.tar.gz
        

## rsync_tar_log  自动化将日志打包压缩且移动到日志服务器 【磁盘清理自动化】
    【需求】：将应用程序日志5天前日志压缩打包切移动rsync mv 到日志服务器。
    【复杂度】：两星
    【技巧】：
        1.带指定自定义时间段执行要缩打包（eg:夜间凌晨段，服务器负载小时开始，到早上上班结束，压缩）
        2.带同步压缩实时记录日志
        3.配置文件方式，定义开关压缩

## add_msgsrv  将同组内的Ip进行遍历注册到消息中间件   【提高效率、数组遍历执行】
    【需求】：多台主机同时注册开通消息中间件
    【复杂度】：三星
    【技巧】：
        1.一个脚本就可以注册多个ip在消息中间件的注册放行
        2.严格的安全参数检查如：ip检查
        3.支持数组定义 相同ip同时注册，避免遗漏单个ip

## Cut_orderid_time 跨服务器查询日志功能 【跨服务器跨目录检索日志】
    【需求】：根据订单号查询该订单号在不同程序且不同不服务器的日志？
    【复杂度】：三星
    【技巧】：
        1.根据订单号检索多台服务器的日志信息 
        2.数组定义支持多个服务器地址与日志目录

## crawl_zucpInfo.py 爬虫短信数量监控 【爬取短信接口短信数量的监控】
    【需求】：每天都需要登录短信接口，进行短信接口数量趋势分析？
    【复杂度】：二星
    【技巧】：
        1.Python crawl
        2.highchart
        3.Datables
        4.php 下载execl
