# Java Application Bootstrap Script

一个 **生产级 Java 应用守护启动脚本**，适用于 **Spring Boot / 普通 Java Jar** 项目，支持：

- 应用启动 / 停止 / 重启 / 状态查看
- **异常退出自动拉起（watchdog）**
- **日志自动切割（防止 nohup.out 无限增大）**
- 严格 Shell 模式（`set -euo pipefail`）
- 适配 **CentOS / Ubuntu / ARM / x86**

---

## 📌 适用场景

- 单机部署 Java 后台服务
- 无 systemd / 不想写 service 文件
- 需要 **进程守护 + 自动重启**
- Kafka / 摄像头数据 / 后台消费程序
- 边缘节点 / 私有化部署

---

## 📂 目录结构

```text
app/
├── bootstrap.sh
├── your-app-1.0.0.jar
├── app.log
├── app.log.1
├── app.pid
├── watchdog.pid
└── .stopped
