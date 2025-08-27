import 'package:rss_agent/src/parsers/rss2_parser.dart';

/// 時間轉換驗證工具
/// 用於測試 RSS pubDate 的時區解析是否正確
class TimezoneValidator {
  final Rss2Parser _parser = Rss2Parser();

  /// 驗證單一時間字串的解析結果
  ValidationResult validate(String pubDateStr, {String? expectedTimezone}) {
    // 創建測試用的 RSS XML
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

      // 分析時區信息
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

  /// 分析時區信息
  TimezoneInfo _analyzeTimezone(String pubDateStr) {
    // 匹配數字時區格式：+0800, -0500, +0930 等
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

    // 匹配文字時區格式：GMT, UTC, EST 等
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
      // 解析基本時間部分 (忽略時區)
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

      // 創建本地時間，然後根據時區偏移量轉為 UTC
      final localTime = DateTime(year, month, day, hour, minute, second);
      final utcTime =
          localTime.subtract(Duration(minutes: timezoneInfo.offsetMinutes));
      // 確保返回 UTC 時間
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
      'GMT': 0, 'UTC': 0,
      'EST': -300, 'EDT': -240, // 美東標準/夏令時間
      'CST': -360, 'CDT': -300, // 美中標準/夏令時間 (注意：CST 在不同地區有不同含義)
      'MST': -420, 'MDT': -360, // 美山標準/夏令時間
      'PST': -480, 'PDT': -420, // 美西標準/夏令時間
      'BST': 60, // 英國夏令時間
      'CET': 60, 'CEST': 120, // 中歐標準/夏令時間
      'JST': 540, // 日本標準時間
      'KST': 540, // 韓國標準時間
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
  final String original; // 原始時區字串
  final String type; // 時區類型：numeric, text, unknown
  final int offsetMinutes; // UTC 偏移量 (分鐘)
  final String description; // 描述

  TimezoneInfo({
    required this.original,
    required this.type,
    required this.offsetMinutes,
    required this.description,
  });
}

/// 驗證結果
class ValidationResult {
  final String input; // 輸入字串
  final DateTime? parsed; // 解析結果
  final DateTime? expected; // 預期結果
  final bool success; // 是否成功
  final TimezoneInfo? timezoneInfo; // 時區信息
  final String? error; // 錯誤信息

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

/// 命令行工具主函數
void main(List<String> args) {
  final validator = TimezoneValidator();

  if (args.isEmpty) {
    // 預設測試案例
    final testCases = [
      'Thu, 28 Aug 2025 00:46:04 +0800', // 台北時間
      'Wed, 27 Aug 2025 12:00:00 -0500', // 美東時間
      'Thu, 28 Aug 2025 10:30:00 +0930', // 澳洲阿德雷德時間
      'Wed, 27 Aug 2025 15:30:00 GMT', // GMT
      'Wed, 27 Aug 2025 20:15:00 UTC', // UTC
      'Fri, 29 Aug 2025 14:22:33 EST', // 美東標準時間
      'Sat, 30 Aug 2025 09:15:00 JST', // 日本標準時間
    ];

    print('=== RSS pubDate 時區解析驗證工具 ===\n');
    print('📋 運行預設測試案例...\n');

    for (var i = 0; i < testCases.length; i++) {
      print('--- 測試案例 ${i + 1} ---');
      final result = validator.validate(testCases[i]);
      print(result);
      print('');
    }

    // 統計
    final results = validator.validateBatch(testCases);
    final successCount = results.where((r) => r.success).length;
    final totalCount = results.length;

    print('=== 統計結果 ===');
    print('✅ 正確: $successCount');
    print('❌ 錯誤: ${totalCount - successCount}');
    print('📈 正確率: ${(successCount / totalCount * 100).toStringAsFixed(1)}%');

    if (successCount < totalCount) {
      print('\n⚠️  發現時區解析問題！建議修復 RFC 2822 解析器。');
    }
  } else {
    // 驗證用戶提供的時間字串
    print('=== RSS pubDate 時區解析驗證工具 ===\n');

    for (final dateStr in args) {
      print('--- 驗證: $dateStr ---');
      final result = validator.validate(dateStr);
      print(result);
      print('');
    }
  }
}
