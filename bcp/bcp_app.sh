#!/bin/bash

# ***************************************************************************
# * 
# * @file:bcp.sh 
# * @author:Luolired@163.com 
# * @date:2015-07-27 20:53 
# * @version 7.3
# * @description:复制文件到新目录，新目录若存在同名文件则备份并输出一个回滚脚本;若不存在直接复制
# * @Copyright (c) 007ka all right reserved 
# * @UpdateLog: 1.增加OA流水号标识版本
# *             2.首次复制也增加OA流水号版本进行软链接
# *             3.增加支持针对一个文件的复制
# *             4.主体函数g_fn_Director 分解
# *             5.首次新复制文件不产生回滚脚本
#**************************************************************************/ 
export LANG=zh_CN.GBK

sudo_user=apps
#sudo_user=lizx01
g_s_DataTime=`date +%Y%m%d`

g_p_ProGram_Path=$1       #将要上线的程序包目录路径/文件
g_p_Dest_Path=$2          #生产目标路径
g_i_OANUM=$3              #本次上线OA流水号


### Print error messges eg:  _err "This is error"
function _err()
{
    echo -e "\033[1;31m[ERROR] $@\033[0m" >&2
}

### Print notice messages eg: _info "This is Info"
function _info()
{
    echo -e "\033[1;32m[Info] $@\033[0m" >&2
}

### Print notice messages eg: _content "This is Info"
function _content() {
    echo -e "\033[1;30m$@\033[0m"
}

### 使用引导help
if [ "$#" -lt 3 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	_content "=========================== Welcome ===================================="
	_info "用途：cp复制源文件或源目录,到新目录。若存在同名文件则备份并输出一个回滚脚本;若不存在直接复制"
	echo 
	_content "用法：$0 源文件路径目录或源文件路径 目标路径目录 OA编号"
	_info "Usage: $0 /home/lizx01/program_path /usr/local/007ka OANum" >&2
	echo 
	_content "Create Time:2016-05-04,Author:lizx 007ka-soc,V1.0"
	_content "Modified Time:2016-05-04,V2.0,Add Cp Only File"
	_content "=========================== Welcome ===================================="
	exit 1
fi

### g_p_Dest_Path 若非绝对路径(^/)则进行转换，是/$则进行剔除最后/字符,保证路径正确性,最终得出绝对路径！
if [ -d $g_p_Dest_Path ] 
then
    echo $g_p_Dest_Path | grep -q '^/' || g_p_Dest_Path=$PWD/$g_p_Dest_Path
    echo $g_p_Dest_Path | grep -q '/$' && g_p_Dest_Path=$(echo $g_p_Dest_Path|sed 's/\/$//')
    #echo $g_p_Dest_Path
else
    _err "$g_p_Dest_Path directory does not exist." 
    exit 1
fi

### 创建具体的OANum+g_s_DataTime编号回滚脚本,重复则清空
function g_fn_Create_RollBack()
{
	proname=$1
	### 回滚目录创建
	t_p_RollBack_Path=~/RollBack
	if [ ! -d $t_p_RollBack_Path ]
	then
		mkdir -p $t_p_RollBack_Path
	fi
	RollBack_PathFile="${t_p_RollBack_Path}/${proname}_${g_i_OANUM}${g_s_DataTime}.sh"
	if [ -f "${RollBack_PathFile}" ]
	then
   		 cat /dev/null > "${RollBack_PathFile}"
	fi
	echo "${RollBack_PathFile}"
}

### 回调信息记录指令函数 
function g_fn_RollBack()
{
	echo "$*" >> $g_p_RollBack_PathFile
}

### g_fn_Rename 函数,重命名后的规范定义
function g_fn_Rename()
{   
    source_file_name=$1
    tmp_datetime=$2
    tmp_oanum=$3
    dest_file_name=`echo $source_file_name |awk -F. 'BEGIN{OFS="."};{if(NF>1)NF=NF-1;print $0}'`.${tmp_oanum}${tmp_datetime}`echo $source_file_name|awk -F '.' '{if(NF>1)print "."$NF}'`
    echo $dest_file_name
}

function g_fn_Director()
{
    file_line=$1
    source_path=$2
    if [ -f ${g_p_Dest_Path}/${file_line} ]
    then
        #$file_line ini/msgsrv.xml 可能存在子目录subdirectory(ini),回滚脚本就必须切到ini目录下
        subdirectory=$(echo ${g_p_Dest_Path}/${file_line} |awk -F '/' 'BEGIN{OFS="/"};{if(NF>1)NF=NF-1;print $0}')
        
        #新目录若存在同名文件则备份并输出一个回滚脚本 readlink
        if [ -L ${g_p_Dest_Path}/${file_line} ]
        then
            oldlink_file=$(ls -lh ${g_p_Dest_Path}/${file_line} |awk -F'->' '{print $NF}')
            #最终带本次上线编号的文件名格式
 	    dest_line=$(g_fn_Rename ${file_line} ${g_s_DataTime} ${g_i_OANUM})
            #复制文件到生产路径命名为最终带版本编号文件
            cd ${source_path} && sudo -u $sudo_user cp ${file_line} ${g_p_Dest_Path}/${dest_line}
	    #开始软链接到新版本
	    [ $? -eq 0 ] && cd ${g_p_Dest_Path} && sudo -u $sudo_user ln -sf $(echo $dest_line|awk -F '/' '{print $NF}') $file_line
            
	    #回退脚本，这里要找到之前软链接的源文件
            #[ $? -eq 0 ] && echo "cd $subdirectory && sudo -u $sudo_user ln -sf $(echo $oldlink_file|awk -F '/' '{print $NF}') $(echo $file_line | awk -F '/' '{print $NF}')" >> ${g_p_RollBack_PathFile}
            [ $? -eq 0 ] && g_fn_RollBack "cd $subdirectory && sudo -u $sudo_user ln -sf $(echo $oldlink_file|awk -F '/' '{print $NF}') $(echo $file_line | awk -F '/' '{print $NF}')"
            _info "目标路径===存在同名文件:$file_line 且已有软链接===整理完毕,旧版本:${oldlink_file};当前版本:${dest_line}"

        else
            #目标路径未创建软链接,先创建软链接,后替换为新软链接格式规范
            last_mtime=$(ls -l --time-style="+%Y%m%d" $g_p_Dest_Path/$file_line |awk '{print $(NF-1)}')
            #最后一次编辑时间带编号的文件名格式
	    #因为以前可能没有版本号追溯记录,所以OANum 特定000000标识
            source_line=$(g_fn_Rename ${file_line} ${last_mtime} 000000 )
	    #回退脚本回退0000000版本,最初版本
            #[ $? -eq 0 ] && echo "cd $subdirectory && sudo -u $sudo_user ln -sf $(echo $source_line|awk -F '/' '{print $NF}') $(echo $file_line | awk -F '/' '{print $NF}')" >> ${g_p_RollBack_PathFile}
            [ $? -eq 0 ] && g_fn_RollBack "cd $subdirectory && sudo -u $sudo_user ln -sf $(echo $source_line|awk -F '/' '{print $NF}') $(echo $file_line | awk -F '/' '{print $NF}')"
            #因为未创建软链接,先将当期在用版本进行复制成它最后一次编辑时间当做版本号
            sudo -u $sudo_user cp ${g_p_Dest_Path}/${file_line} ${g_p_Dest_Path}/${source_line}
            
            #最终带本次上线编号的文件名格式
            dest_line=$(g_fn_Rename ${file_line} ${g_s_DataTime} ${g_i_OANUM})
            #复制文件到生产路径命名为最终带版本编号文件
            cd $source_path && sudo -u $sudo_user cp $file_line ${g_p_Dest_Path}/${dest_line} 
	    #开始软链接到新版本
	    [ $? -eq 0 ] && cd $g_p_Dest_Path && sudo -u $sudo_user ln -sf $(echo $dest_line|awk -F '/' '{print $NF}') $file_line
            _info "目标路径===存在同名文件:$file_line 无软链接规范===整理完毕,旧版本重命名为:${source_line};当前版本:${dest_line}"
        fi
    ### 生产目标路径没有重名文件哦,意味着是首次复制
    else
	if echo ${file_line}| grep -q '/'       
    	then 
    	    #注意:先要进行子目录的创建,否则:
            #cp: 无法创建普通文件"/home/lizx/guom01/proget/ini/msgsrv.xml": 没有ini文件或目录,所以先需要创建ini目录
            #新目录不存在同名文件，则进行复制，复制时进行区分是，复制的是文件还是目录，分别处理
            #先获得$file_line的目录路径
            directories=$(dirname "$g_p_Dest_Path/$file_line")
            sudo -u $sudo_user mkdir -p $directories && _info "=== 目标路径无同名目录:$directories目录首次创建完毕==="
	fi
	#开始对文件进行处理,文件首次复制,需要建立软连接
        #最终带本次上线编号的文件名格式
	dest_line=$(g_fn_Rename ${file_line} ${g_s_DataTime} ${g_i_OANUM})
	#复制文件到生产路径命名为最终带版本编号文件
	cd $source_path && sudo -u $sudo_user cp $file_line ${g_p_Dest_Path}/${dest_line}
        #开始软链接到新版本
        [ $? -eq 0 ] && cd $g_p_Dest_Path && sudo -u $sudo_user ln -sf $(echo $dest_line|awk -F '/' '{print $NF}') $file_line
        _info "=== 目标路径无同名文件:$file_line文件首次复制&软链接完毕===当前版本:${dest_line}"
	_info "=== 首次复制不产生回滚脚本 ==="
    fi
}

function main()
{
	#### g_p_ProGram_Path 若非绝对路径(^/)则进行转换，是/$则进行剔除最后/字符,保证路径正确性,最终得出绝对路径！
	if [ -d "$g_p_ProGram_Path" ] 
	then
		echo $g_p_ProGram_Path | grep -q '^/' || g_p_ProGram_Path=$PWD/$g_p_ProGram_Path
		echo $g_p_ProGram_Path | grep -q '/$' && g_p_ProGram_Path=$(echo $g_p_ProGram_Path|sed 's/\/$//')
		tmp_proname=$(echo $g_p_ProGram_Path |awk -F'/' '{print $NF}')

		g_p_RollBack_PathFile=$(g_fn_Create_RollBack $tmp_proname)	
	
		### 核心主体:遍历文件
		### 注意文件路径已经切换到了$g_p_ProGram_Path下
		cd $g_p_ProGram_Path && find ./ -type f |sed 's/\.\///g'|sort | while read tmp_file_line
		do
			g_fn_Director $tmp_file_line $g_p_ProGram_Path
		done
	else
	    	### g_p_ProGram_Path 若是文件则只进行这一个文件的复制到目标目录下
	    	if [ -f $g_p_ProGram_Path ];then
	    		_content "$g_p_ProGram_Path is type f"
			tmp_file_line=$(basename "$g_p_ProGram_Path" | awk '{print $1}')
			tmp_file_path=$(dirname "$g_p_ProGram_Path" | awk '{print $1}')
			g_p_RollBack_PathFile=$(g_fn_Create_RollBack $tmp_file_line)
			g_fn_Director $tmp_file_line $tmp_file_path
	    	else
			_err "[ERROR]$g_p_ProGram_Path is not directory or file exist."
			exit 1
	    	fi
	fi
	
	if [ -f "${g_p_RollBack_PathFile}" ]
	then
		chmod +x "${g_p_RollBack_PathFile}"
		_info "回滚脚本准备完毕:${g_p_RollBack_PathFile}"
		exit 0
	fi
}

main
#mark
