#!/usr/bin/env dart

/// 测试运行脚本
///
/// 提供便捷的测试执行和报告功能，支持：
/// - 运行所有测试
/// - 运行特定测试套件
/// - 生成覆盖率报告
/// - 性能测试
/// - 测试结果统计
library;

import 'dart:io';
class TestRunner {
  static const String _resetColor = '\x1B[0m';
  static const String _greenColor = '\x1B[32m';
  static const String _redColor = '\x1B[31m';
  static const String _yellowColor = '\x1B[33m';
  static const String _blueColor = '\x1B[34m';
  static const String _boldColor = '\x1B[1m';

  /// 运行所有测试
  static Future<void> runAllTests() async {
    _printHeader('运行所有测试');

    final result = await _runCommand(['dart', 'test']);

    if (result.exitCode == 0) {
      _printSuccess('✅ 所有测试通过');
    } else {
      _printError('❌ 测试失败');
      exit(1);
    }
  }

  /// 运行特定测试文件
  static Future<void> runSpecificTest(String testFile) async {
    _printHeader('运行测试: $testFile');

    final result = await _runCommand(['dart', 'test', 'test/$testFile']);

    if (result.exitCode == 0) {
      _printSuccess('✅ 测试通过: $testFile');
    } else {
      _printError('❌ 测试失败: $testFile');
      exit(1);
    }
  }

  /// 运行测试并生成覆盖率报告
  static Future<void> runWithCoverage() async {
    _printHeader('运行测试并生成覆盖率报告');

    // 创建覆盖率目录
    final coverageDir = Directory('coverage');
    if (!coverageDir.existsSync()) {
      coverageDir.createSync();
    }

    // 运行测试并收集覆盖率
    _printInfo('📊 收集覆盖率数据...');
    var result = await _runCommand(['dart', 'test', '--coverage=coverage']);

    if (result.exitCode != 0) {
      _printError('❌ 测试失败，无法生成覆盖率报告');
      exit(1);
    }

    // 格式化覆盖率报告
    _printInfo('📈 生成覆盖率报告...');
    result = await _runCommand([
      'dart',
      'run',
      'coverage:format_coverage',
      '--lcov',
      '--in=coverage',
      '--out=coverage/lcov.info',
      '--report-on=lib',
    ]);

    if (result.exitCode == 0) {
      _printSuccess('✅ 覆盖率报告已生成: coverage/lcov.info');
    } else {
      _printWarning('⚠️  覆盖率报告生成失败，但测试通过');
    }
  }

  /// 运行性能测试
  static Future<void> runPerformanceTests() async {
    _printHeader('运行性能测试');

    final result = await _runCommand([
      'dart',
      'test',
      'test/integration_test.dart',
      '--name=performance',
    ]);

    if (result.exitCode == 0) {
      _printSuccess('✅ 性能测试通过');
    } else {
      _printError('❌ 性能测试失败');
      exit(1);
    }
  }

  /// 运行测试套件
  static Future<void> runTestSuite() async {
    _printHeader('运行完整测试套件');

    final testFiles = [
      'packet_models_test.dart',
      'encoder_test.dart',
      'decoder_test.dart',
      'packet_utils_test.dart',
      'integration_test.dart',
    ];

    var passedTests = 0;
    var failedTests = 0;

    for (final testFile in testFiles) {
      _printInfo('🧪 运行: $testFile');

      final result = await _runCommand(['dart', 'test', 'test/$testFile']);

      if (result.exitCode == 0) {
        _printSuccess('  ✅ 通过');
        passedTests++;
      } else {
        _printError('  ❌ 失败');
        failedTests++;
      }
    }

    _printHeader('测试结果统计');
    _printInfo('总测试文件: ${testFiles.length}');
    _printSuccess('通过: $passedTests');

    if (failedTests > 0) {
      _printError('失败: $failedTests');
      exit(1);
    } else {
      _printSuccess('🎉 所有测试套件通过！');
    }
  }

  /// 检查代码格式
  static Future<void> checkFormat() async {
    _printHeader('检查代码格式');

    final result = await _runCommand([
      'dart',
      'format',
      '--set-exit-if-changed',
      '.',
    ]);

    if (result.exitCode == 0) {
      _printSuccess('✅ 代码格式正确');
    } else {
      _printError('❌ 代码格式需要修正');
      _printInfo('运行 "dart format ." 来修正格式');
      exit(1);
    }
  }

  /// 运行代码分析
  static Future<void> runAnalysis() async {
    _printHeader('运行代码分析');

    final result = await _runCommand(['dart', 'analyze']);

    if (result.exitCode == 0) {
      _printSuccess('✅ 代码分析通过');
    } else {
      _printError('❌ 代码分析发现问题');
      exit(1);
    }
  }

  /// 完整的CI检查
  static Future<void> runCIChecks() async {
    _printHeader('运行CI检查');

    await checkFormat();
    await runAnalysis();
    await runAllTests();
    await runWithCoverage();

    _printSuccess('🎉 所有CI检查通过！');
  }

  /// 执行命令
  static Future<ProcessResult> _runCommand(List<String> command) async {
    final process = await Process.run(
      command.first,
      command.skip(1).toList(),
      runInShell: true,
    );

    if (process.stdout.toString().isNotEmpty) {
      print(process.stdout);
    }

    if (process.stderr.toString().isNotEmpty) {
      print(process.stderr);
    }

    return process;
  }

  /// 打印标题
  static void _printHeader(String message) {
    print('\n$_boldColor$_blueColor=== $message ===$_resetColor\n');
  }

  /// 打印成功信息
  static void _printSuccess(String message) {
    print('$_greenColor$message$_resetColor');
  }

  /// 打印错误信息
  static void _printError(String message) {
    print('$_redColor$message$_resetColor');
  }

  /// 打印警告信息
  static void _printWarning(String message) {
    print('$_yellowColor$message$_resetColor');
  }

  /// 打印信息
  static void _printInfo(String message) {
    print('$_blueColor$message$_resetColor');
  }

  /// 显示帮助信息
  static void showHelp() {
    print('''
${_boldColor}Byte Message 测试运行器$_resetColor

用法: dart test_runner.dart [选项]

选项:
  all              运行所有测试
  suite            运行测试套件（逐个文件）
  coverage         运行测试并生成覆盖率报告
  performance      运行性能测试
  format           检查代码格式
  analyze          运行代码分析
  ci               运行完整CI检查
  <test_file>      运行特定测试文件
  help             显示此帮助信息

示例:
  dart test_runner.dart all
  dart test_runner.dart coverage
  dart test_runner.dart encoder_test.dart
  dart test_runner.dart ci
''');
  }
}

void main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.contains('help')) {
    TestRunner.showHelp();
    return;
  }

  final command = arguments.first;

  try {
    switch (command) {
      case 'all':
        await TestRunner.runAllTests();
        break;
      case 'suite':
        await TestRunner.runTestSuite();
        break;
      case 'coverage':
        await TestRunner.runWithCoverage();
        break;
      case 'performance':
        await TestRunner.runPerformanceTests();
        break;
      case 'format':
        await TestRunner.checkFormat();
        break;
      case 'analyze':
        await TestRunner.runAnalysis();
        break;
      case 'ci':
        await TestRunner.runCIChecks();
        break;
      default:
        if (command.endsWith('_test.dart')) {
          await TestRunner.runSpecificTest(command);
        } else {
          TestRunner._printError('未知命令: $command');
          TestRunner.showHelp();
          exit(1);
        }
    }
  } catch (e) {
    TestRunner._printError('执行失败: $e');
    exit(1);
  }
}
