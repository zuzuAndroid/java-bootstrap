# Java 应用守护启动脚本

一个功能完善的 Java 应用守护启动脚本，提供自动重启、日志轮转、进程监控等功能，适用于生产环境部署。

## 🚀 功能特性

- ✅ **自动启动** - 自动查找并启动目录下的最新 JAR 文件
- ✅ **进程守护** - Watchdog 监控，应用异常退出时自动重启
- ✅ **日志轮转** - 当日志文件超过 100MB 时自动切割备份
- ✅ **优雅停止** - 支持平滑停止应用，避免数据丢失
- ✅ **状态监控** - 实时查看应用运行状态
- ✅ **性能优化** - 预设 G1GC、字符串去重等 JVM 优化参数
- ✅ **环境检测** - 自动检测操作系统和 Java 版本信息

## 📋 系统要求

- **操作系统**: Linux (CentOS/RHEL/Ubuntu/Debian 等)
- **Java版本**: Java 8+ 
- **Shell**: Bash (支持 set -euo pipefail)
- **权限**: 需要有文件读写和进程管理权限


## 📊 启动日志示例

```text
[2026-01-10 10:12:01] OS: CentOS Linux 7
[2026-01-10 10:12:01] Java: java version "1.8.0_382"
[2026-01-10 10:12:01] JAVA_OPTS: -Xms1g -Xmx1g ...
[2026-01-10 10:12:01] JAR: your-app.jar
[2026-01-10 10:12:01] 启动应用 your-app.jar
[2026-01-10 10:12:02] watchdog 启动 PID=12345
```



## 🎯 使用指南

### 启动应用
```bash
./bootstrap.sh start
```
- 自动查找最新的 JAR 文件
- 启动应用并记录进程 ID
- 启动 Watchdog 监控进程
- 显示系统环境信息

### 停止应用
```bash
./bootstrap.sh stop
```
- 发送停止信号给应用
- 等待 3 秒后强制终止
- 清理 PID 文件
- 停止 Watchdog 进程

### 重启应用
```bash
./bootstrap.sh restart
```
- 先停止应用
- 等待 2 秒
- 重新启动应用

### 查看应用状态
```bash
./bootstrap.sh status
```
- 检查应用进程是否运行
- 显示进程 ID（如果运行中）

## ⚙️ 配置说明

### JVM 参数配置
脚本预设了性能优化的 JVM 参数：

```bash
JAVA_OPT="-Xms1g -Xmx1g \
-XX:MaxDirectMemorySize=2g \
-XX:+UseG1GC \
-XX:MaxGCPauseMillis=50 \
-XX:+UseStringDeduplication \
-Dfile.encoding=UTF-8 \
-Duser.timezone=Asia/Shanghai"
```

**参数说明：**
- `-Xms1g -Xmx1g`: 堆内存初始和最大值 1GB
- `-XX:MaxDirectMemorySize=2g`: 直接内存最大 2GB
- `-XX:+UseG1GC`: 使用 G1 垃圾收集器
- `-XX:MaxGCPauseMillis=50`: 最大 GC 暂停时间 50ms
- `-XX:+UseStringDeduplication`: 字符串去重（G1GC 下有效）
- `-Dfile.encoding=UTF-8`: 文件编码 UTF-8
- `-Duser.timezone=Asia/Shanghai`: 时区设置为上海

### 日志配置
- **日志文件**: `app.log`
- **最大日志大小**: 100MB (104,857,600 字节)
- **保留备份数量**: 5 份
- **日志轮转**: 自动检测并切割超大日志文件

### 监控配置
- **重启间隔**: 5 秒
- **Watchdog**: 持续监控应用状态
- **异常重启**: 应用退出后自动重启

## 📁 文件说明

| 文件名 | 用途 | 说明 |
|--------|------|------|
| `app.pid` | 应用进程 ID 文件 | 记录主应用的进程 ID |
| `watchdog.pid` | 监控进程 ID 文件 | 记录 Watchdog 的进程 ID |
| `.stopped` | 停止标志文件 | 标记应用停止状态 |
| `app.log` | 应用日志文件 | 应用的标准输出和错误输出 |
| `app.log.1~5` | 日志备份文件 | 轮转后的日志备份 |

## 🔧 工作原理

### 进程管理
1. **启动流程**:
   - 脚本启动后自动查找最新 JAR 文件
   - 启动 Java 应用并记录 PID 到 `app.pid`
   - 同时启动 Watchdog 进程并记录 PID 到 `watchdog.pid`

2. **监控机制**:
   - Watchdog 每 5 秒检查一次应用进程状态
   - 使用 `kill -0` 检查进程是否存在
   - 如果应用异常退出，Watchdog 会自动重启

3. **停止流程**:
   - 创建 `.stopped` 标志文件
   - 发送 SIGTERM 信号给应用进程
   - 等待 3 秒后发送 SIGKILL 强制终止
   - 停止 Watchdog 进程并清理 PID 文件

### 日志轮转机制
- 当 `app.log` 文件大小超过 100MB 时触发轮转
- 原 `app.log` 重命名为 `app.log.1`
- 原 `app.log.1` 到 `app.log.4` 依次递增命名
- 创建新的 `app.log` 文件继续写入
- 最多保留 5 个备份文件

## 🛠️ 自定义配置

如需修改配置参数，可以直接编辑脚本中的以下变量：

```bash
# JVM 参数
JAVA_OPT="-Xms2g -Xmx2g ..."  # 根据服务器资源调整

# 重启间隔（秒）
RESTART_INTERVAL=10

# 最大日志大小（字节）
MAX_LOG_SIZE=$((200 * 1024 * 1024))  # 200MB

# 日志备份数量
LOG_BACKUPS=10

# PID 文件名
PID_FILE="myapp.pid"
```

## 🐛 故障排查

### 查看应用日志
```bash
# 实时查看最新日志
tail -f app.log

# 查看最近的错误信息
grep -i error app.log

# 查看 GC 相关信息
grep -i gc app.log
```

### 检查进程状态
```bash
# 查看应用运行状态
./bootstrap.sh status

# 查看 Java 进程详情
ps aux | grep java

# 查看所有相关进程
ps aux | grep -E "(java|bootstrap)"
```

### 手动管理进程
```bash
# 停止 Watchdog（如果卡住）
kill -9 $(cat watchdog.pid)
rm -f watchdog.pid

# 清理残留 PID 文件
rm -f app.pid watchdog.pid
```

### 常见问题

**Q: 应用启动失败怎么办？**
A: 检查 `app.log` 文件中的错误信息，确认 JAR 文件完整性和依赖项。

**Q: 内存不够用怎么办？**
A: 修改 `JAVA_OPT` 中的堆内存参数，如 `-Xms2g -Xmx4g`。

**Q: 日志文件增长太快？**
A: 调整 `MAX_LOG_SIZE` 或增加 `LOG_BACKUPS` 数量。

## 🔒 安全注意事项

- 确保脚本所在目录有足够的写入权限
- 不要手动删除 PID 文件，会影响进程管理
- 定期检查磁盘空间，避免日志文件占满磁盘
- 生产环境中建议配合系统监控工具使用

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request 来改进脚本功能。

## 📄 License

MIT License

## 🆘 支持

如遇到问题，请检查：
1. Java 环境是否正确安装
2. JAR 文件是否完整
3. 系统权限是否足够
4. 相关端口是否被占用

如果仍有问题，请查看日志文件或提交 Issue。
