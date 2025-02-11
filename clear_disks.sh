#!/bin/bash

# 打印绿色文字
print_green() {
    echo -e "\e[01;32m$(date "+%Y-%m-%d %H:%M:%S") [INFO] $*\e[01;00m"
}

# 打印红色文字
print_red() {
    echo -e "\e[01;31m$(date "+%Y-%m-%d %H:%M:%S") [ERROR] $*\e[01;00m"
}

# 打印黄色文字
print_yellow() {
    echo -e "\e[01;33m$(date "+%Y-%m-%d %H:%M:%S") [WARNING] $*\e[01;00m"
}

# 提示用户确认操作
print_yellow "此操作将格式化除sda vda sr0之外的所有磁盘，数据将不可恢复。"
echo -e "\e[01;32m是否确定要继续？输入 'y' 确认，输入 'n' 退出: \e[01;00m\c"
read -r confirm

# 检查用户输入
if [[ "$confirm" != "y" ]]; then
    print_red "操作已取消。"
    exit 0
fi

# 清空指定设备数据的函数
clear_device() {
    local device=$1
    print_green "正在清空 /dev/$device 上的数据..."
    
    # 执行 dd 命令并捕获其退出状态
    if sudo dd if=/dev/zero of=/dev/"$device" bs=1M status=progress 2>/dev/null; then
        print_green "/dev/$device 上的数据已成功清空。"
    else
        # 检查是否是因为设备空间不足导致的错误
        if [ $? -eq 1 ]; then
            print_green "/dev/$device 上的数据已成功清空。"
        else
            print_red "清空 /dev/$device 上的数据失败。"
        fi
    fi
}

# 函数：运行 shellcheck 检查脚本
run_shellcheck() {
    if ! shellcheck "$0"; then
        print_red "Shellcheck found issues in the script. Exiting."
        exit 1
    fi
}

# 运行 shellcheck 检查脚本
run_shellcheck

# 获取除 sda vda sr0之外的所有块设备列表
devices=$(lsblk -dno NAME,MOUNTPOINT | awk '$2 == "" {print $1}' | grep -Ev '^(sda|vda|sr0)$')

# 遍历每个设备并清空数据
for device in $devices; do
    clear_device "$device"
done
