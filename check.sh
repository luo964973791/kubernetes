#!/bin/bash
################################################################
# Copyright (C) 1998-2022 Tencent Inc. All Rights Reserved
# Description: a script to check if the centos server.
# @Time    : 2022/05/18 17:29 下午
# @Author  : ukec
# @File    : check.sh
################################################################
red() 
{
    currentTime=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "\033[31m$currentTime    $1    $2\033[0m" >&2
}

green() 
{
    currentTime=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "\033[32m$currentTime    $1    $2\033[0m" >&2
}

check_city()
{
    time_zone="Asia/Shanghai"
    currentTimezone=$(timedatectl | grep "Time zone" |awk '{print $3}')
    if [ "$currentTimezone" == "$time_zone" ];then
        green "INFO" "Check if timezone is ok."
    else
        red "WARNING" "Check if timezone is failed"
        return 1
    fi
}

check_swap()
{
    swap_total=$(free -m|grep Swap|awk '{print $2}')
    if [[ $swap_total -eq 0 ]];then
        green "INFO" "swap is off"
    else
        red "WARNING" "swap is on"
        return 1
    fi
}

check_selinux()
{

    os_version=$(grep '^NAME' /etc/os-release |awk -F '=' '{print $NF}'|sed 's/"//g')
    if [ "$os_version" == "uos" ] ;then
        green "INFO" "Ok. Selinux status is disabled."

    fi
    isDisabled=$(getenforce)
    if [ "$isDisabled" != "Disabled" ] && [ "$isDisabled" != "SELINUX=disabled" ];then
        red "ERROR" "Nok. Selinux status is not disabled."

    else
        green "INFO" "Ok. Selinux status is disabled."
        return 1

    fi
}

check_os() 
{
    if [ -f /etc/redhat-release ]; then
        version=$(awk '{print $4}' < /etc/redhat-release |cut -d '.' -f1-2)
    elif [ -f /etc/centos-release ]; then
        version=$(awk '{print $4}' < /etc/centos-release |cut -d '.' -f1-2)
    else
        red "ERROR" "Unknow OS type"
        return 1
    fi
    if [ "$version" == 7.6 ] ;then
        green "INFO" "os version is ok!"
    else
        red "ERROR" "os version is not 7.6"
        return 1

    fi
}

check_city
check_swap
check_selinux
check_os
