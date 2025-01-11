#!/bin/bash

# 每 120 秒发送一个心跳信号（2 分钟）
while true; do
    # 删除或注释掉 echo 语句，避免显示 "保活中..."
    sleep 120
done &

# 记录开始时间
start_time=$(date +%s)

# 增加sn为快捷启动命令，检查并创建 alias（如果没有的话）
if ! grep -q "alias sn=" ~/.bashrc; then
    echo "正在为 sn 设置快捷命令..."
    echo "alias sn='bash <(curl -sL https://raw.githubusercontent.com/sinian-liu/VPStest/main/system_info.sh)'" >> ~/.bashrc
    source ~/.bashrc
    echo "快捷命令 sn 已设置。"
else
    echo "快捷命令 sn 已经存在。"
fi

# 设置新的主机名
NEW_HOSTNAME="www.1373737.xyz"

# 修改主机名
sudo hostnamectl set-hostname "$NEW_HOSTNAME"

# 更新 /etc/hosts 文件
sudo sed -i "s/127.0.1.1.*/127.0.1.1   $NEW_HOSTNAME/" /etc/hosts

# 验证修改
echo "主机名已成功修改为："
hostnamectl

# 更新系统
update_system() {
    echo "正在检查并更新系统..."
    # 检查系统是否为 Debian/Ubuntu 或 CentOS
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu 系统
        sudo apt update && sudo apt upgrade -y
    elif [[ -f /etc/redhat-release ]]; then
        # CentOS 系统
        sudo yum update -y
    else
        echo "未知的系统类型，跳过更新。"
    fi
}

# 检测并安装必要的工具
install_required_tools() {
    echo "检查并安装缺少的工具..."

    # 检查并安装 jq
    if ! command -v jq &>/dev/null; then
        echo "jq 未安装，正在安装..."
        if [[ -f /etc/debian_version ]]; then
            sudo apt install -y jq
        elif [[ -f /etc/redhat-release ]]; then
            sudo yum install -y jq
        fi
    else
        echo "jq 已安装。"
    fi

    # 检查并安装 curl
    if ! command -v curl &>/dev/null; then
        echo "curl 未安装，正在安装..."
        if [[ -f /etc/debian_version ]]; then
            sudo apt install -y curl
        elif [[ -f /etc/redhat-release ]]; then
            sudo yum install -y curl
        fi
    else
        echo "curl 已安装。"
    fi

    # 检查并安装 dd (通常 dd 工具是默认安装的)
    if ! command -v dd &>/dev/null; then
        echo "dd 未安装，正在安装..."
        if [[ -f /etc/debian_version ]]; then
            sudo apt install -y coreutils
        elif [[ -f /etc/redhat-release ]]; then
            sudo yum install -y coreutils
        fi
    else
        echo "dd 已安装。"
    fi

    # 检查并安装 fio
    if ! command -v fio &>/dev/null; then
        echo "fio 未安装，正在安装..."
        if [[ -f /etc/debian_version ]]; then
            sudo apt install -y fio
        elif [[ -f /etc/redhat-release ]]; then
            sudo yum install -y fio
        fi
    else
        echo "fio 已安装。"
    fi

    # 检查并安装 tar
    if ! command -v tar &>/dev/null; then
        echo "tar 未安装，正在安装..."
        if [[ -f /etc/debian_version ]]; then
            sudo apt install -y tar
        elif [[ -f /etc/redhat-release ]]; then
            sudo yum install -y tar
        fi
    else
        echo "tar 已安装。"
    fi

    # 检查并安装 iperf3
    if ! command -v iperf3 &>/dev/null; then
        echo "iperf3 未安装，正在安装..."
        if [[ -f /etc/debian_version ]]; then
            # 设置非交互模式，避免询问是否让 iperf3 启动为守护进程
            sudo DEBIAN_FRONTEND=noninteractive apt install -y iperf3
        elif [[ -f /etc/redhat-release ]]; then
            sudo yum install -y iperf3
        fi
    else
        echo "iperf3 已安装。"
    fi
    
    # 检查并安装 mtr
    if ! command -v mtr &>/dev/null; then
        echo "mtr 未安装，正在安装..."
        if [[ -f /etc/debian_version ]]; then
            sudo apt install -y mtr
        elif [[ -f /etc/redhat-release ]]; then
            sudo yum install -y mtr
        fi
    else
        echo "mtr 已安装。"
    fi
}

# 设置系统时区为中国上海
set_timezone_to_shanghai() {
    echo "正在将系统时区设置为中国上海..."
    # 使用 timedatectl 设置时区
    sudo timedatectl set-timezone Asia/Shanghai

    # 验证时区设置
    echo "当前系统时区为：$(timedatectl | grep 'Time zone')"
}

# 检测是否为Debian或Ubuntu系统
is_debian_or_ubuntu() {
    if [[ -f /etc/debian_version ]]; then
        echo "检测到Debian或Ubuntu系统，继续开启BBR..."
        return 0
    else
        echo "此系统不是Debian或Ubuntu，跳过BBR设置。"
        return 1
    fi
}

# 一键开启BBR（适用于较新的Debian、Ubuntu）
enable_bbr() {
    if is_debian_or_ubuntu; then
        echo "正在开启BBR..."
        # 设置默认的队列调度器为 fq
        echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
        # 设置TCP拥塞控制算法为 bbr
        echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
        # 应用配置
        sudo sysctl -p

        # 检查BBR是否已启用
        sysctl net.ipv4.tcp_available_congestion_control
        lsmod | grep bbr
    fi
}

# 配置 iperf3 为自动启动服务
enable_iperf3_autostart() {
    echo "正在配置 iperf3 为自动启动守护进程..."

    # 创建 systemd 服务文件
    sudo bash -c 'cat > /etc/systemd/system/iperf3.service <<EOF
[Unit]
Description=iperf3 Daemon
After=network.target

[Service]
ExecStart=/usr/bin/iperf3 -s
Restart=on-failure
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF'

    # 重新加载 systemd 配置
    sudo systemctl daemon-reload

    # 启动并设置 iperf3 服务为开机自启
    sudo systemctl start iperf3
    sudo systemctl enable iperf3

    echo "iperf3 服务已配置为自动启动。"
}

# 执行更新和工具安装
update_system
install_required_tools

# 设置系统时区
set_timezone_to_shanghai

# 启用BBR
enable_bbr

# 配置 iperf3 自动启动
enable_iperf3_autostart

# 继续执行您的其他脚本逻辑...



# 颜色定义
YELLOW='\033[1;33m'
NC='\033[0m' # 重置颜色

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

# 总接收和总发送流量
get_network_traffic() {
    local bytes=$1
    if [ -n "$bytes" ] && (( bytes > 1024*1024*1024 )); then
        echo "$(awk "BEGIN {printf \"%.2f GB\", $bytes/1024/1024/1024}")"
    elif [ -n "$bytes" ] && (( bytes > 1024*1024 )); then
        echo "$(awk "BEGIN {printf \"%.2f MB\", $bytes/1024/1024}")"
    elif [ -n "$bytes" ]; then
        echo "$(awk "BEGIN {printf \"%.2f KB\", $bytes/1024}")"
    else
        echo "0 KB"
    fi
}

# 网络接口
interface=$(ip route | grep '^default' | awk '{print $5}')
total_rx=$(get_network_traffic $(cat /proc/net/dev | grep -w "$interface" | awk '{print $2}'))
total_tx=$(get_network_traffic $(cat /proc/net/dev | grep -w "$interface" | awk '{print $10}'))

# 网络算法
tcp_algo=$(sysctl -n net.ipv4.tcp_congestion_control)

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
uptime_days=$((uptime_seconds / 86400))
uptime_hours=$(( (uptime_seconds % 86400) / 3600 ))
uptime_minutes=$(( (uptime_seconds % 3600) / 60 ))

if (( uptime_days > 0 )); then
    uptime_formatted="${uptime_days}天 ${uptime_hours}时 ${uptime_minutes}分"
else
    uptime_formatted="${uptime_hours}时 ${uptime_minutes}分"
fi

# 输出优化的格式化信息
echo -e "\n${YELLOW}系统信息查询${NC}"
echo "-------------"
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


# 颜色定义
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 重置颜色

# 格式化输出为黄色
_yellow() {
    echo -e "${YELLOW}$1${NC}"
}

# 格式化输出为红色
_red() {
    echo -e "${RED}$1${NC}"
}

# 定义颜色
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'  # 无颜色


# 模拟硬盘 I/O 性能测试函数 (需要根据你的系统实际情况替换为真实的 I/O 测试命令)
io_test() {
    result=$(dd if=/dev/zero of=tempfile bs=1M count=$1 oflag=direct 2>&1 | grep -oP '[0-9.]+ (MB|GB)/s')
    rm -f tempfile  # 删除临时文件
    echo "$result"
}

print_io_test() {
    freespace=$(df -m . | awk 'NR==2 {print $4}')
    if [ -z "${freespace}" ]; then
        freespace=$(df -m . | awk 'NR==3 {print $3}')
    fi

    if [ "${freespace}" -gt 1024 ]; then
        writemb=2048  # 设置写入的 MB 大小
        echo -e "\n\n\n${YELLOW}硬盘 I/O 性能测试${NC}\n"
        echo "硬盘性能测试正在进行中..."
        
        # 执行三次测试
        io1=$(io_test ${writemb})
        io2=$(io_test ${writemb})
        io3=$(io_test ${writemb})
        
        # 提取测试结果并转换单位为 MB/s
        ioraw1=$(echo "$io1" | awk '{print $1}')
        [[ "$(echo "$io1" | awk '{print $2}')" == "GB/s" ]] && ioraw1=$(awk 'BEGIN{print '"$ioraw1"' * 1024}')
        
        ioraw2=$(echo "$io2" | awk '{print $1}')
        [[ "$(echo "$io2" | awk '{print $2}')" == "GB/s" ]] && ioraw2=$(awk 'BEGIN{print '"$ioraw2"' * 1024}')
        
        ioraw3=$(echo "$io3" | awk '{print $1}')
        [[ "$(echo "$io3" | awk '{print $2}')" == "GB/s" ]] && ioraw3=$(awk 'BEGIN{print '"$ioraw3"' * 1024}')

        # 计算总和和平均值
        ioall=$(awk 'BEGIN{print '"$ioraw1"' + '"$ioraw2"' + '"$ioraw3"'}')
        ioavg=$(awk 'BEGIN{printf "%.2f", '"$ioall"' / 3}')
        
        # 格式化输出结果
        echo -e "\n硬盘性能测试结果如下："
        printf "%-25s %s\n" "硬盘I/O (第一次测试) :" "$(_yellow "$io1")"
        printf "%-25s %s\n" "硬盘I/O (第二次测试) :" "$(_yellow "$io2")"
        printf "%-25s %s\n" "硬盘I/O (第三次测试) :" "$(_yellow "$io3")"
        echo -e "硬盘I/O (平均测试) : $(_yellow "$ioavg MB/s")"
        
        # 硬盘类型检测
        disk_type=$(lsblk -d -o name,rota | awk 'NR==2 {print $2}')
        disk_device=$(lsblk -d -o name,rota | awk 'NR==2 {print $1}')
        
        # 判断是否为 NVMe
        if [[ "$disk_device" == nvme* ]]; then
            disk_type="NVMe SSD"
        elif [[ "$disk_type" == "0" ]]; then
            disk_type="SSD"
        elif [[ "$disk_type" == "1" ]]; then
            disk_type="HDD"
        else
            disk_type="未知"
        fi
        
        # 硬盘性能等级判定
        if (( $(echo "$ioavg > 500" | bc -l) )); then
            performance_level="优秀"
        elif (( $(echo "$ioavg > 200" | bc -l) )); then
            performance_level="好"
        elif (( $(echo "$ioavg > 100" | bc -l) )); then
            performance_level="一般"
        else
            performance_level="差"
        fi

        echo "硬盘类型: $disk_type"
        echo "硬盘性能等级: $performance_level"

        # 输出绿色的提示信息
        echo -e "${GREEN}测试数据不是百分百准确，以官方宣称为主。${NC}"

    else
        echo -e " $(_red "空间不足，无法测试硬盘性能！")"
    fi
}

print_io_test


#!/bin/bash

# 设置颜色
_yellow() {
    echo -e "\033[1;33m$1\033[0m"
}

# IPinfo信息查询
# 通过 API 获取 IP 信息，使用提供的 API 密钥
# API Token
API_TOKEN="5ebf2ff2b04160"

# 获取 IP 信息
ip_info=$(curl -s "ipinfo.io?token=${API_TOKEN}")

# 获取各项信息，检查是否存在字段
ip_address=$(echo "$ip_info" | jq -r '.ip // "N/A"')
city=$(echo "$ip_info" | jq -r '.city // "N/A"')
region=$(echo "$ip_info" | jq -r '.region // "N/A"')
country=$(echo "$ip_info" | jq -r '.country // "N/A"')
loc=$(echo "$ip_info" | jq -r '.loc // "N/A"')
org=$(echo "$ip_info" | jq -r '.org // "N/A"')

# 获取 ASN 信息（免费版通过 org 字段提供 ASN 信息）
asn=$(echo "$ip_info" | jq -r '.org // "N/A"')

# 公司信息（免费版不支持）
company_name="N/A"
company_domain="N/A"
company_type="N/A"

# 输出查询结果
echo -e "\n\n\nIP info信息查询结果如下："
echo "-------------------"
echo "IP 地址:         $ip_address"
echo "城市:            $city"
echo "地区:            $region"
echo "国家:            $country"
echo "地理位置:        $loc"
echo "组织:            $org"
echo "-------------------"
echo "ASN编号:         $asn"
echo "-------------------"
echo "公司名称:        $company_name"
echo "公司域名:        $company_domain"
echo "公司类型:        $company_type"
echo -e "\n\n备注："
echo "1. ASN 编号、名称、路由和类型字段仅在付费版本中可用。"
echo "2. 公司信息（名称、域名、类型）仅在付费版本中可用。"

echo ""
echo ""

# IP欺诈风险监测脚本

# Scamalytics API key
API_KEY="89c1e8dc1272cb7b1e1f162cbdcc0cf4434a06c41b4ab7f8b7f9497c0cd56e9f"

# 检测依赖是否已安装并自动安装
check_dependencies() {
    echo "检测所需依赖工具：curl 和 jq..."

    # 获取系统类型
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo "无法检测系统类型，请手动安装 curl 和 jq 后重试。"
        exit 1
    fi

    # 安装 curl
    if ! command -v curl &> /dev/null; then
        echo "未检测到 curl，正在安装..."
        if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
            sudo apt update && sudo apt install -y curl
        elif [[ "$OS" == "centos" || "$OS" == "rocky" || "$OS" == "almalinux" ]]; then
            sudo yum install -y curl
        else
            echo "不支持的系统类型：$OS，请手动安装 curl 后重试。"
            exit 1
        fi
    else
        echo "curl 已安装，跳过。"
    fi

    # 安装 jq
    if ! command -v jq &> /dev/null; then
        echo "未检测到 jq，正在安装..."
        if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
            sudo apt update && sudo apt install -y jq
        elif [[ "$OS" == "centos" || "$OS" == "rocky" || "$OS" == "almalinux" ]]; then
            sudo yum install -y jq
        else
            echo "不支持的系统类型：$OS，请手动安装 jq 后重试。"
            exit 1
        fi
    else
        echo "jq 已安装，跳过。"
    fi
}

# 获取当前时间
get_current_time() {
    date +"%Y-%m-%d %H:%M:%S"
}

# 获取公网 IPv4 地址
get_public_ip() {
    IPV4=$(curl -s https://api.ipify.org)
    if [[ -n "$IPV4" ]]; then
        echo $IPV4
    else
        echo "无法获取公网IPv4地址"
        exit 1
    fi
}

# 使用 Scamalytics API 检测 IP 欺诈得分
get_fraud_details() {
    IP=$1
    RESPONSE=$(curl -s "https://api.scamalytics.com/v1/score/$IP?api_key=$API_KEY")
    SCORE=$(echo $RESPONSE | jq -r '.score // "null"')
    RISK=$(echo $RESPONSE | jq -r '.risk // "unknown"')
    if [[ "$SCORE" == "null" || -z "$SCORE" ]]; then
        echo "API响应不包含有效得分，无法继续检测。"
        exit 1
    fi
    echo "$SCORE $RISK"
}

# 显示得分及风险等级评估
display_fraud_score() {
    IP=$1
    SCORE=$2
    RISK=$3
    CURRENT_TIME=$(get_current_time)

    echo -e "\n检测时间: $CURRENT_TIME"
    echo -e "此 IP ($IP) 的欺诈得分为 $SCORE，风险等级评估：\c"

    # 风险级别分析
    if [[ "$RISK" == "low" ]]; then
        echo -e "\033[32m低风险\033[0m。"
    elif [[ "$RISK" == "medium" ]]; then
        echo -e "\033[33m中等风险\033[0m。"
    elif [[ "$RISK" == "high" ]]; then
        echo -e "\033[31m高风险！\033[0m"
    else
        echo -e "\033[34m未知风险\033[0m。"
    fi
}

# 主程序
main() {
    # 检查依赖
    check_dependencies

    # 获取公网 IP
    IP=$(get_public_ip)
    echo -e "正在检测当前VPS的公网 IPv4: $IP"

    # 获取 IP 欺诈详细信息
    DETAILS=$(get_fraud_details $IP)
    FRAUD_SCORE=$(echo $DETAILS | awk '{print $1}')
    RISK_LEVEL=$(echo $DETAILS | awk '{print $2}')

    # 显示得分和风险等级评估
    display_fraud_score $IP $FRAUD_SCORE $RISK_LEVEL
}

# 执行主程序

# IP质量检测
# 获取并自动输入 'y' 安装脚本
bash <(curl -Ls IP.Check.Place) <<< "y"



# 执行第一个三网回程线路脚本
curl https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh -sSf | sh

# 执行第二个三网回程线路脚本
curl https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash

# 安装并运行三网+教育网 IPv4 单线程测速脚本，并自动输入 '2'
bash <(curl -sL https://raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh) <<< "2"

# 执行流媒体平台及游戏区域限制测试脚本并自动输入 '66'
bash <(curl -L -s check.unlock.media) <<< "66"
# 全国五网ISP路由回程测试
curl -s https://nxtrace.org/nt | bash && sleep 2 && echo -e "1\n6" | nexttrace --fast-trace
# 执行 Bench 性能测试并自动回车运行
curl -Lso- bench.sh | bash

echo ""
echo ""

# 显示测试完成提示信息  
echo -e "\n\033[33m37VPS主机评测：\033[31mhttps://1373737.xyz\033[0m"  
echo -e "\033[33m服务器推荐：\033[31mhttps://my.frantech.ca/aff.php?aff=4337\033[0m"  
echo -e "\033[33mYouTube频道：\033[31mhttps://www.youtube.com/@cyndiboy7881\033[0m"  
echo -e "\033[33mv2ray-agent脚本：\033[31mhttps://github.com/sinian-liu/v2ray-agent\033[0m"  

# 计算并显示总耗时
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

# 换算成分钟和秒
minutes=$((elapsed_time / 60))
seconds=$((elapsed_time % 60))

# 显示分钟和秒
if [ $minutes -gt 0 ]; then
    echo -e "\033[33m所有测试已经完成，测试总耗时：\033[31m${minutes} 分钟 ${seconds} 秒\033[33m，感谢使用本脚本。\033[0m"
else
    echo -e "\033[33m所有测试已经完成，测试总耗时：\033[31m${seconds} 秒\033[33m，感谢使用本脚本。\033[0m"
fi

# 新增行：下次直接输入快捷命令即可再次启动
echo -e "\033[33m下次直接输入快捷命令即可再次启动：\033[31msn\033[0m"
