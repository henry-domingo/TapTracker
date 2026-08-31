import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tap_tracker/core/pdf_statement_parser.dart';

void main() {
  const parser = PdfStatementParser();

  test('parses primary SOA fields', () {
    const raw = '''
      BDO Credit Card Statement
      Statement Date: 08/01/2026
      Due Date: 08/21/2026
      Total Amount Due: PHP 18,000.00
      Minimum Amount Due: PHP 1,800.00
      08/02 Grab
      08/03 Lazada
    ''';

    final result = parser.parse(latin1.encode(raw));

    expect(result, isNotNull);
    expect(result!.usedFallback, isFalse);
    expect(result.summary.bankDetected, 'BDO');
    expect(result.summary.totalAmountDue, 18000);
    expect(result.summary.minimumDue, 1800);
  });

  test('uses fallback parsing when labels are missing', () {
    const raw = '''
      08/01/2026 08/21/2026
      PHP 8,250.50
      PHP 1,200.00
    ''';

    final result = parser.parse(latin1.encode(raw));

    expect(result, isNotNull);
    expect(result!.usedFallback, isTrue);
    expect(result.summary.totalAmountDue, 8250.50);
    expect(result.summary.minimumDue, 1200);
  });
}
