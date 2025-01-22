### VPS一键测试脚本


## 包含以下功能：

请选择要执行的操作：
1. VPS一键测试
2. BBR安装
3. 安装v2ray
4. 安装无人直播云SRS
5. 安装宝塔纯净版
6. 系统更新
7. 重启服务器
8. 一键永久禁用IPv6
9. 一键解除禁用IPv6
10. 服务器时区修改为中国时区
11. 保持SSH会话一直连接不断开
12. 安装 Windows或Linux系统

快捷命令：s

方式一：直接运行脚本（不保存文件）
```
bash <(curl -sL https://raw.githubusercontent.com/sinian-liu/VPStest/main/system_info.sh)
```
方式二：下载后运行（保存到本地）
```
wget -O /root/onekey.sh https://github.com/sinian-liu/onekey/raw/main/onekey.sh && chmod +x /root/onekey.sh && /root/onekey.sh
```
