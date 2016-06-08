# bcp 
    bcp复制文件到新目录，新目录若存在同名文件则备份并输出一个回滚脚本;若不存在直接复制。
    【需求】：应用程序部署环节    旧的进行备份（cp重命名），新版本进行软链接，同时自动产生版本号&回退脚本
    【复杂度】：三星
    【用法】：
    ```
    ./bcp_app_new.sh --help
        [Info] 用途：cp复制源文件或源目录,到新目录。若存在同名文件则备份并输出一个回滚脚本;若不存在直接复制
        用法：./bcp_app_new.sh 源文件路径目录或源文件路径 目标路径目录 OA编号
        [Info] Usage: ./bcp_app_new.sh /home/lizx01/program_path /usr/local/007ka OANum
        Create Time:2016-05-04,Author:lizx 007ka-soc,V1.0
        Modified Time:2016-05-04,V2.0,Add Cp Only File
    ```
