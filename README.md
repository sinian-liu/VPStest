```
bash <(curl -sL https://raw.githubusercontent.com/sinian-liu/VPStest/main/system_info.sh)
```
### VPS一键测试脚本


## 包含以下功能：
- 1.更新系统,检查并安装jq、curl、dd、fio、tar、iperf3、系统地区时间修改为中国上海
- 2.一键开启BBR（适用于较新的Debian、Ubuntu）如遇其他系统则自动跳过安装
- 3.检查主机名和系统信息
- 4.硬盘I/O性能进行三次测试
- 5.IPinfo检测IP类型
- 6.IP质量检测
- 7.三网回程线路测试
- 8.三网+教育网IPv4单线程测速
- 9.流媒体平台及游戏区域限制测试
- 10.全国五网ISP路由回程测试
- 11.Bench 性能测试
