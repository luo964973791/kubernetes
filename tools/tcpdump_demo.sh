#!/bin/bash
# @Time    : 2025/7/18 09:35
# @Author  : Leo Luo
# @File    : tcpdump_demo.sh
# @Software: cursor

print_green() {
    echo -e "\e[01;32m$(date "+%Y-%m-%d %H:%M:%S") [INFO] $*\e[01;00m"
}

print_red() {
    echo -e "\e[01;31m$(date "+%Y-%m-%d %H:%M:%S") [ERROR] $*\e[01;00m"
    exit 1
}

print_yellow() {
    echo -e "\e[01;33m$(date "+%Y-%m-%d %H:%M:%S") [Warning] $*\e[01;00m"
}

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    print_red "此脚本需要root权限运行，请使用 sudo $0"
fi

# 用法: ./tcp_udp_check.sh 80tcp 或 ./tcp_udp_check.sh 53udp
if [ $# -ne 1 ]; then
  print_red "Usage: $0 <port><tcp|udp> (e.g. 80tcp or 53udp)"
fi

port_proto=$1
port=$(echo "$port_proto" | grep -oE '^[0-9]+')
proto=$(echo "$port_proto" | grep -oE '(tcp|udp)$')
TIMEOUT=60

# 创建临时文件存储tcpdump输出
TMPFILE=$(mktemp)

if [[ "$proto" == "tcp" ]]; then
  print_green "[INFO] 检测TCP端口 $port 的三次握手..."
  
  # 在后台启动tcpdump
  print_green "[INFO] 启动tcpdump监听..."
  timeout "$TIMEOUT" tcpdump -i any port "$port" -s0 -A > "$TMPFILE" 2>/dev/null &
  TCPDUMP_PID=$!
  
  # 等待一秒让tcpdump启动
  sleep 1
  
  # 触发流量（尝试HTTP请求或TCP连接）
  print_green "[INFO] 触发HTTP请求到端口 $port..."
  curl -s --connect-timeout 3 "http://127.0.0.1:$port" >/dev/null 2>&1 &
  
  # 同时尝试TCP连接作为备用
  print_green "[INFO] 同时触发TCP连接到端口 $port..."
  timeout 3 bash -c "echo 'test' | nc -w 2 127.0.0.1 \"$port\"" >/dev/null 2>&1 &
  
  # 等待tcpdump完成
  wait "$TCPDUMP_PID"
  
  # 读取tcpdump输出
  tcpdump_output=$(cat "$TMPFILE")
  
  # 抓取SYN包
  syn_count=$(echo "$tcpdump_output" | grep -c 'Flags \[S\],')
  if [ "$syn_count" -eq 0 ]; then
    print_yellow "[DEBUG] tcpdump上下文（SYN相关）："
    grep -n 'Flags \[S\],' "$TMPFILE" | cut -d: -f1 | while read -r line; do
      [ -z "$line" ] && continue
      start=$((line-2)); [ $start -lt 1 ] && start=1
      end=$((line+2))
      sed -n "${start},${end}p" "$TMPFILE"
      echo "----------------------------------------------------------------------"
    done
    print_red "[ERROR] 未检测到SYN包，说明没有连接请求。"
  fi
  # 检查SYN-ACK
  synack_count=$(echo "$tcpdump_output" | grep -c 'Flags \[S\.\],')
  if [ "$synack_count" -eq 0 ]; then
    print_yellow "[DEBUG] tcpdump上下文（SYN-ACK相关）："
    grep -n 'Flags \[S\.\],' "$TMPFILE" | cut -d: -f1 | while read -r line; do
      [ -z "$line" ] && continue
      start=$((line-2)); [ $start -lt 1 ] && start=1
      end=$((line+2))
      sed -n "${start},${end}p" "$TMPFILE"
      echo "---"
    done
    print_red "[ERROR] 三次握手失败：没有收到SYN-ACK。"
  fi
  # 检查ACK
  ack_count=$(echo "$tcpdump_output" | grep -c 'Flags \[\.\],')
  if [ "$ack_count" -eq 0 ]; then
    print_yellow "[DEBUG] tcpdump上下文（ACK相关）："
    grep -n 'Flags \[\.\],' "$TMPFILE" | cut -d: -f1 | while read -r line; do
      [ -z "$line" ] && continue
      start=$((line-2)); [ $start -lt 1 ] && start=1
      end=$((line+2))
      sed -n "${start},${end}p" "$TMPFILE"
      echo "----------------------------------------------------------------------"
    done
    print_red "[ERROR] 三次握手失败：没有收到ACK。"
  fi
  # 检查RST
  rst_count=$(echo "$tcpdump_output" | grep -c 'Flags \[R\],')
  if [ "$rst_count" -gt 0 ]; then
    print_yellow "[DEBUG] tcpdump上下文（RST相关）："
    grep -n 'Flags \[R\],' "$TMPFILE" | cut -d: -f1 | while read -r line; do
      [ -z "$line" ] && continue
      start=$((line-2)); [ $start -lt 1 ] && start=1
      end=$((line+2))
      sed -n "${start},${end}p" "$TMPFILE"
      echo "----------------------------------------------------------------------"
    done
    print_red "[ERROR] 检测到RST（连接被重置），请检查服务端或防火墙。"
  fi
  print_green "[OK] TCP三次握手正常，无RST。"

elif [[ "$proto" == "udp" ]]; then
  print_green "[INFO] 检测UDP端口 $port 的流量和ICMP错误..."
  
  # 在后台启动tcpdump监听UDP
  timeout "$TIMEOUT" tcpdump -i any port "$port" -s0 -A > "$TMPFILE" 2>/dev/null &
  TCPDUMP_PID=$!
  
  # 等待一秒让tcpdump启动
  sleep 1
  
  # 触发UDP流量
  print_green "[INFO] 触发UDP请求到端口 $port..."
  echo "test" | nc -u -w 2 127.0.0.1 "$port" >/dev/null 2>&1 &
  
  # 等待tcpdump完成
  wait "$TCPDUMP_PID"
  
  # 检查UDP流量
  udp_count=$(wc -l < "$TMPFILE")
  if [ "$udp_count" -eq 0 ]; then
    print_red "[ERROR] 未检测到UDP流量，说明没有请求。"
  fi
  
  # 检查ICMP端口不可达
  icmp_unreach_count=$(timeout "$TIMEOUT" tcpdump -nn -i any icmp 2>/dev/null | grep 'icmp port unreachable' | grep -c ":$port$")
  if [ "$icmp_unreach_count" -gt 0 ]; then
    print_red "[ERROR] 检测到ICMP端口不可达错误，目标端口未监听或被防火墙拦截。"
  fi
  print_green "[OK] UDP端口 $port 流量正常，无ICMP端口不可达错误。"
else
  print_red "[ERROR] 协议必须为tcp或udp"
fi

# 显示抓包文件路径
print_green "[INFO] 抓包的路径保存文件为: $TMPFILE" 
