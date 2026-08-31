import 'dart:convert';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'philippine_banks.dart';
import '../models/entities.dart';

class ParsedStatementResult {
  const ParsedStatementResult({
    required this.summary,
    required this.usedFallback,
  });

  final ParseSummary summary;
  final bool usedFallback;
}

class PdfStatementParser {
  const PdfStatementParser({List<String> banks = philippineBanks}) : _banks = banks;

  final List<String> _banks;

  ParsedStatementResult? parse(Uint8List bytes, {String? password}) {
    final text = _extractText(bytes, password: password);
    if (text.trim().isEmpty) {
      return null;
    }
    final primary = _parsePrimary(text);
    if (primary != null) {
      return ParsedStatementResult(summary: primary, usedFallback: false);
    }

    final fallback = _parseFallback(text);
    if (fallback != null) {
      return ParsedStatementResult(summary: fallback, usedFallback: true);
    }
    return ParsedStatementResult(
      summary: _buildBestEffortSummary(text),
      usedFallback: true,
    );
  }

  String _extractText(Uint8List bytes, {String? password}) {
    PdfDocument? document;
    try {
      document = (password == null || password.isEmpty)
          ? PdfDocument(inputBytes: bytes)
          : PdfDocument(inputBytes: bytes, password: password);
      final extractor = PdfTextExtractor(document);
      final output = StringBuffer();
      for (var i = 0; i < document.pages.count; i++) {
        output.writeln(
          extractor.extractText(startPageIndex: i, endPageIndex: i),
        );
      }
      return output.toString();
    } catch (_) {
      final latin = latin1.decode(bytes, allowInvalid: true);
      return latin.replaceAll(RegExp(r'[^\x09\x0A\x0D\x20-\x7E]'), ' ');
    } finally {
      document?.dispose();
    }
  }

  ParseSummary? _parsePrimary(String rawText) {
    final text = rawText.replaceAll(RegExp(r'\s+'), ' ');
    final bankPattern = _banks.map(RegExp.escape).join('|');
    final bank = _match(text, [
      RegExp('($bankPattern)', caseSensitive: false),
    ]);
    final statementDate = _parseDate(_match(text, [
      RegExp(
        r'Statement\s*Date\s*[:\-]\s*([A-Za-z]{3,9}\s+\d{1,2},\s*\d{4}|\d{2}/\d{2}/\d{4})',
        caseSensitive: false,
      ),
    ]));
    final dueDate = _parseDate(_match(text, [
      RegExp(
        r'Due\s*Date\s*[:\-]\s*([A-Za-z]{3,9}\s+\d{1,2},\s*\d{4}|\d{2}/\d{2}/\d{4})',
        caseSensitive: false,
      ),
    ]));
    final total = _parseMoney(
      _match(text, [
        RegExp(
          r'Total\s*Amount\s*Due\s*[:\-]?\s*(PHP|₱)?\s*([\d,]+(?:\.\d{2})?)',
          caseSensitive: false,
        ),
      ], group: 2),
    );
    final minimum = _parseMoney(
      _match(text, [
        RegExp(
          r'Minimum\s*Amount\s*Due\s*[:\-]?\s*(PHP|₱)?\s*([\d,]+(?:\.\d{2})?)',
          caseSensitive: false,
        ),
        RegExp(
          r'Minimum\s*Due\s*[:\-]?\s*(PHP|₱)?\s*([\d,]+(?:\.\d{2})?)',
          caseSensitive: false,
        ),
      ], group: 2),
    );

    if (statementDate == null || dueDate == null || total == null || minimum == null) {
      return null;
    }

    return ParseSummary(
      bankDetected: bank ?? 'Unknown',
      statementDate: statementDate,
      dueDate: dueDate,
      totalAmountDue: total,
      minimumDue: minimum,
      transactionCount: _estimateTransactionCount(text),
    );
  }

  ParseSummary? _parseFallback(String rawText) {
    final text = rawText.replaceAll(RegExp(r'\s+'), ' ');
    final dates = RegExp(r'(\d{2}/\d{2}/\d{4})').allMatches(text).map((m) => m.group(1)!).toList();
    if (dates.length < 2) {
      return null;
    }

    final amounts = RegExp(r'(?:PHP|₱)?\s*([\d,]+\.\d{2})')
        .allMatches(text)
        .map((m) => _parseMoney(m.group(1)))
        .whereType<double>()
        .toList();
    if (amounts.length < 2) {
      return null;
    }

    final statementDate = _parseDate(dates.first);
    final dueDate = _parseDate(dates[1]);
    if (statementDate == null || dueDate == null) {
      return null;
    }

    final firstAmount = amounts.first;
    final secondAmount = amounts[1];
    final total = firstAmount > secondAmount ? firstAmount : secondAmount;
    final minimum = firstAmount > secondAmount ? secondAmount : firstAmount;

    return ParseSummary(
      bankDetected: 'Unknown',
      statementDate: statementDate,
      dueDate: dueDate,
      totalAmountDue: total,
      minimumDue: minimum,
      transactionCount: _estimateTransactionCount(text),
    );
  }

  String? _match(String text, List<RegExp> patterns, {int group = 1}) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(group)?.trim();
      }
    }
    return null;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final slash = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);
    if (slash != null) {
      var month = int.parse(slash.group(1)!);
      var day = int.parse(slash.group(2)!);
      if (month > 12 && day <= 12) {
        final swap = month;
        month = day;
        day = swap;
      }
      final year = int.parse(slash.group(3)!);
      return DateTime(year, month, day);
    }

    final full = RegExp(r'^([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})$').firstMatch(value);
    if (full == null) {
      return null;
    }

    const fullMonthMap = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    const shortMonthMap = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final normalizedMonth = full.group(1)!.toLowerCase();
    final month = fullMonthMap[normalizedMonth] ?? shortMonthMap[normalizedMonth];
    if (month == null) {
      return null;
    }
    final day = int.parse(full.group(2)!);
    final year = int.parse(full.group(3)!);
    return DateTime(year, month, day);
  }

  double? _parseMoney(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final normalized = value
        .replaceAll(',', '')
        .replaceAll('PHP', '')
        .replaceAll('₱', '')
        .trim();
    return double.tryParse(normalized);
  }

  int _estimateTransactionCount(String text) {
    return RegExp(r'\d{2}/\d{2}\s+[A-Za-z0-9]').allMatches(text).length;
  }

  ParseSummary _buildBestEffortSummary(String text) {
    final parsedDates = RegExp(
      r'(\d{2}/\d{2}/\d{4}|[A-Za-z]{3,9}\s+\d{1,2},\s*\d{4})',
      caseSensitive: false,
    )
        .allMatches(text)
        .map((m) => _parseDate(m.group(1)))
        .whereType<DateTime>()
        .toList();

    final parsedAmounts = RegExp(r'(?:PHP|₱)\s*([\d,]+(?:\.\d{2})?)')
        .allMatches(text)
        .map((m) => _parseMoney(m.group(1)))
        .whereType<double>()
        .toList();

    final statementDate = parsedDates.isNotEmpty ? parsedDates.first : DateTime.now();
    final dueDate = parsedDates.length > 1
        ? parsedDates[1]
        : statementDate.add(const Duration(days: 20));

    final explicitTotal = _parseMoney(
      _match(text, [
        RegExp(
          r'(?:Total|Total\s*Amount)\s*(?:Amount\s*Due|Due)?\s*[:\-]?\s*(?:PHP|₱)?\s*([\d,]+(?:\.\d{2})?)',
          caseSensitive: false,
        ),
      ]),
    );
    final total = explicitTotal ??
        (parsedAmounts.isEmpty
            ? 0.0
            : parsedAmounts.reduce((a, b) => a > b ? a : b));
    final explicitMinimum = _parseMoney(
      _match(text, [
        RegExp(
          r'(?:Minimum|Min\.?)\s*(?:Amount\s*Due|Due)?\s*[:\-]?\s*(?:PHP|₱)?\s*([\d,]+(?:\.\d{2})?)',
          caseSensitive: false,
        ),
      ]),
    );
    final minimum = explicitMinimum ??
        (parsedAmounts.isEmpty
            ? 0.0
            : parsedAmounts.reduce((a, b) => a < b ? a : b));

    final bankPattern = _banks.map(RegExp.escape).join('|');
    final bank = _match(text, [RegExp('($bankPattern)', caseSensitive: false)]);

    return ParseSummary(
      bankDetected: bank ?? 'Unknown',
      statementDate: statementDate,
      dueDate: dueDate,
      totalAmountDue: total,
      minimumDue: minimum,
      transactionCount: _estimateTransactionCount(text),
    );
  }
}
