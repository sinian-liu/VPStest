#!/bin/bash

# 定义README文件路径
README_FILE="/etc/v2ray-agent/README.txt"
SN_CMD="/usr/local/bin/sn"

# 步骤 1: 检查并安装必要的依赖（如果缺少 jq 和 curl）
echo "检测并安装依赖..."
if ! command -v jq &>/dev/null; then
    echo "未安装 jq，正在安装..."
    apt-get update && apt-get install -y jq
else
    echo "jq 已安装"
fi

if ! command -v curl &>/dev/null; then
    echo "未安装 curl，正在安装..."
    apt-get install -y curl
else
    echo "curl 已安装"
fi

# 步骤 2: 修改文件路径（根据需求修改）
echo "步骤 2: 修改文件路径..."
# 例如，如果你需要修改 README 文件路径，可以在这里进行操作
# 如果没有额外修改步骤，可以跳过

# 步骤 3: 确保文件权限
echo "步骤 3: 确保文件权限..."
# 设置文件的读写权限（如果需要）
chmod 644 "$README_FILE"
echo "文件权限已更新：$README_FILE"

# 步骤 4: 创建符号链接
echo "步骤 4: 创建符号链接..."
if [ ! -f "$SN_CMD" ]; then
    ln -s /etc/v2ray-agent/install.sh "$SN_CMD"
    echo "符号链接已创建：$SN_CMD"
else
    echo "符号链接已存在：$SN_CMD"
fi

# 步骤 5: 更新环境变量
echo "步骤 5: 更新环境变量..."
# 将 /usr/local/bin 添加到系统的 PATH 中，确保 sn 命令可用
if ! grep -q "/usr/local/bin" /etc/profile; then
    echo 'export PATH=$PATH:/usr/local/bin' >> /etc/profile
    echo "已将 /usr/local/bin 添加到 PATH"
    source /etc/profile
else
    echo "/usr/local/bin 已在 PATH 中"
fi

# 步骤 6: 验证
echo "步骤 6: 验证..."
if [ -f "$SN_CMD" ]; then
    echo "验证成功：可以通过 sn 命令运行脚本"
else
    echo "验证失败：未能找到 sn 命令"
fi

# 提示用户首次安装后，下次输入 sn 即可运行脚本
echo -e "\033[1;33m首次安装后，下次直接输入 \033[1;31msn\033[0m \033[1;33m即可打开脚本。\033[0m"


#!/bin/bash

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
}

# 执行更新和工具安装
update_system
install_required_tools

# 继续执行您的其他脚本逻辑...

#!/bin/bash

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

#!/bin/bash

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

# 模拟硬盘 I/O 性能测试函数 (需要根据你的系统实际情况替换为真实的 I/O 测试命令)
io_test() {
    # 模拟硬盘测试命令 (这里使用 dd 作为示例)
    result=$(dd if=/dev/zero of=tempfile bs=1M count=$1 oflag=direct 2>&1 | grep -oP '[0-9.]+ (MB|GB)/s')
    rm -f tempfile  # 删除临时文件
    echo "$result"
}

# 打印硬盘性能测试结果
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
        ioraw1=$(echo "$io1" | awk 'NR==1 {print $1}')
        [[ "$(echo "$io1" | awk 'NR==1 {print $2}')" == "GB/s" ]] && ioraw1=$(awk 'BEGIN{print '"$ioraw1"' * 1024}')
        
        ioraw2=$(echo "$io2" | awk 'NR==1 {print $1}')
        [[ "$(echo "$io2" | awk 'NR==1 {print $2}')" == "GB/s" ]] && ioraw2=$(awk 'BEGIN{print '"$ioraw2"' * 1024}')
        
        ioraw3=$(echo "$io3" | awk 'NR==1 {print $1}')
        [[ "$(echo "$io3" | awk 'NR==1 {print $2}')" == "GB/s" ]] && ioraw3=$(awk 'BEGIN{print '"$ioraw3"' * 1024}')

        # 计算总和和平均值
        ioall=$(awk 'BEGIN{print '"$ioraw1"' + '"$ioraw2"' + '"$ioraw3"'}')
        ioavg=$(awk 'BEGIN{printf "%.2f", '"$ioall"' / 3}')
        
        # 格式化输出结果
        echo -e "\n硬盘性能测试结果如下："
        printf "%-25s %s\n" "硬盘I/O (第一次测试) :" "$(_yellow "$io1")"
        printf "%-25s %s\n" "硬盘I/O (第二次测试) :" "$(_yellow "$io2")"
        printf "%-25s %s\n" "硬盘I/O (第三次测试) :" "$(_yellow "$io3")"
        echo -e "硬盘I/O (平均测试) : $(_yellow "$ioavg MB/s")"
    else
        echo -e " $(_red "Not enough space for I/O Speed test!")"
    fi
}

# 调用函数进行测试
print_io_test

#!/bin/bash

# 设置颜色
_yellow() {
    echo -e "\033[1;33m$1\033[0m"
}

# 通过 API 获取 IP 信息，使用提供的 API 密钥
API_TOKEN="5ebf2ff2b04160"
ip_info=$(curl -s "ipinfo.io?token=${API_TOKEN}")

# 获取各项信息，检查是否存在字段
ip_address=$(echo "$ip_info" | jq -r '.ip // "N/A"')
city=$(echo "$ip_info" | jq -r '.city // "N/A"')
region=$(echo "$ip_info" | jq -r '.region // "N/A"')
country=$(echo "$ip_info" | jq -r '.country // "N/A"')
loc=$(echo "$ip_info" | jq -r '.loc // "N/A"')
org=$(echo "$ip_info" | jq -r '.org // "N/A"')

# 获取 ASN 信息
asn=$(echo "$ip_info" | jq -r '.asn.asn // "N/A"')
asn_name=$(echo "$ip_info" | jq -r '.asn.name // "N/A"')
asn_domain=$(echo "$ip_info" | jq -r '.asn.domain // "N/A"')
asn_route=$(echo "$ip_info" | jq -r '.asn.route // "N/A"')
asn_type=$(echo "$ip_info" | jq -r '.asn.type // "N/A"')

# 获取公司信息
company_name=$(echo "$ip_info" | jq -r '.company.name // "N/A"')
company_domain=$(echo "$ip_info" | jq -r '.company.domain // "N/A"')
company_type=$(echo "$ip_info" | jq -r '.company.type // "N/A"')

# 输出查询结果
echo -e "\n\n\n$(_yellow "IP info信息查询结果如下：")"
echo "-------------------"
echo "IP 地址:         $ip_address"
echo "城市:            $city"
echo "地区:            $region"
echo "国家:            $country"
echo "地理位置:        $loc"
echo "组织:            $org"
echo "-------------------"
echo "ASN 信息："
echo "ASN编号:         $asn"
echo "ASN名称:         $asn_name"
echo "ASN域名:         $asn_domain"
echo "ASN路由:         $asn_route"
echo "ASN类型:         $asn_type"
echo "-------------------"
echo "公司信息："
echo "公司名称:        $company_name"
echo "公司域名:        $company_domain"
echo "公司类型:        $company_type"

#!/bin/bash

# IP质量检测
# 获取并自动输入 'y' 安装脚本
bash <(curl -Ls IP.Check.Place) <<< "y"

# 执行第一个三网回程线路脚本
curl https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh -sSf | sh

# 执行第二个三网回程线路脚本
curl https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash

# 安装并运行三网+教育网 IPv4 单线程测速脚本，并自动输入 '2'
bash <(curl -sL https://raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh) <<< "2"

# 检查 curl 是否已安装，若未安装则自动安装
if ! command -v curl &>/dev/null; then
    echo "curl 未安装，正在安装..."
    apt update && apt install -y curl
else
    echo "curl 已安装，跳过安装。"
fi

# 执行流媒体平台及游戏区域限制测试脚本并自动输入 '66'
bash <(curl -L -s check.unlock.media) <<< "66"
# 全国五网ISP路由回程测试
curl -s https://nxtrace.org/nt | bash && sleep 2 && echo -e "1\n6" | nexttrace --fast-trace
# 执行 Bench 性能测试并自动回车运行
curl -Lso- bench.sh | bash


