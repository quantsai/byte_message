#!/bin/bash

# Byte Message 测试运行脚本
# 提供快速的测试执行功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_info() {
    echo -e "${BLUE}$1${NC}"
}

# 检查Dart是否安装
check_dart() {
    if ! command -v dart &> /dev/null; then
        print_error "❌ Dart未安装或不在PATH中"
        exit 1
    fi
    print_success "✅ Dart已安装: $(dart --version | head -n1)"
}

# 运行所有测试
run_all_tests() {
    print_header "运行所有测试"
    
    if dart test; then
        print_success "✅ 所有测试通过"
    else
        print_error "❌ 测试失败"
        exit 1
    fi
}

# 运行特定测试
run_specific_test() {
    local test_file=$1
    print_header "运行测试: $test_file"
    
    if dart test "test/$test_file"; then
        print_success "✅ 测试通过: $test_file"
    else
        print_error "❌ 测试失败: $test_file"
        exit 1
    fi
}

# 运行测试并生成覆盖率
run_with_coverage() {
    print_header "运行测试并生成覆盖率报告"
    
    # 创建覆盖率目录
    mkdir -p coverage
    
    print_info "📊 收集覆盖率数据..."
    if dart test --coverage=coverage; then
        print_info "📈 生成覆盖率报告..."
        if dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib 2>/dev/null; then
            print_success "✅ 覆盖率报告已生成: coverage/lcov.info"
        else
            print_warning "⚠️  覆盖率报告生成失败，但测试通过"
        fi
    else
        print_error "❌ 测试失败，无法生成覆盖率报告"
        exit 1
    fi
}

# 检查代码格式
check_format() {
    print_header "检查代码格式"
    
    if dart format --set-exit-if-changed .; then
        print_success "✅ 代码格式正确"
    else
        print_error "❌ 代码格式需要修正"
        print_info "运行 'dart format .' 来修正格式"
        exit 1
    fi
}

# 运行代码分析
run_analysis() {
    print_header "运行代码分析"
    
    if dart analyze; then
        print_success "✅ 代码分析通过"
    else
        print_error "❌ 代码分析发现问题"
        exit 1
    fi
}

# 运行完整CI检查
run_ci_checks() {
    print_header "运行CI检查"
    
    check_format
    run_analysis
    run_all_tests
    run_with_coverage
    
    print_success "🎉 所有CI检查通过！"
}

# 显示帮助信息
show_help() {
    echo -e "${BOLD}Byte Message 测试运行脚本${NC}"
    echo ""
    echo "用法: ./run_tests.sh [选项]"
    echo ""
    echo "选项:"
    echo "  all              运行所有测试"
    echo "  coverage         运行测试并生成覆盖率报告"
    echo "  format           检查代码格式"
    echo "  analyze          运行代码分析"
    echo "  ci               运行完整CI检查"
    echo "  <test_file>      运行特定测试文件"
    echo "  help             显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  ./run_tests.sh all"
    echo "  ./run_tests.sh coverage"
    echo "  ./run_tests.sh encoder_test.dart"
    echo "  ./run_tests.sh ci"
}

# 主函数
main() {
    # 检查Dart环境
    check_dart
    
    # 处理命令行参数
    case "${1:-help}" in
        "all")
            run_all_tests
            ;;
        "coverage")
            run_with_coverage
            ;;
        "format")
            check_format
            ;;
        "analyze")
            run_analysis
            ;;
        "ci")
            run_ci_checks
            ;;
        "help"|"")
            show_help
            ;;
        *_test.dart)
            run_specific_test "$1"
            ;;
        *)
            print_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"