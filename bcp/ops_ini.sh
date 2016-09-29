#!/bin/bash

# ***************************************************************************
# * 
# * @file:ops_ini.sh 
# * @author:Luolired@163.com 
# * @date:2016-09-29 20:53 
# * @version 0.1
# * @description:�Զ����޸������ļ��ı���
# * @Copyright (c) 007ka all right reserved 
# * @UpdateLog:
# *	      1.���ÿ��нű�����ֱ�Ӷ���
#**************************************************************************/ 
export LANG=zh_CN.GBK
sudo_user=lizx

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

ops_file=$1

if [ $# -lt 1 ]
then
    _info "��;:�Զ����޸������ļ��ı���"
    _err "�÷���`basename $0` Դ�ļ�·��"
    _err "���磺#`basename $0` /home/lizx01/XXXX.ini"
    exit 1
else
	[ -f $ops_file ] || {
		_err "$ops_file is not File!!!"
    		_err "�÷���`basename $0` Դ�ļ�·��"
   		 _err "���磺#`basename $0` /home/lizx01/XXXX.ini"
		exit 1
	}
fi

##########################################
#
#	�����滻��(������Ľ���)
#
##########################################
#;��WebsiteOrderSrv����MsgSrv����
ip_WebsiteOrderSrv="10.20.10.134"
port_WebsiteOrderSrv="6010"
#;��Distributor����MsgSrv����
ip_Distributor="10.20.10.213"
port_Distributor="7020"
#;�����ӷ���PhoneInfoSrv��ȡ��������Ϣ
ip_PhoneInfoSrv="10.20.10.213"
port_PhoneInfoSrv="7020"
#;��WebsiteCharge����MsgSrv����
ip_WebSiteCharge="10.20.10.212"
port_WebSiteCharge="6004"
#;��CCBFlowSrv����MsgSrv����
ip_CCBFlowSrv="10.20.10.212"
port_CCBFlowSrv="6004"
#;����QueryClient�������
ip_QueryClient="10.20.10.122" 
port_QueryClient="6007" 
#;��CouponOrdChkSrv ����MsgSrv����
ip_CouponOrdChkSrv="10.20.10.212"
port_CouponOrdChkSrv="6004"
#;��CardBackstage����MsgSrv����
ip_CardBackstage="10.20.10.212"
port_CardBackstage="6004"
#;��CmbWapSrv����MsgSrv����
ip_CmbWapSrv="10.20.10.212"
port_CmbWapSrv="6004"
#;��FluxAmountQuerySrv����MsgSrv����
ip_FluxAmountQuerySrv="10.20.10.213"
port_FluxAmountQuerySrv="7020"
#;��OrderIdSystemSrv����MsgSrv����
ip_OrderIdSystemSrv="10.20.10.212"
port_OrderIdSystemSrv="6006"
#;�����ӷ���WofuCheckService��ȡ��������Ϣ
ip_WofuCheckService="10.20.10.212"
port_WofuCheckService="6004"
#;��PayTran����MsgSrv����
ip_PayTran="10.20.10.134"
port_PayTran="6010"
#;CmbWapSrvͨ��key
cmbWapSrvKey="fasdfasdfasdfasdf"
#;QueryClient��ͨѶkey 
QueryClientKey="XXXXXXXXXXXXXXXXXXX"
#;websiteChargeͨ��key
WebSiteChargeKey="Xy8XXXXXXXXXXXXXw=="
#;OrderIdSystemSrvͨ��key
OrderIdSystemSrvKey="rlcKXXXXXXXXXXXXXyhbw=="

##############################    Luolired 	###############################
############################## 	  ENd	#######################################

function main()
{
	#ģ�鸴���޸ı�������:
	#vim�༭�� :.,$s/from/to/     ��  �Ե�ǰ�е����һ�е����ݽ����滻
	##### ģ��һ
 	_info "��ʼ���Ҳ��滻��WebsiteOrderSrv����MsgSrv����"
	grep -Eq "^ip_WebsiteOrderSrv=" $ops_file && {
		#ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
		sed -i "s/\(^ip_WebsiteOrderSrv=\)\S\S*/\1\"$ip_WebsiteOrderSrv\"/" $ops_file
		sed -i "s/\(^port_WebsiteOrderSrv=\)\S\S*/\1\"$port_WebsiteOrderSrv\"/" $ops_file
		grep -E "^ip_WebsiteOrderSrv=" $ops_file
	} || {
		_info "���ò�����^ip_WebsiteOrderSrv=,�˳�������һ����"
	}
	
	##### ģ���
        _info "��ʼ���Ҳ��滻;��Distributor����MsgSrv����"
        grep -Eq "^ip_Distributor=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^ip_Distributor=\)\S\S*/\1\"$ip_Distributor\"/" $ops_file
                sed -i "s/\(^port_Distributor=\)\S\S*/\1\"$port_Distributor\"/" $ops_file
                grep -E "^ip_Distributor=" $ops_file
        } || {
                _info "���ò�����^ip_Distributor=,�˳�������һ����"
        }

	##### ģ����
        _info "��ʼ���Ҳ��滻;�����ӷ���PhoneInfoSrv��ȡ��������Ϣ"
        grep -Eq "^ip_PhoneInfoSrv=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^ip_PhoneInfoSrv=\)\S\S*/\1\"$ip_PhoneInfoSrv\"/" $ops_file
                sed -i "s/\(^port_PhoneInfoSrv=\)\S\S*/\1\"$port_PhoneInfoSrv\"/" $ops_file
                grep -E "^ip_PhoneInfoSrv=" $ops_file
        } || {
                _info "���ò�����^ip_PhoneInfoSrv=,�˳�������һ����"
        }

	##### ģ����
        _info "��ʼ���Ҳ��滻;��WebsiteCharge����MsgSrv����"
        grep -Eq "^ip_WebSiteCharge=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^ip_WebSiteCharge=\)\S\S*/\1\"$ip_WebSiteCharge\"/" $ops_file
                sed -i "s/\(^port_WebSiteCharge=\)\S\S*/\1\"$port_WebSiteCharge\"/" $ops_file
                grep -E "^ip_WebSiteCharge=" $ops_file
        } || {
                _info "���ò�����^ip_WebSiteCharge=,�˳�������һ����"
        }

        ##### ģ����
        _info "��ʼ���Ҳ��滻;��CCBFlowSrv����MsgSrv����"
        grep -Eq "^ip_CCBFlowSrv=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^ip_CCBFlowSrv=\)\S\S*/\1\"$ip_CCBFlowSrv\"/" $ops_file
                sed -i "s/\(^port_CCBFlowSrv=\)\S\S*/\1\"$port_CCBFlowSrv\"/" $ops_file
                grep -E "^ip_CCBFlowSrv=" $ops_file
        } || {
                _info "���ò�����^ip_CCBFlowSrv=,�˳�������һ����"
        }
	
	##### ģ����
        _info "��ʼ���Ҳ��滻;����QueryClient�������"
        grep -Eq "^ip_QueryClient=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^ip_QueryClient=\)\S\S*/\1\"$ip_QueryClient\"/" $ops_file
                sed -i "s/\(^port_QueryClient=\)\S\S*/\1\"$port_QueryClient\"/" $ops_file
                grep -E "^ip_QueryClient=" $ops_file
        } || {
                _info "���ò�����^ip_QueryClient=,�˳�������һ����"
        }

	
        ##### ģ����
        _info "��ʼ���Ҳ��滻;��CouponOrdChkSrv ����MsgSrv����"
        grep -Eq "^ip_CouponOrdChkSrv=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^ip_CouponOrdChkSrv=\)\S\S*/\1\"$ip_CouponOrdChkSrv\"/" $ops_file
                sed -i "s/\(^port_CouponOrdChkSrv=\)\S\S*/\1\"$port_CouponOrdChkSrv\"/" $ops_file
                grep -E "^ip_CouponOrdChkSrv=" $ops_file
        } || {
                _info "���ò�����^ip_CouponOrdChkSrv=,�˳�������һ����"
        }

	

        ##### ģ���
        _info "��ʼ���Ҳ��滻;��CardBackstage����MsgSrv����"
        grep -Eq "^ip_CardBackstage=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^ip_CardBackstage=\)\S\S*/\1\"$ip_CardBackstage\"/" $ops_file
                sed -i "s/\(^port_CardBackstage=\)\S\S*/\1\"$port_CardBackstage\"/" $ops_file
                grep -E "^ip_CardBackstage=" $ops_file
        } || {
                _info "���ò�����^ip_CardBackstage=,�˳�������һ����"
        }

	##### ģ���
        _info "��ʼ���Ҳ��滻;��CmbWapSrv����MsgSrv����"
        grep -Eq "^ip_CmbWapSrv=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^ip_CmbWapSrv=\)\S\S*/\1\"$ip_CmbWapSrv\"/" $ops_file
                sed -i "s/\(^port_CmbWapSrv=\)\S\S*/\1\"$port_CmbWapSrv\"/" $ops_file
                grep -E "^ip_CmbWapSrv=" $ops_file
        } || {
                _info "���ò�����^ip_CmbWapSrv=,�˳�������һ����"
        }

	##### ģ��ʮ
        _info "��ʼ���Ҳ��滻;��FluxAmountQuerySrv����MsgSrv����"
        grep -Eq "^ip_FluxAmountQuerySrv=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^ip_FluxAmountQuerySrv=\)\S\S*/\1\"$ip_FluxAmountQuerySrv\"/" $ops_file
                sed -i "s/\(^port_FluxAmountQuerySrv=\)\S\S*/\1\"$port_FluxAmountQuerySrv\"/" $ops_file
                grep -E "^ip_FluxAmountQuerySrv=" $ops_file
        } || {
                _info "���ò�����^ip_FluxAmountQuerySrv=,�˳�������һ����"
        }

	
        ##### ģ��ʮһ
        _info "��ʼ���Ҳ��滻;��OrderIdSystemSrv����MsgSrv����"
        grep -Eq "^ip_OrderIdSystemSrv=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^ip_OrderIdSystemSrv=\)\S\S*/\1\"$ip_OrderIdSystemSrv\"/" $ops_file
                sed -i "s/\(^port_OrderIdSystemSrv=\)\S\S*/\1\"$port_OrderIdSystemSrv\"/" $ops_file
                grep -E "^ip_OrderIdSystemSrv=" $ops_file
        } || {
                _info "���ò�����^ip_OrderIdSystemSrv=,�˳�������һ����"
        }

	

        ##### ģ��ʮ��
        _info "��ʼ���Ҳ��滻;�����ӷ���WofuCheckService��ȡ��������Ϣ"
        grep -Eq "^ip_WofuCheckService=" $ops_file && { 
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^ip_WofuCheckService=\)\S\S*/\1\"$ip_WofuCheckService\"/" $ops_file
                sed -i "s/\(^port_WofuCheckService=\)\S\S*/\1\"$port_WofuCheckService\"/" $ops_file
                grep -E "^ip_WofuCheckService=" $ops_file
        } || {
                _info "���ò�����^ip_WofuCheckService=,�˳�������һ����"
        }

	##### ģ��ʮ��
        _info "��ʼ���Ҳ��滻;��PayTran����MsgSrv����"
        grep -Eq "^ip_PayTran=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^ip_PayTran=\)\S\S*/\1\"$ip_PayTran\"/" $ops_file
                sed -i "s/\(^port_PayTran=\)\S\S*/\1\"$port_PayTran\"/" $ops_file
                grep -E "^ip_PayTran=" $ops_file
        } || {
                _info "���ò�����^ip_PayTran=,�˳�������һ����"
        }

	##### ģ��ʮ��
        _info "��ʼ���Ҳ��滻;��CmbWapSrvͨ��key"
        grep -Eq "^cmbWapSrvKey=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^cmbWapSrvKey=\)\S\S*/\1\"$cmbWapSrvKey\"/" $ops_file
                grep -E "^cmbWapSrvKey=" $ops_file
        } || {
                _info "���ò�����^cmbWapSrvKey=,�˳�������һ����"
        }

	##### ģ��ʮ��
        _info "��ʼ���Ҳ��滻;��websiteChargeͨ��key"
        grep -Eq "^WebSiteChargeKey=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^WebSiteChargeKey=\)\S\S*/\1\"$WebSiteChargeKey\"/" $ops_file
                grep -E "^WebSiteChargeKey=" $ops_file
        } || {
                _info "���ò�����^WebSiteChargeKey=,�˳�������һ����"
        }

	##### ģ��ʮ��
        _info "��ʼ���Ҳ��滻;��QueryClient��ͨѶkey"
        grep -Eq "^QueryClientKey=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^QueryClientKey=\)\S\S*/\1\"$QueryClientKey\"/" $ops_file
                grep -E "^QueryClientKey=" $ops_file
        } || {
                _info "���ò�����^QueryClientKey=,�˳�������һ����"
        }

	
        ##### ģ��ʮ��
        _info "��ʼ���Ҳ��滻;��OrderIdSystemSrvͨ��key"
        grep -Eq "^OrderIdSystemSrvKey=" $ops_file && {
                #ƥ�俪ͷ�����ؼ��ֱ�������������ģ�����滻����
                sed -i "s/\(^OrderIdSystemSrvKey=\)\S\S*/\1\"$OrderIdSystemSrvKey\"/" $ops_file
                grep -E "^OrderIdSystemSrvKey=" $ops_file
        } || {
                _info "���ò�����^OrderIdSystemSrvKey=,�˳�������һ����"
        }


}

#main
main
