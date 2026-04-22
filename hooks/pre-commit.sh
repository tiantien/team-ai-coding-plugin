#!/bin/bash
# Pre-Commit Hook - 提交前门禁
# 在代码提交前触发，强制执行代码审查、测试、安全扫描

set -e

COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="$2"
SHA1="$3"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志记录
log_message() {
    echo "[PreCommit] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> ~/.claude/logs/hooks.log
}

# 打印状态
print_status() {
    echo -e "${2}${1}${NC}"
}

# 检查是否在 main/master 分支
check_branch() {
    local branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$branch" == "main" || "$branch" == "master" ]]; then
        print_status "❌ 禁止直接提交到 main/master 分支" "$RED"
        echo "请创建功能分支进行开发。"
        exit 1
    fi
    print_status "✅ 分支检查通过: $branch" "$GREEN"
}

# 检查是否有未通过的测试
check_tests() {
    print_status "🔍 运行测试..." "$YELLOW"

    # 检查是否存在测试配置
    if [ -f "package.json" ]; then
        if grep -q '"test"' package.json; then
            if ! npm test 2>&1; then
                print_status "❌ 测试未通过，请修复后再提交" "$RED"
                exit 1
            fi
        fi
    elif [ -f "pom.xml" ]; then
        if ! mvn test -q 2>&1; then
            print_status "❌ 测试未通过，请修复后再提交" "$RED"
            exit 1
        fi
    elif [ -f "requirements.txt" ] && [ -d "tests" ]; then
        if ! python -m pytest -q 2>&1; then
            print_status "❌ 测试未通过，请修复后再提交" "$RED"
            exit 1
        fi
    fi

    print_status "✅ 测试检查通过" "$GREEN"
}

# 检查代码风格
check_lint() {
    print_status "🔍 检查代码风格..." "$YELLOW"

    if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ]; then
        if ! npx eslint . --quiet 2>&1; then
            print_status "❌ 代码风格检查未通过" "$RED"
            exit 1
        fi
    elif [ -f ".prettierrc" ]; then
        if ! npx prettier --check . 2>&1; then
            print_status "❌ 代码格式检查未通过" "$RED"
            exit 1
        fi
    fi

    print_status "✅ 代码风格检查通过" "$GREEN"
}

# 检查敏感信息
check_secrets() {
    print_status "🔍 检查敏感信息..." "$YELLOW"

    local secret_patterns=(
        "password\s*=\s*['\"][^'\"]+['\"]"
        "api_key\s*=\s*['\"][^'\"]+['\"]"
        "secret\s*=\s*['\"][^'\"]+['\"]"
        "token\s*=\s*['\"][^'\"]+['\"]"
        "-----BEGIN.*PRIVATE KEY-----"
    )

    local staged_files=$(git diff --cached --name-only --diff-filter=ACM)

    for file in $staged_files; do
        if [ -f "$file" ]; then
            for pattern in "${secret_patterns[@]}"; do
                if grep -qE "$pattern" "$file" 2>/dev/null; then
                    print_status "❌ 发现敏感信息: $file" "$RED"
                    echo "请移除敏感信息或使用环境变量。"
                    exit 1
                fi
            done
        fi
    done

    print_status "✅ 敏感信息检查通过" "$GREEN"
}

# 检查提交信息格式
check_commit_message() {
    local msg=$(cat "$COMMIT_MSG_FILE")

    # 提交信息格式: type(scope): description
    local pattern="^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?:\s*.+"

    if ! echo "$msg" | grep -qE "$pattern"; then
        print_status "❌ 提交信息格式不正确" "$RED"
        echo "正确格式: type(scope): description"
        echo "示例: feat(user): add login feature"
        echo ""
        echo "类型列表:"
        echo "  feat:     新功能"
        echo "  fix:      修复 bug"
        echo "  docs:     文档更新"
        echo "  style:    代码格式调整"
        echo "  refactor: 代码重构"
        echo "  test:     测试相关"
        echo "  chore:    构建/工具相关"
        exit 1
    fi

    print_status "✅ 提交信息格式正确" "$GREEN"
}

# 主流程
main() {
    print_status "🚀 开始 Pre-Commit 检查..." "$YELLOW"
    echo ""

    check_branch
    check_secrets
    check_lint
    check_tests
    check_commit_message

    echo ""
    print_status "✅ 所有检查通过，允许提交" "$GREEN"
    log_message "COMMIT ALLOWED"
}

main
