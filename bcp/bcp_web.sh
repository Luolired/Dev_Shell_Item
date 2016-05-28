#!/bin/bash

# ***************************************************************************
# * 
# * @file:bcp.sh 
# * @author:Luolired@163.com 
# * @date:2015-07-27 20:53 
# * @version 7.1
# * @description:复制web文件到新目录，新目录若存在同名文件则备份并输出一个回滚脚本;若不存在直接复制
# * @Copyright (c) 007ka all right reserved 
#* 
#**************************************************************************/ 
export LANG=zh_CN.GBK
sudo_user=www-data
datetime=`date +%Y%m%d`
propath=$1
despath=$2
#回滚脚本路径
rollback=~/rollback
if [ ! -d $rollback ]
then
	mkdir -p $rollback
fi

# Print error messges eg:  _err "This is error"
function _err()
{
    echo -e "\033[1;31m[ERROR] $@\033[0m" >&2
}

# Print notice messages eg: _info "This is Info"
function _info()
{
    echo -e "\033[1;32m[Info] $@\033[0m" >&2
}

if [ $# -lt 2 ]
then 
    _info "用途：复制文件到新目录，新目录若存在同名文件则备份并输出一个回滚脚本;若不存在直接复制"
    _err "用法：`basename $0` 源文件路径目录 目标路径目录"
    _err "例如：#`basename $0` /home/lizx01/tmp /var/www/html/test"
   exit 1
fi

if [ -d $propath ] 
then
    #若非绝对路径(^/)则进行转换，是/$则进行剔除最后/字符,保证路径正确性
    echo $propath | grep -q '^/' || propath=$PWD/$propath
    echo $propath | grep -q '/$' && propath=$(echo $propath|sed 's/\/$//')
    proname=$(echo $propath |awk -F'/' '{print $NF}')
else
    _err "$propath directory does not exist." 
    exit 1
fi

if [ -d $despath ] 
then
    #若非绝对路径(^/)则进行转换，是/$则进行剔除最后/字符,保证路径正确性
    echo $despath | grep -q '^/' || despath=$PWD/$despath
    echo $despath | grep -q '/$' && despath=$(echo $despath|sed 's/\/$//')
    #echo $despath
else
    _err "$despath directory does not exist." 
    exit 1
fi

if [ -f ${rollback}/${proname}_${datetime}.sh ]
then
    cat /dev/null > ${rollback}/${proname}_${datetime}.sh
fi

function rename()
{   
    source_file_name=$1
    datetime=$2
    dest_file_name=`echo ${source_file_name}.old.${datetime}`
    echo $dest_file_name
}

#:<<mark
#注意文件路径已经切换到了$propath下
cd $propath && find ./ -type f |sed 's/\.\///g'|sort | while read file_line
do
    #$ cd /home/lizx/test01/ && find ./ -type f |sed 's/\.\///g'
    #ini/msgsrv.xml
    #time
    if [ -f $despath/$file_line ]
    then
        #新目录若存在同名文件则备份并输出一个回滚脚本,备份格式为：cp $despath/$file_line ${despath}/${file_line}.old.${last_mtime}
        #开始进行备份，然后覆盖重名文件
        last_mtime=$(ls -l --time-style="+%Y%m%d" $despath/$file_line |awk '{print $(NF-1)}')
	dest_old_line=$(rename $file_line $last_mtime)
        sudo -u $sudo_user cp ${despath}/${file_line} ${despath}/${dest_old_line}
        cd $propath && sudo -u $sudo_user cp -rf $file_line ${despath}/${file_line}
        [ $? -eq 0 ] && echo "cd $despath && sudo -u $sudo_user cp ${despath}/${file_line} ${despath}/${file_line}.old.${datetime}" >>${rollback}/${proname}_${datetime}.sh
	[ $? -eq 0 ] && echo "sudo -u $sudo_user cp ${despath}/${dest_old_line} ${despath}/${file_line}" >>${rollback}/${proname}_${datetime}.sh
        _info "目标路径===存在同名文件:$file_line ===整理完毕,旧版本重命名为:$dest_old_line;当前版本:$file_line"
    fi
    if echo $file_line| grep -q '/'       #不存在时，判断是否存在新目录的复制
    then 
        #eg:/home/lizx/guom01/proget02/two
        #cp: 无法创建普通文件"/home/lizx/guom01/proget/ini/msgsrv.xml": 没有ini文件或目录
        #新目录不存在同名文件，则进行复制，复制时进行区分是，复制的是文件还是目录，分别处理
        #存在目录的复制，获取目录路径,创建目录路径
        directories=$(dirname "$despath/$file_line")
        sudo -u $sudo_user mkdir -p $directories && cd $propath && sudo -u $sudo_user cp -rf $file_line $directories && _info "目标路径===无同名文件:$file_line 目录===首次创建&复制完毕"
    else
     	cd $propath && sudo -u $sudo_user cp -rf $file_line $despath && _info "目标路径===无同名文件:$file_line 文件===首次复制完毕"
    fi
done

if [ -f ${rollback}/${proname}_${datetime}.sh ]
then
    chmod +x ${rollback}/${proname}_${datetime}.sh
    _info "回滚脚本准备完毕:${rollback}/${proname}_${datetime}.sh"
    exit 0
fi
#mark

