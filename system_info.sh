#!/bin/bash

# 主机名和系统信息
hostname=$(hostname)
domain=$(hostname -d)
os_version=$(lsb_release -d | awk -F"\t" '{print $2}')
kernel_version=$(uname -r)

# CPU信息
cpu_arch=$(uname -m)
cpu_model=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo | xargs)
cpu_cores=$(grep -c ^processor /proc/cpuinfo)
cpu_frequency=$(awk -F': ' '/cpu MHz/ {print $2; exit}' /proc/cpuinfo | awk '{printf "%.4f GHz", $1 / 1000}')
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.1f%%", $2 + $4}')

# 系统负载
load_avg=$(uptime | awk -F'load average: ' '{print $2}')

# 内存信息
memory_usage=$(free -m | awk '/Mem:/ {printf "%.2f/%.2f MB (%.2f%%)", $3, $2, $3/$2 * 100}')
swap_usage=$(free -m | awk '/Swap:/ {if ($2 > 0) printf "%.2f/%.2f MB (%.2f%%)", $3, $2, $3/$2 * 100; else print "N/A"}')

# 硬盘使用
disk_usage=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')

# 网络流量
total_rx=$(cat /proc/net/dev | grep eth0 | awk '{printf "%.2f MB", $2 / 1024 / 1024}')
total_tx=$(cat /proc/net/dev | grep eth0 | awk '{printf "%.2f MB", $10 / 1024 / 1024}')

# TCP算法
tcp_algo=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')

# 网络信息
ip_info=$(curl -s ipinfo.io)
ipv4=$(echo "$ip_info" | jq -r '.ip')
isp=$(echo "$ip_info" | jq -r '.org')
location=$(echo "$ip_info" | jq -r '.city + ", " + .country')

# DNS地址
dns_address=$(awk '/^nameserver/ {print $2}' /etc/resolv.conf | tr '\n' ' ' | xargs)

# 系统时间
timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
sys_time=$(date "+%Y-%m-%d %H:%M %p")

# 获取系统运行时间并格式化
uptime_seconds=$(cat /proc/uptime | awk '{print int($1)}')
uptime_hours=$((uptime_seconds / 3600))
uptime_minutes=$(( (uptime_seconds % 3600) / 60 ))
uptime_formatted="${uptime_hours}时 ${uptime_minutes}分"

# 输出优化的格式化信息
echo "主机名:       $hostname.$domain"
echo "系统版本:     $os_version"
echo "Linux版本:    $kernel_version"
echo "-------------"
echo "CPU架构:      $cpu_arch"
echo "CPU型号:      $cpu_model"
echo "CPU核心数:    $cpu_cores"
echo "CPU频率:      $cpu_frequency"
echo "-------------"
echo "CPU占用:      $cpu_usage"
echo "系统负载:     $load_avg"
echo "物理内存:     $memory_usage"
echo "虚拟内存:     $swap_usage"
echo "硬盘占用:     $disk_usage"
echo "-------------"
echo "总接收:       $total_rx"
echo "总发送:       $total_tx"
echo "-------------"
echo "网络算法:     $tcp_algo"
echo "-------------"
echo "运营商:       $isp"
echo "IPv4地址:     $ipv4"
echo "DNS地址:      $dns_address"
echo "地理位置:     $location"
echo "系统时间:     $timezone $sys_time"
echo "-------------"
echo "运行时长:     $uptime_formatted"
