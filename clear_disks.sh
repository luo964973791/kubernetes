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
    local MOUNTPOINT=$(lsblk -no MOUNTPOINT /dev/"$device")
    local UUID=$(blkid -s UUID -o value /dev/"$device")
    print_green "正在清空 /dev/$device 上的数据..."

    if [[ -n "$MOUNTPOINT" ]]; then
        print_green "设备$device已挂载在$MOUNTPOINT，正在卸载..."
        if umount /dev/"$device"; then
            print_green "设备$device已卸载"
        else
            print_red "无法卸载设备$device。请手动检查并重试。"
            exit 1
        fi
    else
        print_green "设备$device未挂载。"
    fi

    # 检查/etc/fstab是否包含该设备或UUID
    if grep -q "/dev/$device" /etc/fstab; then
        print_green "警告: /etc/fstab中找到与/dev/$device相关的行，正在删除..."
        sed -i "\|/dev/$device|d" /etc/fstab
        print_green "/dev/$device的相关行已删除"
    fi

    if [[ -n "$UUID" ]] && grep -q "$UUID" /etc/fstab; then
        print_green "警告: /etc/fstab中找到与UUID $UUID相关的行，正在删除..."
        sed -i "\|$UUID|d" /etc/fstab
        print_green "UUID $UUID的相关行已删除"
    fi

    # 执行 wipefs 命令并捕获其退出状态
    print_green "正在执行 wipefs -a /dev/$device..."
    if wipefs -a /dev/"$device" 2>/dev/null; then
        print_green "/dev/$device 上的数据已成功清空,请再次检查/etc/fstab文件是否清除干净,再三确认/etc/fstab文件没有问题以后,重启服务器"
        cat /etc/fstab
    else
        # 检查是否是因为设备空间不足导致的错误
        if [ $? -eq 1 ]; then
            print_green "/dev/$device 上的数据已成功清空"
        else
            print_red "清空 /dev/$device 上的数据失败。"
            exit 1
        fi
    fi
}

# 函数：运行 shellcheck 检查脚本
# run_shellcheck() {
#     if ! shellcheck "$0"; then
#         print_red "Shellcheck found issues in the script. Exiting."
#         exit 1
#     fi
# }

# 运行 shellcheck 检查脚本
# run_shellcheck

# 获取除 sda vda sr0之外的所有块设备列表
devices=$(lsblk -dno NAME | grep -vE 'sda|vda|sr0' |awk '{print $1}')

# 遍历每个设备并清空数据
for device in $devices; do
    clear_device "$device"
done
