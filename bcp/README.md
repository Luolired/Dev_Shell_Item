# bcp 带回滚的复制
    bcp复制文件到新目录，新目录若存在同名文件则备份并输出一个回滚脚本;若不存在直接复制。
    【需求】：应用程序部署环节    
            旧的进行备份（cp重命名），新版本进行软链接，同时自动产生版本号&回退脚本
    【复杂度】：三星
    【扩展】：为什么不用cp？ 
            因为cp命令询问是否覆盖有询问，而且旧复制出来的文件格式并非是我们需要的日期+版本号在中间（SmsCenter.20160606.jar）。
            cp -i, –interactive
            覆盖目标文件时给与提醒.默认cp命令覆盖目标文件时是不会提示的，很多Linux发行版里的cp都被设置别名`cp -i`,其实作用就是给用户一个提醒。如果你不想被提示，那么请这样输入：\cp source target，或者使用cp命令的绝对路径/bin/cp
    【用法】：
    ```
        ./bcp_app.sh --help
            [Info] 用途：cp复制源文件或源目录,到新目录。若存在同名文件则备份并输出一个回滚脚本;若不存在直接复制
            用法：./bcp_app_new.sh 源文件路径目录或源文件路径 目标路径目录 OA编号
            [Info] Usage: ./bcp_app_new.sh /home/lizx01/program_path /usr/local/007ka OANum
            Create Time:2016-05-04,Author:lizx 007ka-soc,V1.0
            Modified Time:2016-05-04,V2.0,Add Cp Only File
    ```
    【功能解读】：
    
 ![image](https://github.com/Luolired/Dev_Shell_Item/blob/master/bcp/img/QQ截图20160608091942.jpg)
 
        [Info] 目标路径===存在同名文件:SmsCenter.jar 且已有软链接===整理完毕,旧版本: SmsCenter.20160606.jar;当前版本:SmsCenter.14107120160608.jar
        [Info] 回滚脚本准备完毕:/home/lizx01/RollBack/SmsCenter.jar_14107120160608.sh

 ![image](https://github.com/Luolired/Dev_Shell_Item/blob/master/bcp/img/111.jpg)    
 ![image](https://github.com/Luolired/Dev_Shell_Item/blob/master/bcp/img/2222.jpg)
  

