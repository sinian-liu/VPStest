#!/bin/bash

# ANSI颜色代码：黄色
YELLOW='\033[1;33m'
NC='\033[0m' # 颜色重置

# 系统信息函数
get_system_info() {
    HOSTNAME=$(hostname)
    OS_VERSION=$(lsb_release -d | awk -F'\t' '{print $2}')
    KERNEL_VERSION=$(uname -r)
    CPU_ARCH=$(uname -m)
    CPU_MODEL=$(awk -F ': ' '/model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^[ \t]*//')
    CPU_CORES=$(nproc)
    CPU_FREQ=$(awk -F '[: ]+' '/cpu MHz/ {print $4; exit}' /proc/cpuinfo | awk '{printf "%.2f GHz", $1/1000}')
    MEM_USAGE=$(free -m | awk '/Mem/ {printf "%.2f/%.2f MB (%.2f%%)", $3, $2, $3/$2 * 100}')
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')
}

# 硬盘性能测试函数
perform_test() {
    # 临时文件路径
    test_file="/tmp/testfile"
    
    # 使用 dd 命令进行写入测试，写入 1GB 数据
    result=$(dd if=/dev/zero of=$test_file bs=1M count=1024 oflag=direct 2>&1 | tail -n 1)

    # 提取写入速度（MB/s 或 GB/s）并返回
    echo "$result" | grep -oP '\d+\.\d+ [GM]B/s'
    
    # 删除测试文件
    rm -f $test_file
}

# 显示系统信息
display_system_info() {
    echo -e "\n${YELLOW}系统信息${NC}"
    echo "主机名:      $HOSTNAME"
    echo "系统版本:    $OS_VERSION"
    echo "Linux版本:   $KERNEL_VERSION"
    echo "CPU架构:     $CPU_ARCH"
    echo "CPU型号:     $CPU_MODEL"
    echo "CPU核心数:   $CPU_CORES"
    echo "CPU频率:     $CPU_FREQ"
    echo "物理内存:    $MEM_USAGE"
    echo "硬盘占用:    $DISK_USAGE"
}

# 硬盘性能测试
run_disk_tests() {
    echo -e "\n\n\n${YELLOW}硬盘 I/O 性能测试${NC}\n"
    echo "硬盘性能测试正在进行中..."
    
    # 运行三次测试
    first_test=$(perform_test)
    second_test=$(perform_test)
    third_test=$(perform_test)

    # 输出格式化的硬盘性能测试结果
    echo -e "\n硬盘性能测试结果如下："
    printf "%-25s %s\n" "硬盘I/O (第一次测试) :" "$first_test"
    printf "%-25s %s\n" "硬盘I/O (第二次测试) :" "$second_test"
    printf "%-25s %s\n" "硬盘I/O (第三次测试) :" "$third_test"
}

# 执行所有步骤
get_system_info
display_system_info
run_disk_tests
