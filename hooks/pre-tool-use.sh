#!/bin/bash
# Pre-Tool-Use Hook - 工具调用前校验
# 在 AI 执行代码编辑、命令运行前触发

set -e

TOOL_NAME="$1"
TOOL_INPUT="$2"

# 日志记录
log_message() {
    echo "[PreToolUse] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> ~/.claude/logs/hooks.log
}

# 检查是否修改非目标文件
check_file_scope() {
    local file_path="$1"

    # 读取当前任务的目标文件列表
    if [ -f ".claude/current-task-files.txt" ]; then
        if ! grep -q "$file_path" ".claude/current-task-files.txt"; then
            log_message "WARNING: Attempting to modify file outside task scope: $file_path"
            echo "⚠️ 警告：尝试修改任务范围外的文件: $file_path"
            echo "请确认是否需要修改此文件，或更新任务范围。"
            return 1
        fi
    fi
    return 0
}

# 检查高危命令
check_dangerous_command() {
    local cmd="$1"

    # 危险命令列表
    local dangerous_patterns=(
        "rm -rf"
        "git push --force"
        "git reset --hard"
        "DROP TABLE"
        "TRUNCATE"
        "DELETE FROM"
        ":(){ :|:& };:"
        "chmod 777"
        "chown -R"
    )

    for pattern in "${dangerous_patterns[@]}"; do
        if echo "$cmd" | grep -qi "$pattern"; then
            log_message "BLOCKED: Dangerous command detected: $pattern"
            echo "🚫 阻止执行高危命令: $pattern"
            echo "如需执行，请手动确认。"
            return 1
        fi
    done
    return 0
}

# 主逻辑
main() {
    case "$TOOL_NAME" in
        "Edit"|"Write")
            # 提取文件路径
            file_path=$(echo "$TOOL_INPUT" | grep -oP '"file_path"\s*:\s*"\K[^"]+' || true)
            if [ -n "$file_path" ]; then
                check_file_scope "$file_path" || exit 1
            fi
            ;;
        "Bash")
            # 提取命令
            cmd=$(echo "$TOOL_INPUT" | grep -oP '"command"\s*:\s*"\K[^"]+' || true)
            if [ -n "$cmd" ]; then
                check_dangerous_command "$cmd" || exit 1
            fi
            ;;
    esac

    log_message "ALLOWED: $TOOL_NAME"
    exit 0
}

main
