import 'package:equatable/equatable.dart';

enum CardNetwork { visa, mastercard, jcb, amex }

enum AutoLockTimeout { immediate, oneMinute, fiveMinutes }

class CardProfile extends Equatable {
  const CardProfile({
    required this.id,
    required this.bankName,
    required this.nickname,
    required this.network,
    required this.creditLimit,
    required this.statementDay,
    required this.dueDay,
    required this.colorHex,
    this.isArchived = false,
  });

  final String id;
  final String bankName;
  final String nickname;
  final CardNetwork network;
  final double creditLimit;
  final int statementDay;
  final int dueDay;
  final String colorHex;
  final bool isArchived;

  CardProfile copyWith({
    String? bankName,
    String? nickname,
    CardNetwork? network,
    double? creditLimit,
    int? statementDay,
    int? dueDay,
    String? colorHex,
    bool? isArchived,
  }) {
    return CardProfile(
      id: id,
      bankName: bankName ?? this.bankName,
      nickname: nickname ?? this.nickname,
      network: network ?? this.network,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      colorHex: colorHex ?? this.colorHex,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bankName,
        nickname,
        network,
        creditLimit,
        statementDay,
        dueDay,
        colorHex,
        isArchived,
      ];
}

class StatementRecord extends Equatable {
  const StatementRecord({
    required this.id,
    required this.cardId,
    required this.statementDate,
    required this.dueDate,
    required this.totalAmountDue,
    required this.minimumDue,
    required this.transactionCount,
    this.isPaid = false,
    this.paidAmount = 0,
    this.paymentDate,
    this.paymentReference,
  });

  final String id;
  final String cardId;
  final DateTime statementDate;
  final DateTime dueDate;
  final double totalAmountDue;
  final double minimumDue;
  final int transactionCount;
  final bool isPaid;
  final double paidAmount;
  final DateTime? paymentDate;
  final String? paymentReference;

  StatementRecord copyWith({
    DateTime? statementDate,
    DateTime? dueDate,
    double? totalAmountDue,
    double? minimumDue,
    int? transactionCount,
    bool? isPaid,
    double? paidAmount,
    DateTime? paymentDate,
    String? paymentReference,
  }) {
    return StatementRecord(
      id: id,
      cardId: cardId,
      statementDate: statementDate ?? this.statementDate,
      dueDate: dueDate ?? this.dueDate,
      totalAmountDue: totalAmountDue ?? this.totalAmountDue,
      minimumDue: minimumDue ?? this.minimumDue,
      transactionCount: transactionCount ?? this.transactionCount,
      isPaid: isPaid ?? this.isPaid,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentReference: paymentReference ?? this.paymentReference,
    );
  }

  @override
  List<Object?> get props => [
        id,
        cardId,
        statementDate,
        dueDate,
        totalAmountDue,
        minimumDue,
        transactionCount,
        isPaid,
        paidAmount,
        paymentDate,
        paymentReference,
      ];
}

class TransactionRecord extends Equatable {
  const TransactionRecord({
    required this.id,
    required this.cardId,
    required this.merchant,
    required this.category,
    required this.date,
    required this.amount,
    this.statementId,
    this.isInstallment = false,
    this.excludeFromAnalytics = false,
  });

  final String id;
  final String cardId;
  final String merchant;
  final String category;
  final DateTime date;
  final double amount;
  final String? statementId;
  final bool isInstallment;
  final bool excludeFromAnalytics;

  TransactionRecord copyWith({
    String? merchant,
    String? category,
    DateTime? date,
    double? amount,
    bool? isInstallment,
    bool? excludeFromAnalytics,
  }) {
    return TransactionRecord(
      id: id,
      cardId: cardId,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      statementId: statementId,
      isInstallment: isInstallment ?? this.isInstallment,
      excludeFromAnalytics: excludeFromAnalytics ?? this.excludeFromAnalytics,
    );
  }

  @override
  List<Object?> get props => [
        id,
        cardId,
        merchant,
        category,
        date,
        amount,
        statementId,
        isInstallment,
        excludeFromAnalytics,
      ];
}

class ParseSummary extends Equatable {
  const ParseSummary({
    required this.bankDetected,
    required this.statementDate,
    required this.dueDate,
    required this.totalAmountDue,
    required this.minimumDue,
    required this.transactionCount,
  });

  final String bankDetected;
  final DateTime statementDate;
  final DateTime dueDate;
  final double totalAmountDue;
  final double minimumDue;
  final int transactionCount;

  ParseSummary copyWith({
    String? bankDetected,
    DateTime? statementDate,
    DateTime? dueDate,
    double? totalAmountDue,
    double? minimumDue,
    int? transactionCount,
  }) {
    return ParseSummary(
      bankDetected: bankDetected ?? this.bankDetected,
      statementDate: statementDate ?? this.statementDate,
      dueDate: dueDate ?? this.dueDate,
      totalAmountDue: totalAmountDue ?? this.totalAmountDue,
      minimumDue: minimumDue ?? this.minimumDue,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }

  @override
  List<Object?> get props => [
        bankDetected,
        statementDate,
        dueDate,
        totalAmountDue,
        minimumDue,
        transactionCount,
      ];
}
