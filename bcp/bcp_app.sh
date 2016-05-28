#!/bin/bash

# ***************************************************************************
# * 
# * @file:bcp.sh 
# * @author:Luolired@163.com 
# * @date:2015-07-27 20:53 
# * @version 7.3
# * @description:�����ļ�����Ŀ¼����Ŀ¼������ͬ���ļ��򱸷ݲ����һ���ع��ű�;��������ֱ�Ӹ���
# * @Copyright (c) 007ka all right reserved 
# * @UpdateLog: 1.����OA��ˮ�ű�ʶ�汾
# *             2.�״θ���Ҳ����OA��ˮ�Ű汾����������
# *             3.����֧�����һ���ļ��ĸ���
# *             4.���庯��g_fn_Director �ֽ�
# *             5.�״��¸����ļ��������ع��ű�
#**************************************************************************/ 
export LANG=zh_CN.GBK

sudo_user=apps
#sudo_user=lizx01
g_s_DataTime=`date +%Y%m%d`

g_p_ProGram_Path=$1       #��Ҫ���ߵĳ����Ŀ¼·��/�ļ�
g_p_Dest_Path=$2          #����Ŀ��·��
g_i_OANUM=$3              #��������OA��ˮ��


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

### ʹ������help
if [ "$#" -lt 3 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	_content "=========================== Welcome ===================================="
	_info "��;��cp����Դ�ļ���ԴĿ¼,����Ŀ¼��������ͬ���ļ��򱸷ݲ����һ���ع��ű�;��������ֱ�Ӹ���"
	echo 
	_content "�÷���$0 Դ�ļ�·��Ŀ¼��Դ�ļ�·�� Ŀ��·��Ŀ¼ OA���"
	_info "Usage: $0 /home/lizx01/program_path /usr/local/007ka OANum" >&2
	echo 
	_content "Create Time:2016-05-04,Author:lizx 007ka-soc,V1.0"
	_content "Modified Time:2016-05-04,V2.0,Add Cp Only File"
	_content "=========================== Welcome ===================================="
	exit 1
fi

### g_p_Dest_Path ���Ǿ���·��(^/)�����ת������/$������޳����/�ַ�,��֤·����ȷ��,���յó�����·����
if [ -d $g_p_Dest_Path ] 
then
    echo $g_p_Dest_Path | grep -q '^/' || g_p_Dest_Path=$PWD/$g_p_Dest_Path
    echo $g_p_Dest_Path | grep -q '/$' && g_p_Dest_Path=$(echo $g_p_Dest_Path|sed 's/\/$//')
    #echo $g_p_Dest_Path
else
    _err "$g_p_Dest_Path directory does not exist." 
    exit 1
fi

### ���������OANum+g_s_DataTime��Żع��ű�,�ظ������
function g_fn_Create_RollBack()
{
	proname=$1
	### �ع�Ŀ¼����
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

### �ص���Ϣ��¼ָ��� 
function g_fn_RollBack()
{
	echo "$*" >> $g_p_RollBack_PathFile
}

### g_fn_Rename ����,��������Ĺ淶����
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
        #$file_line ini/msgsrv.xml ���ܴ�����Ŀ¼subdirectory(ini),�ع��ű��ͱ����е�iniĿ¼��
        subdirectory=$(echo ${g_p_Dest_Path}/${file_line} |awk -F '/' 'BEGIN{OFS="/"};{if(NF>1)NF=NF-1;print $0}')
        
        #��Ŀ¼������ͬ���ļ��򱸷ݲ����һ���ع��ű� readlink
        if [ -L ${g_p_Dest_Path}/${file_line} ]
        then
            oldlink_file=$(ls -lh ${g_p_Dest_Path}/${file_line} |awk -F'->' '{print $NF}')
            #���մ��������߱�ŵ��ļ�����ʽ
 	    dest_line=$(g_fn_Rename ${file_line} ${g_s_DataTime} ${g_i_OANUM})
            #�����ļ�������·������Ϊ���մ��汾����ļ�
            cd ${source_path} && sudo -u $sudo_user cp ${file_line} ${g_p_Dest_Path}/${dest_line}
	    #��ʼ�����ӵ��°汾
	    [ $? -eq 0 ] && cd ${g_p_Dest_Path} && sudo -u $sudo_user ln -sf $(echo $dest_line|awk -F '/' '{print $NF}') $file_line
            
	    #���˽ű�������Ҫ�ҵ�֮ǰ�����ӵ�Դ�ļ�
            #[ $? -eq 0 ] && echo "cd $subdirectory && sudo -u $sudo_user ln -sf $(echo $oldlink_file|awk -F '/' '{print $NF}') $(echo $file_line | awk -F '/' '{print $NF}')" >> ${g_p_RollBack_PathFile}
            [ $? -eq 0 ] && g_fn_RollBack "cd $subdirectory && sudo -u $sudo_user ln -sf $(echo $oldlink_file|awk -F '/' '{print $NF}') $(echo $file_line | awk -F '/' '{print $NF}')"
            _info "Ŀ��·��===����ͬ���ļ�:$file_line ������������===�������,�ɰ汾:${oldlink_file};��ǰ�汾:${dest_line}"

        else
            #Ŀ��·��δ����������,�ȴ���������,���滻Ϊ�������Ӹ�ʽ�淶
            last_mtime=$(ls -l --time-style="+%Y%m%d" $g_p_Dest_Path/$file_line |awk '{print $(NF-1)}')
            #���һ�α༭ʱ�����ŵ��ļ�����ʽ
	    #��Ϊ��ǰ����û�а汾��׷�ݼ�¼,����OANum �ض�000000��ʶ
            source_line=$(g_fn_Rename ${file_line} ${last_mtime} 000000 )
	    #���˽ű�����0000000�汾,����汾
            #[ $? -eq 0 ] && echo "cd $subdirectory && sudo -u $sudo_user ln -sf $(echo $source_line|awk -F '/' '{print $NF}') $(echo $file_line | awk -F '/' '{print $NF}')" >> ${g_p_RollBack_PathFile}
            [ $? -eq 0 ] && g_fn_RollBack "cd $subdirectory && sudo -u $sudo_user ln -sf $(echo $source_line|awk -F '/' '{print $NF}') $(echo $file_line | awk -F '/' '{print $NF}')"
            #��Ϊδ����������,�Ƚ��������ð汾���и��Ƴ������һ�α༭ʱ�䵱���汾��
            sudo -u $sudo_user cp ${g_p_Dest_Path}/${file_line} ${g_p_Dest_Path}/${source_line}
            
            #���մ��������߱�ŵ��ļ�����ʽ
            dest_line=$(g_fn_Rename ${file_line} ${g_s_DataTime} ${g_i_OANUM})
            #�����ļ�������·������Ϊ���մ��汾����ļ�
            cd $source_path && sudo -u $sudo_user cp $file_line ${g_p_Dest_Path}/${dest_line} 
	    #��ʼ�����ӵ��°汾
	    [ $? -eq 0 ] && cd $g_p_Dest_Path && sudo -u $sudo_user ln -sf $(echo $dest_line|awk -F '/' '{print $NF}') $file_line
            _info "Ŀ��·��===����ͬ���ļ�:$file_line �������ӹ淶===�������,�ɰ汾������Ϊ:${source_line};��ǰ�汾:${dest_line}"
        fi
    ### ����Ŀ��·��û�������ļ�Ŷ,��ζ�����״θ���
    else
	if echo ${file_line}| grep -q '/'       
    	then 
    	    #ע��:��Ҫ������Ŀ¼�Ĵ���,����:
            #cp: �޷�������ͨ�ļ�"/home/lizx/guom01/proget/ini/msgsrv.xml": û��ini�ļ���Ŀ¼,��������Ҫ����iniĿ¼
            #��Ŀ¼������ͬ���ļ�������и��ƣ�����ʱ���������ǣ����Ƶ����ļ�����Ŀ¼���ֱ���
            #�Ȼ��$file_line��Ŀ¼·��
            directories=$(dirname "$g_p_Dest_Path/$file_line")
            sudo -u $sudo_user mkdir -p $directories && _info "=== Ŀ��·����ͬ��Ŀ¼:$directoriesĿ¼�״δ������==="
	fi
	#��ʼ���ļ����д���,�ļ��״θ���,��Ҫ����������
        #���մ��������߱�ŵ��ļ�����ʽ
	dest_line=$(g_fn_Rename ${file_line} ${g_s_DataTime} ${g_i_OANUM})
	#�����ļ�������·������Ϊ���մ��汾����ļ�
	cd $source_path && sudo -u $sudo_user cp $file_line ${g_p_Dest_Path}/${dest_line}
        #��ʼ�����ӵ��°汾
        [ $? -eq 0 ] && cd $g_p_Dest_Path && sudo -u $sudo_user ln -sf $(echo $dest_line|awk -F '/' '{print $NF}') $file_line
        _info "=== Ŀ��·����ͬ���ļ�:$file_line�ļ��״θ���&���������===��ǰ�汾:${dest_line}"
	_info "=== �״θ��Ʋ������ع��ű� ==="
    fi
}

function main()
{
	#### g_p_ProGram_Path ���Ǿ���·��(^/)�����ת������/$������޳����/�ַ�,��֤·����ȷ��,���յó�����·����
	if [ -d "$g_p_ProGram_Path" ] 
	then
		echo $g_p_ProGram_Path | grep -q '^/' || g_p_ProGram_Path=$PWD/$g_p_ProGram_Path
		echo $g_p_ProGram_Path | grep -q '/$' && g_p_ProGram_Path=$(echo $g_p_ProGram_Path|sed 's/\/$//')
		tmp_proname=$(echo $g_p_ProGram_Path |awk -F'/' '{print $NF}')

		g_p_RollBack_PathFile=$(g_fn_Create_RollBack $tmp_proname)	
	
		### ��������:�����ļ�
		### ע���ļ�·���Ѿ��л�����$g_p_ProGram_Path��
		cd $g_p_ProGram_Path && find ./ -type f |sed 's/\.\///g'|sort | while read tmp_file_line
		do
			g_fn_Director $tmp_file_line $g_p_ProGram_Path
		done
	else
	    	### g_p_ProGram_Path �����ļ���ֻ������һ���ļ��ĸ��Ƶ�Ŀ��Ŀ¼��
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
		_info "�ع��ű�׼�����:${g_p_RollBack_PathFile}"
		exit 0
	fi
}

main
#mark
