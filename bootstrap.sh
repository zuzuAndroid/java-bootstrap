#!/bin/bash
#######################################################
# Java 应用守护启动脚本
#######################################################

set -euo pipefail

JAVA_OPT="-Xms1g -Xmx1g \
-XX:MaxDirectMemorySize=2g \
-XX:+UseG1GC \
-XX:MaxGCPauseMillis=50 \
-XX:+UseStringDeduplication \
-Dfile.encoding=UTF-8 \
-Duser.timezone=Asia/Shanghai"

JARFILE=$(ls -1r *.jar 2>/dev/null | head -n 1)

PID_FILE="app.pid"
WATCHDOG_PID_FILE="watchdog.pid"
STOP_FLAG=".stopped"

RESTART_INTERVAL=5
PWD=$(pwd)

LOG_FILE="app.log"
MAX_LOG_SIZE=$((100 * 1024 * 1024))
LOG_BACKUPS=5

rotate_log() {
    if [[ -f "$LOG_FILE" ]]; then
        local size
        size=$(stat -c%s "$LOG_FILE")

        if (( size >= MAX_LOG_SIZE )); then
            log "nohup.out 超过 $((MAX_LOG_SIZE/1024/1024))MB，进行切割"

            for ((i=LOG_BACKUPS-1; i>=1; i--)); do
                [[ -f "$LOG_FILE.$i" ]] && mv "$LOG_FILE.$i" "$LOG_FILE.$((i+1))"
            done

            mv "$LOG_FILE" "$LOG_FILE.1"
            : > "$LOG_FILE"
        fi
    fi
}

log() {
    echo "[$(date '+%F %T')] $*" >&2
}

print_os_info() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        log "OS: $NAME $VERSION"
    else
        log "OS: $(uname -srm)"
    fi
}

print_java_info() {
    if command -v java >/dev/null 2>&1; then
        local java_ver
        java_ver=$(java -version 2>&1 | head -n 1)
        log "Java: $java_ver"
    else
        log "Java: NOT FOUND"
    fi
}

is_running() {
    [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

start_app() {
    rm -f "$STOP_FLAG"

    if is_running; then
        log "应用已运行 PID=$(cat $PID_FILE)"
        return
    fi

    log "========== 环境信息 =========="
    print_os_info
    print_java_info
    log "JAVA_OPTS: $JAVA_OPT"
    log "JAR: $JARFILE"
    log "=============================="

    log "启动应用 $JARFILE"
    rotate_log
    nohup java $JAVA_OPT -jar "$PWD/$JARFILE" >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"

    launch_watchdog
}

stop_app() {
    log "停止应用..."
    touch "$STOP_FLAG"

    if is_running; then
        pid=$(cat "$PID_FILE")
        kill "$pid"
        sleep 3
        kill -9 "$pid" 2>/dev/null || true
    fi

    rm -f "$PID_FILE"
    stop_watchdog
    log "应用已停止"
}

launch_watchdog() {
    if [[ -f "$WATCHDOG_PID_FILE" ]] && kill -0 "$(cat "$WATCHDOG_PID_FILE")" 2>/dev/null; then
        return
    fi

    nohup "$0" watchdog >/dev/null 2>&1 &
    echo $! > "$WATCHDOG_PID_FILE"
    log "watchdog 启动 PID=$(cat $WATCHDOG_PID_FILE)"
}

stop_watchdog() {
    if [[ -f "$WATCHDOG_PID_FILE" ]]; then
        wd=$(cat "$WATCHDOG_PID_FILE")
        kill "$wd" 2>/dev/null || true
        kill -9 "$wd" 2>/dev/null || true
        rm -f "$WATCHDOG_PID_FILE"
    fi
}

watchdog() {
    log "watchdog running PID=$$"
    echo $$ > "$WATCHDOG_PID_FILE"

    while true; do
        if [[ -f "$STOP_FLAG" ]]; then
            log "检测到 stop 标志，watchdog 退出"
            exit 0
        fi

        if ! is_running; then
            log "应用异常退出，重启中..."
	    rotate_log
            nohup java $JAVA_OPT -jar "$PWD/$JARFILE" >> "$LOG_FILE" 2>&1 &
            echo $! > "$PID_FILE"
        fi

        sleep "$RESTART_INTERVAL"
    done
}

case "${1:-}" in
    start) start_app ;;
    stop) stop_app ;;
    restart) stop_app; sleep 2; start_app ;;
    status)
        is_running && log "运行中 PID=$(cat $PID_FILE)" || log "未运行"
        ;;
    watchdog) watchdog ;;
    *) echo "Usage: $0 {start|stop|restart|status}" ;;
esac