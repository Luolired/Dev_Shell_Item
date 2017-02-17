### 一、[重定义linux rm指令] rm解读 rm -rf ~
> rm_backup.txt是重定义的mv与rm指令，主要改动rm指令。
本上是偷换了概念，把rm命令转换成了mv命令，但是能够达到我想要的效果，只不过在习惯性的敲入－r 参数时会报出一个错误，因为mv命令没有－r参数嘛

> 呵呵,如此操作则不报错了，强烈推荐

![image](https://github.com/Luolired/Dev_Shell_Item/blob/master/rm/clipboard.png) 

  自我创新实现的，复制如下代码加入到.bashrc：

    #------------------------------------rm修改重新定义mv模块------------------------------
    mkdir -p  ~/.trash
    alias rm='trash'
    #rl 命令是列出回收站
    alias rl='trashlist'
    alias ur='undelfile'
    #替换rm指令移动文件到~/.trash/中   
    trash()  
    {
       #mv $@  ~/.trash/
       #mv命令没有－r参数
       #mv_tmp_all=$@
       #mv_tmp_first=$(echo $mv_tmp_all|awk '{print $1}')
       #if [ $mv_tmp_first == '-rf' -o $mv_tmp_first == '-r' ] ;then
       #   mv_tmp_other=$(echo "${mv_tmp_all}" | awk 'gsub(/r/,"",$1) {print $0}')
       #   mv $mv_tmp_other  ~/.trash/  
       #else
       #   mv $mv_tmp_all  ~/.trash/  
       #fi
       mv $(echo "$@" | awk '{sub(/^-r/,"-",$1);print $0}') ~/.trash/
    }
    #显示回收站中垃圾清单  
    trashlist()  
    {
        echo -e "\033[32m==== Welcome rm New Changed mv Action ====\033[0m" 
        echo -e "\033[32m==== Recycle Lists in ~/.trash/ Usage: ==== \033[0m" 
        echo -e "\033[33m-1- Use '#Cleartrash ' to clear all garbages in ~/.trash ===> rm -rf ~/.trash/* !!!\033[0m"  
        echo -e "\033[33m-2- Use '#ur filename ' to mv the file in garbages to current dir!!!\033[0m"
        ls -lhtr --time-style=long-iso ~/.trash
        echo -e "\033[32m======================= Lists End  ======================== \033[0m" 
    }
    #找回回收站相应文件   
    undelfile()  
    {
       mv -i ~/.trash/$@ ./
    }
    #清空回收站   
    Cleartrash()  
    {
       echo -e "\033[31m ==== [ WANNING ] ====\033[0m"  
       echo -ne "\033[31m !!! #rm -rf Clear all garbages in ~/.trash, Are you Sure?[y/n] \033[0m"  
       read confirm
       if [ $confirm == 'y' -o $confirm == 'Y' -o $confirm == 'Yes' ] ;then
          /bin/rm -rf ~/.trash/*
          /bin/rm -rf ~/.trash/.* 2>/dev/null
          ls -lhtr --time-style=long-iso ~/.trash
          echo -e "\033[32m=================== rm -rf ~/.trash/* over GoodBye =================== \033[0m" 
       fi
    }
    #------------------------------------rm修改重新定义mv模块------------------------------
    

		这段代码定义了三个函数trash、undelfile和cleartrash。trash的作用是移动文件到指定的回收站目录；undelfile的作用是找回回收站目录中的指定文件；cleartrash的作用是清空回收站目录。经rm命令别名为trash来实现rm命令的改造！
