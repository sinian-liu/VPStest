#!/bin/bash

# ANSI颜色代码：黄色
YELLOW='\033[1;33m'
NC='\033[0m' # 颜色重置

# 显示标题信息并空三行
echo -e "\n\n\n${YELLOW}硬盘 I/O 性能测试${NC}\n"

# 临时文件路径
test_file="/tmp/testfile"

# 硬盘性能测试函数
perform_test() {
    # 使用 dd 命令进行写入测试，写入 1GB 数据
    result=$(dd if=/dev/zero of=$test_file bs=1M count=1024 oflag=direct 2>&1 | tail -n 1)

    # 提取写入速度（MB/s 或 GB/s）并返回
    echo "$result" | grep -oP '\d+\.\d+ [GM]B/s'
}

# 清理临时文件
cleanup() {
    rm -f $test_file
}

# 开始性能测试
echo "硬盘性能测试正在进行中..."

# 运行三次测试
first_test=$(perform_test)
second_test=$(perform_test)
third_test=$(perform_test)

# 清理
cleanup

# 输出格式化结果
echo -e "\n硬盘性能测试结果如下："
printf "%-25s %s\n" "硬盘I/O (第一次测试) :" "$first_test"
printf "%-25s %s\n" "硬盘I/O (第二次测试) :" "$second_test"
printf "%-25s %s\n" "硬盘I/O (第三次测试) :" "$third_test"
