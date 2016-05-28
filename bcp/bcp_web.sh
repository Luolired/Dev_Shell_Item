#!/bin/bash

# ***************************************************************************
# * 
# * @file:bcp.sh 
# * @author:Luolired@163.com 
# * @date:2015-07-27 20:53 
# * @version 7.1
# * @description:����web�ļ�����Ŀ¼����Ŀ¼������ͬ���ļ��򱸷ݲ����һ���ع��ű�;��������ֱ�Ӹ���
# * @Copyright (c) 007ka all right reserved 
#* 
#**************************************************************************/ 
export LANG=zh_CN.GBK
sudo_user=www-data
datetime=`date +%Y%m%d`
propath=$1
despath=$2
#�ع��ű�·��
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
    _info "��;�������ļ�����Ŀ¼����Ŀ¼������ͬ���ļ��򱸷ݲ����һ���ع��ű�;��������ֱ�Ӹ���"
    _err "�÷���`basename $0` Դ�ļ�·��Ŀ¼ Ŀ��·��Ŀ¼"
    _err "���磺#`basename $0` /home/lizx01/tmp /var/www/html/test"
   exit 1
fi

if [ -d $propath ] 
then
    #���Ǿ���·��(^/)�����ת������/$������޳����/�ַ�,��֤·����ȷ��
    echo $propath | grep -q '^/' || propath=$PWD/$propath
    echo $propath | grep -q '/$' && propath=$(echo $propath|sed 's/\/$//')
    proname=$(echo $propath |awk -F'/' '{print $NF}')
else
    _err "$propath directory does not exist." 
    exit 1
fi

if [ -d $despath ] 
then
    #���Ǿ���·��(^/)�����ת������/$������޳����/�ַ�,��֤·����ȷ��
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
#ע���ļ�·���Ѿ��л�����$propath��
cd $propath && find ./ -type f |sed 's/\.\///g'|sort | while read file_line
do
    #$ cd /home/lizx/test01/ && find ./ -type f |sed 's/\.\///g'
    #ini/msgsrv.xml
    #time
    if [ -f $despath/$file_line ]
    then
        #��Ŀ¼������ͬ���ļ��򱸷ݲ����һ���ع��ű�,���ݸ�ʽΪ��cp $despath/$file_line ${despath}/${file_line}.old.${last_mtime}
        #��ʼ���б��ݣ�Ȼ�󸲸������ļ�
        last_mtime=$(ls -l --time-style="+%Y%m%d" $despath/$file_line |awk '{print $(NF-1)}')
	dest_old_line=$(rename $file_line $last_mtime)
        sudo -u $sudo_user cp ${despath}/${file_line} ${despath}/${dest_old_line}
        cd $propath && sudo -u $sudo_user cp -rf $file_line ${despath}/${file_line}
        [ $? -eq 0 ] && echo "cd $despath && sudo -u $sudo_user cp ${despath}/${file_line} ${despath}/${file_line}.old.${datetime}" >>${rollback}/${proname}_${datetime}.sh
	[ $? -eq 0 ] && echo "sudo -u $sudo_user cp ${despath}/${dest_old_line} ${despath}/${file_line}" >>${rollback}/${proname}_${datetime}.sh
        _info "Ŀ��·��===����ͬ���ļ�:$file_line ===�������,�ɰ汾������Ϊ:$dest_old_line;��ǰ�汾:$file_line"
    fi
    if echo $file_line| grep -q '/'       #������ʱ���ж��Ƿ������Ŀ¼�ĸ���
    then 
        #eg:/home/lizx/guom01/proget02/two
        #cp: �޷�������ͨ�ļ�"/home/lizx/guom01/proget/ini/msgsrv.xml": û��ini�ļ���Ŀ¼
        #��Ŀ¼������ͬ���ļ�������и��ƣ�����ʱ���������ǣ����Ƶ����ļ�����Ŀ¼���ֱ���
        #����Ŀ¼�ĸ��ƣ���ȡĿ¼·��,����Ŀ¼·��
        directories=$(dirname "$despath/$file_line")
        sudo -u $sudo_user mkdir -p $directories && cd $propath && sudo -u $sudo_user cp -rf $file_line $directories && _info "Ŀ��·��===��ͬ���ļ�:$file_line Ŀ¼===�״δ���&�������"
    else
     	cd $propath && sudo -u $sudo_user cp -rf $file_line $despath && _info "Ŀ��·��===��ͬ���ļ�:$file_line �ļ�===�״θ������"
    fi
done

if [ -f ${rollback}/${proname}_${datetime}.sh ]
then
    chmod +x ${rollback}/${proname}_${datetime}.sh
    _info "�ع��ű�׼�����:${rollback}/${proname}_${datetime}.sh"
    exit 0
fi
#mark

