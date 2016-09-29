#!/bin/bash

# ***************************************************************************
# * 
# * @file:ops_ini.sh 
# * @author:Luolired@163.com 
# * @date:2016-09-29 20:53 
# * @version 0.1
# * @description:自动化修改配置文件的变量
# * @Copyright (c) 007ka all right reserved 
# * @UpdateLog:
# *	      1.配置库有脚本变量直接定义
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
    _info "用途:自动化修改配置文件的变量"
    _err "用法：`basename $0` 源文件路径"
    _err "例如：#`basename $0` /home/lizx01/XXXX.ini"
    exit 1
else
	[ -f $ops_file ] || {
		_err "$ops_file is not File!!!"
    		_err "用法：`basename $0` 源文件路径"
   		 _err "例如：#`basename $0` /home/lizx01/XXXX.ini"
		exit 1
	}
fi

##########################################
#
#	变量替换库(配置里的交集)
#
##########################################
#;与WebsiteOrderSrv连接MsgSrv配置
ip_WebsiteOrderSrv="10.20.10.134"
port_WebsiteOrderSrv="6010"
#;与Distributor连接MsgSrv配置
ip_Distributor="10.20.10.213"
port_Distributor="7020"
#;短连接发往PhoneInfoSrv获取归属地信息
ip_PhoneInfoSrv="10.20.10.213"
port_PhoneInfoSrv="7020"
#;与WebsiteCharge连接MsgSrv配置
ip_WebSiteCharge="10.20.10.212"
port_WebSiteCharge="6004"
#;与CCBFlowSrv连接MsgSrv配置
ip_CCBFlowSrv="10.20.10.212"
port_CCBFlowSrv="6004"
#;连接QueryClient服务程序
ip_QueryClient="10.20.10.122" 
port_QueryClient="6007" 
#;与CouponOrdChkSrv 连接MsgSrv配置
ip_CouponOrdChkSrv="10.20.10.212"
port_CouponOrdChkSrv="6004"
#;与CardBackstage连接MsgSrv配置
ip_CardBackstage="10.20.10.212"
port_CardBackstage="6004"
#;与CmbWapSrv连接MsgSrv配置
ip_CmbWapSrv="10.20.10.212"
port_CmbWapSrv="6004"
#;与FluxAmountQuerySrv连接MsgSrv配置
ip_FluxAmountQuerySrv="10.20.10.213"
port_FluxAmountQuerySrv="7020"
#;与OrderIdSystemSrv连接MsgSrv配置
ip_OrderIdSystemSrv="10.20.10.212"
port_OrderIdSystemSrv="6006"
#;短连接发往WofuCheckService获取归属地信息
ip_WofuCheckService="10.20.10.212"
port_WofuCheckService="6004"
#;与PayTran连接MsgSrv配置
ip_PayTran="10.20.10.134"
port_PayTran="6010"
#;CmbWapSrv通信key
cmbWapSrvKey="fasdfasdfasdfasdf"
#;QueryClient的通讯key 
QueryClientKey="XXXXXXXXXXXXXXXXXXX"
#;websiteCharge通信key
WebSiteChargeKey="Xy8XXXXXXXXXXXXXw=="
#;OrderIdSystemSrv通信key
OrderIdSystemSrvKey="rlcKXXXXXXXXXXXXXyhbw=="

##############################    Luolired 	###############################
############################## 	  ENd	#######################################

function main()
{
	#模块复制修改变量技巧:
	#vim编辑器 :.,$s/from/to/     ：  对当前行到最后一行的内容进行替换
	##### 模块一
 	_info "开始查找并替换与WebsiteOrderSrv连接MsgSrv配置"
	grep -Eq "^ip_WebsiteOrderSrv=" $ops_file && {
		#匹配开头包含关键字变量，进行配置模板库的替换变量
		sed -i "s/\(^ip_WebsiteOrderSrv=\)\S\S*/\1\"$ip_WebsiteOrderSrv\"/" $ops_file
		sed -i "s/\(^port_WebsiteOrderSrv=\)\S\S*/\1\"$port_WebsiteOrderSrv\"/" $ops_file
		grep -E "^ip_WebsiteOrderSrv=" $ops_file
	} || {
		_info "配置不存在^ip_WebsiteOrderSrv=,退出继续下一项检测"
	}
	
	##### 模块二
        _info "开始查找并替换;与Distributor连接MsgSrv配置"
        grep -Eq "^ip_Distributor=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^ip_Distributor=\)\S\S*/\1\"$ip_Distributor\"/" $ops_file
                sed -i "s/\(^port_Distributor=\)\S\S*/\1\"$port_Distributor\"/" $ops_file
                grep -E "^ip_Distributor=" $ops_file
        } || {
                _info "配置不存在^ip_Distributor=,退出继续下一项检测"
        }

	##### 模块三
        _info "开始查找并替换;短连接发往PhoneInfoSrv获取归属地信息"
        grep -Eq "^ip_PhoneInfoSrv=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^ip_PhoneInfoSrv=\)\S\S*/\1\"$ip_PhoneInfoSrv\"/" $ops_file
                sed -i "s/\(^port_PhoneInfoSrv=\)\S\S*/\1\"$port_PhoneInfoSrv\"/" $ops_file
                grep -E "^ip_PhoneInfoSrv=" $ops_file
        } || {
                _info "配置不存在^ip_PhoneInfoSrv=,退出继续下一项检测"
        }

	##### 模块四
        _info "开始查找并替换;与WebsiteCharge连接MsgSrv配置"
        grep -Eq "^ip_WebSiteCharge=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^ip_WebSiteCharge=\)\S\S*/\1\"$ip_WebSiteCharge\"/" $ops_file
                sed -i "s/\(^port_WebSiteCharge=\)\S\S*/\1\"$port_WebSiteCharge\"/" $ops_file
                grep -E "^ip_WebSiteCharge=" $ops_file
        } || {
                _info "配置不存在^ip_WebSiteCharge=,退出继续下一项检测"
        }

        ##### 模块五
        _info "开始查找并替换;与CCBFlowSrv连接MsgSrv配置"
        grep -Eq "^ip_CCBFlowSrv=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^ip_CCBFlowSrv=\)\S\S*/\1\"$ip_CCBFlowSrv\"/" $ops_file
                sed -i "s/\(^port_CCBFlowSrv=\)\S\S*/\1\"$port_CCBFlowSrv\"/" $ops_file
                grep -E "^ip_CCBFlowSrv=" $ops_file
        } || {
                _info "配置不存在^ip_CCBFlowSrv=,退出继续下一项检测"
        }
	
	##### 模块六
        _info "开始查找并替换;连接QueryClient服务程序"
        grep -Eq "^ip_QueryClient=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^ip_QueryClient=\)\S\S*/\1\"$ip_QueryClient\"/" $ops_file
                sed -i "s/\(^port_QueryClient=\)\S\S*/\1\"$port_QueryClient\"/" $ops_file
                grep -E "^ip_QueryClient=" $ops_file
        } || {
                _info "配置不存在^ip_QueryClient=,退出继续下一项检测"
        }

	
        ##### 模块七
        _info "开始查找并替换;与CouponOrdChkSrv 连接MsgSrv配置"
        grep -Eq "^ip_CouponOrdChkSrv=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^ip_CouponOrdChkSrv=\)\S\S*/\1\"$ip_CouponOrdChkSrv\"/" $ops_file
                sed -i "s/\(^port_CouponOrdChkSrv=\)\S\S*/\1\"$port_CouponOrdChkSrv\"/" $ops_file
                grep -E "^ip_CouponOrdChkSrv=" $ops_file
        } || {
                _info "配置不存在^ip_CouponOrdChkSrv=,退出继续下一项检测"
        }

	

        ##### 模块八
        _info "开始查找并替换;与CardBackstage连接MsgSrv配置"
        grep -Eq "^ip_CardBackstage=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^ip_CardBackstage=\)\S\S*/\1\"$ip_CardBackstage\"/" $ops_file
                sed -i "s/\(^port_CardBackstage=\)\S\S*/\1\"$port_CardBackstage\"/" $ops_file
                grep -E "^ip_CardBackstage=" $ops_file
        } || {
                _info "配置不存在^ip_CardBackstage=,退出继续下一项检测"
        }

	##### 模块九
        _info "开始查找并替换;与CmbWapSrv连接MsgSrv配置"
        grep -Eq "^ip_CmbWapSrv=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^ip_CmbWapSrv=\)\S\S*/\1\"$ip_CmbWapSrv\"/" $ops_file
                sed -i "s/\(^port_CmbWapSrv=\)\S\S*/\1\"$port_CmbWapSrv\"/" $ops_file
                grep -E "^ip_CmbWapSrv=" $ops_file
        } || {
                _info "配置不存在^ip_CmbWapSrv=,退出继续下一项检测"
        }

	##### 模块十
        _info "开始查找并替换;与FluxAmountQuerySrv连接MsgSrv配置"
        grep -Eq "^ip_FluxAmountQuerySrv=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^ip_FluxAmountQuerySrv=\)\S\S*/\1\"$ip_FluxAmountQuerySrv\"/" $ops_file
                sed -i "s/\(^port_FluxAmountQuerySrv=\)\S\S*/\1\"$port_FluxAmountQuerySrv\"/" $ops_file
                grep -E "^ip_FluxAmountQuerySrv=" $ops_file
        } || {
                _info "配置不存在^ip_FluxAmountQuerySrv=,退出继续下一项检测"
        }

	
        ##### 模块十一
        _info "开始查找并替换;与OrderIdSystemSrv连接MsgSrv配置"
        grep -Eq "^ip_OrderIdSystemSrv=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^ip_OrderIdSystemSrv=\)\S\S*/\1\"$ip_OrderIdSystemSrv\"/" $ops_file
                sed -i "s/\(^port_OrderIdSystemSrv=\)\S\S*/\1\"$port_OrderIdSystemSrv\"/" $ops_file
                grep -E "^ip_OrderIdSystemSrv=" $ops_file
        } || {
                _info "配置不存在^ip_OrderIdSystemSrv=,退出继续下一项检测"
        }

	

        ##### 模块十二
        _info "开始查找并替换;短连接发往WofuCheckService获取归属地信息"
        grep -Eq "^ip_WofuCheckService=" $ops_file && { 
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^ip_WofuCheckService=\)\S\S*/\1\"$ip_WofuCheckService\"/" $ops_file
                sed -i "s/\(^port_WofuCheckService=\)\S\S*/\1\"$port_WofuCheckService\"/" $ops_file
                grep -E "^ip_WofuCheckService=" $ops_file
        } || {
                _info "配置不存在^ip_WofuCheckService=,退出继续下一项检测"
        }

	##### 模块十三
        _info "开始查找并替换;与PayTran连接MsgSrv配置"
        grep -Eq "^ip_PayTran=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^ip_PayTran=\)\S\S*/\1\"$ip_PayTran\"/" $ops_file
                sed -i "s/\(^port_PayTran=\)\S\S*/\1\"$port_PayTran\"/" $ops_file
                grep -E "^ip_PayTran=" $ops_file
        } || {
                _info "配置不存在^ip_PayTran=,退出继续下一项检测"
        }

	##### 模块十四
        _info "开始查找并替换;与CmbWapSrv通信key"
        grep -Eq "^cmbWapSrvKey=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^cmbWapSrvKey=\)\S\S*/\1\"$cmbWapSrvKey\"/" $ops_file
                grep -E "^cmbWapSrvKey=" $ops_file
        } || {
                _info "配置不存在^cmbWapSrvKey=,退出继续下一项检测"
        }

	##### 模块十五
        _info "开始查找并替换;与websiteCharge通信key"
        grep -Eq "^WebSiteChargeKey=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^WebSiteChargeKey=\)\S\S*/\1\"$WebSiteChargeKey\"/" $ops_file
                grep -E "^WebSiteChargeKey=" $ops_file
        } || {
                _info "配置不存在^WebSiteChargeKey=,退出继续下一项检测"
        }

	##### 模块十六
        _info "开始查找并替换;与QueryClient的通讯key"
        grep -Eq "^QueryClientKey=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^QueryClientKey=\)\S\S*/\1\"$QueryClientKey\"/" $ops_file
                grep -E "^QueryClientKey=" $ops_file
        } || {
                _info "配置不存在^QueryClientKey=,退出继续下一项检测"
        }

	
        ##### 模块十七
        _info "开始查找并替换;与OrderIdSystemSrv通信key"
        grep -Eq "^OrderIdSystemSrvKey=" $ops_file && {
                #匹配开头包含关键字变量，进行配置模板库的替换变量
                sed -i "s/\(^OrderIdSystemSrvKey=\)\S\S*/\1\"$OrderIdSystemSrvKey\"/" $ops_file
                grep -E "^OrderIdSystemSrvKey=" $ops_file
        } || {
                _info "配置不存在^OrderIdSystemSrvKey=,退出继续下一项检测"
        }


}

#main
main
