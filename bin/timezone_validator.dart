#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:rss_agent/src/parsers/rss2_parser.dart';

/// RSS pubDate 時區解析與轉換工具
void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: '顯示幫助信息')
    ..addFlag('validate', abbr: 'v', help: '運行驗證測試套件', defaultsTo: false)
    ..addOption('input', abbr: 'i', help: '輸入的 RSS pubDate 字串')
    ..addOption('to-timezone', abbr: 't', help: '輸出時區 (如: +0800, GMT, JST)')
    ..addFlag('interactive', help: '進入交互模式', defaultsTo: false)
    ..addFlag('json', help: '以 JSON 格式輸出結果', defaultsTo: false);

  late ArgResults results;
  try {
    results = parser.parse(args);
  } catch (e) {
    print('❌ 參數錯誤: $e\n');
    _showUsage(parser);
    exit(1);
  }

  if (results['help']) {
    _showUsage(parser);
    return;
  }

  final converter = TimezoneConverter();

  if (results['validate']) {
    await _runValidationSuite(converter, results['json']);
    return;
  }

  if (results['interactive']) {
    await _runInteractiveMode(converter);
    return;
  }

  final input = results['input'] as String?;
  if (input == null) {
    print('❌ 請提供輸入的 pubDate 字串\n');
    _showUsage(parser);
    exit(1);
  }

  final targetTimezone = results['to-timezone'] as String?;
  final useJson = results['json'] as bool;

  await _processInput(converter, input, targetTimezone, useJson);
}

/// 顯示使用說明
void _showUsage(ArgParser parser) {
  print('RSS pubDate 時區解析與轉換工具\n');
  print('用法:');
  print('  dart run bin/timezone_validator.dart [選項]\n');
  print('選項:');
  print(parser.usage);
  print('\n範例:');
  print('  # 運行驗證測試套件');
  print('  dart run bin/timezone_validator.dart --validate\n');
  print('  # 解析並轉換時區');
  print(
      '  dart run bin/timezone_validator.dart -i "Thu, 28 Aug 2025 00:46:04 +0800" -t "GMT"\n');
  print('  # 交互模式');
  print('  dart run bin/timezone_validator.dart --interactive\n');
  print('  # JSON 輸出');
  print(
      '  dart run bin/timezone_validator.dart -i "Thu, 28 Aug 2025 00:46:04 +0800" --json');
}

/// 運行驗證測試套件
Future<void> _runValidationSuite(
    TimezoneConverter converter, bool useJson) async {
  final testCases = [
    'Thu, 28 Aug 2025 00:46:04 +0800', // 台北時間
    'Wed, 27 Aug 2025 12:00:00 -0500', // 美東時間
    'Thu, 28 Aug 2025 10:30:00 +0930', // 澳洲阿德雷德時間
    'Wed, 27 Aug 2025 15:30:00 GMT', // GMT
    'Wed, 27 Aug 2025 20:15:00 UTC', // UTC
    'Fri, 29 Aug 2025 14:22:33 EST', // 美東標準時間
    'Sat, 30 Aug 2025 09:15:00 JST', // 日本標準時間
  ];

  if (useJson) {
    final results = <Map<String, dynamic>>[];
    for (final testCase in testCases) {
      final result = converter.validate(testCase);
      results.add({
        'input': result.input,
        'success': result.success,
        'parsed': result.parsed?.toIso8601String(),
        'expected': result.expected?.toIso8601String(),
        'timezone': result.timezoneInfo != null
            ? {
                'original': result.timezoneInfo!.original,
                'type': result.timezoneInfo!.type,
                'offsetMinutes': result.timezoneInfo!.offsetMinutes,
                'description': result.timezoneInfo!.description,
              }
            : null,
        'error': result.error,
      });
    }

    final summary = {
      'total': results.length,
      'passed': results.where((r) => r['success']).length,
      'failed': results.where((r) => !r['success']).length,
      'results': results,
    };

    print(_formatJson(summary));
    return;
  }

  print('=== RSS pubDate 時區解析驗證測試套件 ===\n');
  print('📋 運行預設測試案例...\n');

  for (var i = 0; i < testCases.length; i++) {
    print('--- 測試案例 ${i + 1} ---');
    final result = converter.validate(testCases[i]);
    print(result);
    print('');
  }

  final results = converter.validateBatch(testCases);
  final successCount = results.where((r) => r.success).length;
  final totalCount = results.length;

  print('=== 統計結果 ===');
  print('✅ 正確: $successCount');
  print('❌ 錯誤: ${totalCount - successCount}');
  print('📈 正確率: ${(successCount / totalCount * 100).toStringAsFixed(1)}%');

  if (successCount < totalCount) {
    print('\n⚠️  發現時區解析問題！建議檢查 RFC 2822 解析器。');
    exit(1);
  }
}

/// 運行交互模式
Future<void> _runInteractiveMode(TimezoneConverter converter) async {
  print('=== RSS pubDate 時區轉換工具 (交互模式) ===');
  print('輸入 "quit" 或 "exit" 退出\n');

  while (true) {
    stdout.write('請輸入 RSS pubDate 字串: ');
    final input = stdin.readLineSync();

    if (input == null || input.trim().isEmpty) {
      continue;
    }

    final trimmedInput = input.trim();
    if (trimmedInput.toLowerCase() == 'quit' ||
        trimmedInput.toLowerCase() == 'exit') {
      print('👋 再見！');
      break;
    }

    // 解析輸入
    final result = converter.validate(trimmedInput);
    if (!result.success) {
      print('❌ 解析失敗: ${result.error}\n');
      continue;
    }

    print('\n📊 解析結果:');
    print('  原始輸入: ${result.input}');
    print(
        '  時區信息: ${result.timezoneInfo!.original} (${result.timezoneInfo!.description})');
    print('  UTC 時間: ${result.parsed}');

    // 詢問目標時區
    stdout.write('\n請輸入目標時區 (如: +0800, GMT, JST) 或按 Enter 跳過: ');
    final targetTimezone = stdin.readLineSync()?.trim();

    if (targetTimezone != null && targetTimezone.isNotEmpty) {
      final converted =
          converter.convertToTimezone(result.parsed!, targetTimezone);
      if (converted != null) {
        print('🕐 轉換結果: $converted');
      } else {
        print('❌ 無法轉換到時區: $targetTimezone');
      }
    }

    print('${'=' * 50}\n');
  }
}

/// 處理單一輸入
Future<void> _processInput(TimezoneConverter converter, String input,
    String? targetTimezone, bool useJson) async {
  final result = converter.validate(input);

  if (useJson) {
    final jsonResult = {
      'input': result.input,
      'success': result.success,
      'parsed': result.parsed?.toIso8601String(),
      'expected': result.expected?.toIso8601String(),
      'timezone': result.timezoneInfo != null
          ? {
              'original': result.timezoneInfo!.original,
              'type': result.timezoneInfo!.type,
              'offsetMinutes': result.timezoneInfo!.offsetMinutes,
              'description': result.timezoneInfo!.description,
            }
          : null,
      'error': result.error,
    };

    if (targetTimezone != null && result.success && result.parsed != null) {
      final converted =
          converter.convertToTimezone(result.parsed!, targetTimezone);
      jsonResult['converted'] = {
        'timezone': targetTimezone,
        'result': converted?.toIso8601String(),
        'success': converted != null,
      };
    }

    print(_formatJson(jsonResult));
    return;
  }

  print('=== RSS pubDate 時區解析結果 ===\n');
  print(result);

  if (targetTimezone != null && result.success && result.parsed != null) {
    print('--- 時區轉換 ---');
    final converted =
        converter.convertToTimezone(result.parsed!, targetTimezone);
    if (converted != null) {
      print('🕐 轉換到 $targetTimezone: $converted');
    } else {
      print('❌ 無法轉換到時區: $targetTimezone');
    }
  }

  if (!result.success) {
    exit(1);
  }
}

/// 格式化 JSON 輸出
String _formatJson(Map<String, dynamic> data) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(data);
}

/// 時區轉換器
class TimezoneConverter {
  final Rss2Parser _parser = Rss2Parser();

  /// 驗證單一時間字串的解析結果
  ValidationResult validate(String pubDateStr) {
    final rssXml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <link>https://example.com</link>
    <description>Test feed</description>
    <item>
      <title>Test Article</title>
      <link>https://example.com/article</link>
      <description>Test article</description>
      <pubDate>$pubDateStr</pubDate>
    </item>
  </channel>
</rss>''';

    try {
      final feed = _parser.parse(rssXml);
      final parsedDate = feed.items.first.pubDate;

      if (parsedDate == null) {
        return ValidationResult(
          input: pubDateStr,
          success: false,
          error: '解析失敗 - 返回 null',
        );
      }

      final timezoneInfo = _analyzeTimezone(pubDateStr);
      final expectedUtc = _calculateExpectedUtc(pubDateStr, timezoneInfo);

      final isCorrect = expectedUtc != null &&
          parsedDate.difference(expectedUtc).inMilliseconds.abs() < 1000;

      return ValidationResult(
        input: pubDateStr,
        parsed: parsedDate,
        expected: expectedUtc,
        success: isCorrect,
        timezoneInfo: timezoneInfo,
        error: isCorrect ? null : '時區轉換錯誤',
      );
    } catch (e) {
      return ValidationResult(
        input: pubDateStr,
        success: false,
        error: '解析異常: $e',
      );
    }
  }

  /// 批量驗證多個時間字串
  List<ValidationResult> validateBatch(List<String> pubDateStrings) {
    return pubDateStrings.map((str) => validate(str)).toList();
  }

  /// 將 UTC 時間轉換到指定時區
  DateTime? convertToTimezone(DateTime utcTime, String targetTimezone) {
    if (!utcTime.isUtc) {
      return null;
    }

    final offsetMinutes = _getTimezoneOffsetMinutes(targetTimezone);
    if (offsetMinutes == null) {
      return null;
    }

    return utcTime.add(Duration(minutes: offsetMinutes));
  }

  /// 獲取時區偏移量（分鐘）
  int? _getTimezoneOffsetMinutes(String timezone) {
    // 數字時區格式：+0800, -0500 等
    final numericPattern = RegExp(r'^([+-])(\d{2})(\d{2})$');
    final numericMatch = numericPattern.firstMatch(timezone);

    if (numericMatch != null) {
      final sign = numericMatch.group(1)!;
      final hours = int.parse(numericMatch.group(2)!);
      final minutes = int.parse(numericMatch.group(3)!);
      return (sign == '+' ? 1 : -1) * (hours * 60 + minutes);
    }

    // 文字時區格式
    const timezoneOffsets = {
      'GMT': 0,
      'UTC': 0,
      'EST': -300,
      'EDT': -240,
      'CST': -360,
      'CDT': -300,
      'MST': -420,
      'MDT': -360,
      'PST': -480,
      'PDT': -420,
      'BST': 60,
      'CET': 60,
      'CEST': 120,
      'JST': 540,
      'KST': 540,
    };

    return timezoneOffsets[timezone.toUpperCase()];
  }

  /// 分析時區信息
  TimezoneInfo _analyzeTimezone(String pubDateStr) {
    final numericPattern = RegExp(r'([+-])(\d{2})(\d{2})\s*$');
    final numericMatch = numericPattern.firstMatch(pubDateStr);

    if (numericMatch != null) {
      final sign = numericMatch.group(1)!;
      final hours = int.parse(numericMatch.group(2)!);
      final minutes = int.parse(numericMatch.group(3)!);
      final offsetMinutes = (sign == '+' ? 1 : -1) * (hours * 60 + minutes);

      return TimezoneInfo(
        original: numericMatch.group(0)!.trim(),
        type: 'numeric',
        offsetMinutes: offsetMinutes,
        description:
            'UTC$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}',
      );
    }

    final textPattern = RegExp(r'\b([A-Z]{3,4})\s*$');
    final textMatch = textPattern.firstMatch(pubDateStr);

    if (textMatch != null) {
      final timezone = textMatch.group(1)!;
      final offsetMinutes = _getTimezoneOffset(timezone);

      return TimezoneInfo(
        original: timezone,
        type: 'text',
        offsetMinutes: offsetMinutes,
        description: '$timezone (UTC${_formatOffset(offsetMinutes)})',
      );
    }

    return TimezoneInfo(
      original: '未知',
      type: 'unknown',
      offsetMinutes: 0,
      description: '無法識別時區',
    );
  }

  /// 計算預期的 UTC 時間
  DateTime? _calculateExpectedUtc(
      String pubDateStr, TimezoneInfo timezoneInfo) {
    try {
      final pattern = RegExp(
          r'(\w+,\s+)?(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})');
      final match = pattern.firstMatch(pubDateStr);

      if (match == null) {
        return null;
      }

      final day = int.parse(match.group(2)!);
      final monthStr = match.group(3)!;
      final year = int.parse(match.group(4)!);
      final hour = int.parse(match.group(5)!);
      final minute = int.parse(match.group(6)!);
      final second = int.parse(match.group(7)!);

      final month = _parseMonth(monthStr);
      if (month == null) {
        return null;
      }

      final localTime = DateTime(year, month, day, hour, minute, second);
      final utcTime =
          localTime.subtract(Duration(minutes: timezoneInfo.offsetMinutes));
      return DateTime.utc(utcTime.year, utcTime.month, utcTime.day,
          utcTime.hour, utcTime.minute, utcTime.second);
    } catch (e) {
      return null;
    }
  }

  /// 解析月份
  int? _parseMonth(String monthStr) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return months[monthStr];
  }

  /// 獲取文字時區的偏移量 (分鐘)
  int _getTimezoneOffset(String timezone) {
    const timezoneOffsets = {
      'GMT': 0,
      'UTC': 0,
      'EST': -300,
      'EDT': -240,
      'CST': -360,
      'CDT': -300,
      'MST': -420,
      'MDT': -360,
      'PST': -480,
      'PDT': -420,
      'BST': 60,
      'CET': 60,
      'CEST': 120,
      'JST': 540,
      'KST': 540,
    };
    return timezoneOffsets[timezone] ?? 0;
  }

  /// 格式化時區偏移量為字串
  String _formatOffset(int offsetMinutes) {
    if (offsetMinutes == 0) {
      return '';
    }

    final sign = offsetMinutes > 0 ? '+' : '-';
    final absMinutes = offsetMinutes.abs();
    final hours = absMinutes ~/ 60;
    final minutes = absMinutes % 60;

    return '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

/// 時區信息
class TimezoneInfo {
  final String original;
  final String type;
  final int offsetMinutes;
  final String description;

  TimezoneInfo({
    required this.original,
    required this.type,
    required this.offsetMinutes,
    required this.description,
  });
}

/// 驗證結果
class ValidationResult {
  final String input;
  final DateTime? parsed;
  final DateTime? expected;
  final bool success;
  final TimezoneInfo? timezoneInfo;
  final String? error;

  ValidationResult({
    required this.input,
    this.parsed,
    this.expected,
    required this.success,
    this.timezoneInfo,
    this.error,
  });

  @override
  String toString() {
    final buffer = StringBuffer()..writeln('🔍 輸入: $input');

    if (timezoneInfo != null) {
      buffer.writeln(
          '⏰ 時區: ${timezoneInfo!.original} (${timezoneInfo!.description})');
    }

    if (parsed != null) {
      buffer.writeln('📊 解析結果: $parsed (${parsed!.isUtc ? 'UTC' : 'Local'})');
    }

    if (expected != null) {
      buffer.writeln('✅ 預期結果: $expected UTC');
    }

    buffer.writeln('${success ? '✅' : '❌'} 狀態: ${success ? '正確' : '錯誤'}');

    if (error != null) {
      buffer.writeln('❗ 錯誤: $error');
    }

    if (parsed != null && expected != null) {
      final diff = parsed!.difference(expected!);
      buffer.writeln('⏱️  時差: ${diff.inHours} 小時 ${diff.inMinutes % 60} 分鐘');
    }

    return buffer.toString();
  }
}
