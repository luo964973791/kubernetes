#!/bin/bash

# 函数：输出信息日志
log_info() {
    echo -e "\e[01;32m$(date "+%Y-%m-%d %H:%M:%S") [INFO] $*\e[01;00m"
}

# 函数：输出错误日志
log_error() {
    echo -e "\e[01;31m$(date "+%Y-%m-%d %H:%M:%S") [ERROR] $*\e[01;00m"
}

# 函数：检查并安装命令
install_command() {
    if ! command -v "$1" &> /dev/null; then
        log_info "$1 is not installed. Attempting to install..."

        # 检查操作系统类型并安装
        if [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            apt-get update && apt-get install -y "$2"
        elif [ -f /etc/redhat-release ]; then
            # CentOS/RHEL
            yum install -y "$2"
        else
            log_error "Unsupported OS. Please install $1 manually."
            exit 1
        fi

        # 再次检查是否成功安装
        if ! command -v "$1" &> /dev/null; then
            log_error "Failed to install $1. Please install it manually."
            exit 1
        fi
    fi
}

# 函数：检查并安装 shellcheck
install_shellcheck() {
    if ! command -v shellcheck &> /dev/null; then
        log_info "shellcheck is not installed. Attempting to install..."
        scversion="stable"
        cd /tmp || exit

        # 检查并删除现有的 shellcheck 目录
        if [ -d "shellcheck-${scversion}" ]; then
            rm -rf "shellcheck-${scversion}"
        fi

        wget -q "https://github.com/koalaman/shellcheck/releases/download/${scversion}/shellcheck-${scversion}.linux.x86_64.tar.xz" -O shellcheck.tar.xz
        tar -xJf shellcheck.tar.xz
        cp "shellcheck-${scversion}/shellcheck" /usr/bin/
        shellcheck --version

        # 再次检查是否成功安装
        if ! command -v shellcheck &> /dev/null; then
            log_error "Failed to install shellcheck. Please install it manually."
            exit 1
        fi
    fi
}

# 函数：运行 shellcheck
run_shellcheck() {
    if ! shellcheck "$0"; then
        log_error "Shellcheck found issues in the script. Exiting."
        exit 1
    fi
}

# 函数：获取容器的 PID
get_container_pid() {
    local container_id=$1
    local pid

    if pgrep -x "dockerd" > /dev/null; then
        # 使用 Docker 获取容器的 PID
        pid=$(docker inspect --format '{{.State.Pid}}' "$container_id" 2>/dev/null)
    elif pgrep -x "containerd" > /dev/null; then
        # 使用 crictl 获取容器的 PID
        pid=$(crictl inspect --output json "$container_id" | jq -r '.info.pid')
    else
        log_error "Neither Docker nor containerd is running."
        exit 1
    fi

    echo "$pid"
}

# 函数：检查并安装必要的命令
check_and_install_commands() {
    install_command jq jq
    install_command nsenter util-linux
    install_command netstat net-tools
    install_command tcpdump tcpdump
    install_command tar tar
}

# 主函数
main() {
    # 检查并安装必要的命令
    check_and_install_commands

    # 检查并安装 shellcheck
    install_shellcheck

    # 运行 shellcheck
    run_shellcheck

    # 检查是否提供了容器 ID
    if [ -z "$1" ]; then
        log_error "Usage: $0 <container_id>"
        exit 1
    fi

    local container_id=$1
    local pid
    pid=$(get_container_pid "$container_id")

    # 检查是否成功获取 PID
    if [ -z "$pid" ]; then
        log_error "Could not find PID for container $container_id"
        exit 1
    fi

    # 使用 nsenter 进入网络命名空间并运行 netstat
    log_info "pid: $pid"
    nsenter -t "$pid" -n netstat -tunlp
}

# 调用主函数并传递所有参数
main "$@"
