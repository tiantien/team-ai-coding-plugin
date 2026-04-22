#!/bin/bash
# Security Check Hook - 安全扫描
# 执行安全检查，包括 SQL 注入、XSS、敏感信息泄露等

set -e

SCAN_PATH="${1:-.}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 日志记录
log_message() {
    echo "[SecurityCheck] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> ~/.claude/logs/security.log
}

print_status() {
    echo -e "${2}${1}${NC}"
}

# SQL 注入检查
check_sql_injection() {
    print_status "🔍 检查 SQL 注入风险..." "$YELLOW"

    local sql_patterns=(
        "executeQuery\s*\(\s*['\"]\s*SELECT.*\+"
        "query\s*\(\s*['\"]\s*SELECT.*\+"
        "\$\{.*\}.*SELECT"
        "concat\s*\(.*SELECT"
    )

    local found_issues=0

    for pattern in "${sql_patterns[@]}"; do
        local matches=$(grep -rE "$pattern" "$SCAN_PATH" --include="*.java" --include="*.js" --include="*.ts" --include="*.py" 2>/dev/null || true)
        if [ -n "$matches" ]; then
            print_status "⚠️ 发现潜在 SQL 注入风险:" "$YELLOW"
            echo "$matches"
            found_issues=1
        fi
    done

    if [ $found_issues -eq 0 ]; then
        print_status "✅ SQL 注入检查通过" "$GREEN"
    fi

    return $found_issues
}

# XSS 检查
check_xss() {
    print_status "🔍 检查 XSS 风险..." "$YELLOW"

    local xss_patterns=(
        "innerHTML\s*="
        "document\.write\s*\("
        "dangerouslySetInnerHTML"
        "v-html\s*="
        "\[innerHTML\]"
    )

    local found_issues=0

    for pattern in "${xss_patterns[@]}"; do
        local matches=$(grep -rE "$pattern" "$SCAN_PATH" --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" --include="*.vue" --include="*.html" 2>/dev/null || true)
        if [ -n "$matches" ]; then
            print_status "⚠️ 发现潜在 XSS 风险:" "$YELLOW"
            echo "$matches"
            found_issues=1
        fi
    done

    if [ $found_issues -eq 0 ]; then
        print_status "✅ XSS 检查通过" "$GREEN"
    fi

    return $found_issues
}

# 敏感信息检查
check_sensitive_data() {
    print_status "🔍 检查敏感信息泄露..." "$YELLOW"

    local sensitive_patterns=(
        "password\s*[=:]\s*['\"][^'\"]+['\"]"
        "api[_-]?key\s*[=:]\s*['\"][^'\"]+['\"]"
        "secret[_-]?key\s*[=:]\s*['\"][^'\"]+['\"]"
        "access[_-]?token\s*[=:]\s*['\"][^'\"]+['\"]"
        "private[_-]?key\s*[=:]\s*['\"][^'\"]+['\"]"
        "-----BEGIN.*PRIVATE KEY-----"
        "aws_access_key_id\s*=\s*[A-Z0-9]{20}"
        "aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}"
    )

    local found_issues=0

    for pattern in "${sensitive_patterns[@]}"; do
        local matches=$(grep -rE "$pattern" "$SCAN_PATH" --include="*.js" --include="*.ts" --include="*.py" --include="*.java" --include="*.go" --include="*.env" --include="*.properties" --include="*.yml" --include="*.yaml" 2>/dev/null || true)
        if [ -n "$matches" ]; then
            print_status "🚨 发现敏感信息泄露:" "$RED"
            echo "$matches"
            found_issues=1
        fi
    done

    if [ $found_issues -eq 0 ]; then
        print_status "✅ 敏感信息检查通过" "$GREEN"
    fi

    return $found_issues
}

# 依赖安全检查
check_dependencies() {
    print_status "🔍 检查依赖安全..." "$YELLOW"

    if [ -f "package.json" ] && [ -f "package-lock.json" ]; then
        if command -v npm &> /dev/null; then
            if ! npm audit --audit-level=high 2>&1 | grep -q "found 0 vulnerabilities"; then
                print_status "⚠️ 发现依赖安全漏洞，请运行 npm audit fix" "$YELLOW"
            else
                print_status "✅ 依赖安全检查通过" "$GREEN"
            fi
        fi
    elif [ -f "requirements.txt" ]; then
        if command -v safety &> /dev/null; then
            if ! safety check -r requirements.txt 2>&1; then
                print_status "⚠️ 发现依赖安全漏洞" "$YELLOW"
            else
                print_status "✅ 依赖安全检查通过" "$GREEN"
            fi
        else
            print_status "ℹ️ 未安装 safety，跳过 Python 依赖检查" "$YELLOW"
        fi
    else
        print_status "ℹ️ 未发现依赖文件，跳过依赖检查" "$YELLOW"
    fi
}

# 硬编码 IP/URL 检查
check_hardcoded_endpoints() {
    print_status "🔍 检查硬编码端点..." "$YELLOW"

    local endpoint_patterns=(
        "https?://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"
        "https?://localhost:[0-9]+"
        "https?://127\.0\.0\.1:[0-9]+"
    )

    local found_issues=0

    for pattern in "${endpoint_patterns[@]}"; do
        local matches=$(grep -rE "$pattern" "$SCAN_PATH" --include="*.js" --include="*.ts" --include="*.py" --include="*.java" --include="*.go" 2>/dev/null | grep -v "test" | grep -v "spec" || true)
        if [ -n "$matches" ]; then
            print_status "⚠️ 发现硬编码端点（非测试文件）:" "$YELLOW"
            echo "$matches"
            found_issues=1
        fi
    done

    if [ $found_issues -eq 0 ]; then
        print_status "✅ 硬编码端点检查通过" "$GREEN"
    fi

    return $found_issues
}

# 生成安全报告
generate_report() {
    local report_file=".claude/security-report-$(date '+%Y%m%d-%H%M%S').md"

    echo "# 安全扫描报告" > "$report_file"
    echo "" >> "$report_file"
    echo "**扫描时间**: $(date '+%Y-%m-%d %H:%M:%S')" >> "$report_file"
    echo "**扫描路径**: $SCAN_PATH" >> "$report_file"
    echo "" >> "$report_file"
    echo "## 扫描结果" >> "$report_file"
    echo "" >> "$report_file"
    echo "- SQL 注入: 已检查" >> "$report_file"
    echo "- XSS: 已检查" >> "$report_file"
    echo "- 敏感信息: 已检查" >> "$report_file"
    echo "- 依赖安全: 已检查" >> "$report_file"
    echo "- 硬编码端点: 已检查" >> "$report_file"

    print_status "📄 安全报告已生成: $report_file" "$GREEN"
}

# 主流程
main() {
    print_status "🛡️ 开始安全扫描..." "$YELLOW"
    echo ""

    local total_issues=0

    check_sql_injection || total_issues=$((total_issues + 1))
    check_xss || total_issues=$((total_issues + 1))
    check_sensitive_data || total_issues=$((total_issues + 1))
    check_dependencies
    check_hardcoded_endpoints || total_issues=$((total_issues + 1))

    generate_report

    echo ""
    if [ $total_issues -gt 0 ]; then
        print_status "⚠️ 发现 $total_issues 个安全问题，请修复后再提交" "$YELLOW"
        log_message "SECURITY ISSUES FOUND: $total_issues"
        exit 1
    else
        print_status "✅ 安全扫描通过" "$GREEN"
        log_message "SECURITY CHECK PASSED"
    fi
}

main
