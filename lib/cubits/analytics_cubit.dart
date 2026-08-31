import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/entities.dart';

class AnalyticsState extends Equatable {
  const AnalyticsState({
    this.aggregateUtilization = 0,
    this.perCardUtilization = const {},
    this.categoryTotals = const {},
    this.topMerchants = const {},
    this.insights = const [],
  });

  final double aggregateUtilization;
  final Map<String, double> perCardUtilization;
  final Map<String, double> categoryTotals;
  final Map<String, double> topMerchants;
  final List<String> insights;

  @override
  List<Object?> get props => [
        aggregateUtilization,
        perCardUtilization,
        categoryTotals,
        topMerchants,
        insights,
      ];
}

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit() : super(const AnalyticsState());

  void compute({
    required List<CardProfile> cards,
    required List<TransactionRecord> transactions,
  }) {
    final activeCards = cards.where((card) => !card.isArchived).toList();
    final usableTransactions =
        transactions.where((tx) => !tx.excludeFromAnalytics).toList();

    final totalLimit = activeCards.fold<double>(0, (sum, card) => sum + card.creditLimit);
    final totalSpend = usableTransactions.fold<double>(0, (sum, tx) => sum + tx.amount);

    final perCard = <String, double>{};
    for (final card in activeCards) {
      final spend = usableTransactions
          .where((tx) => tx.cardId == card.id)
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      perCard[card.nickname] = card.creditLimit == 0 ? 0 : (spend / card.creditLimit) * 100;
    }

    final categories = <String, double>{};
    for (final tx in usableTransactions) {
      categories[tx.category] = (categories[tx.category] ?? 0) + tx.amount;
    }

    final merchants = <String, double>{};
    for (final tx in usableTransactions) {
      merchants[tx.merchant] = (merchants[tx.merchant] ?? 0) + tx.amount;
    }
    final sortedMerchants = Map.fromEntries(
      merchants.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    final insights = <String>[];
    for (final entry in perCard.entries) {
      if (entry.value > 80) {
        insights.add('${entry.key} utilization is critical (${entry.value.toStringAsFixed(1)}%).');
      } else if (entry.value > 50) {
        insights.add('${entry.key} utilization is high (${entry.value.toStringAsFixed(1)}%).');
      }
    }

    emit(
      AnalyticsState(
        aggregateUtilization: totalLimit == 0 ? 0 : (totalSpend / totalLimit) * 100,
        perCardUtilization: perCard,
        categoryTotals: categories,
        topMerchants: sortedMerchants,
        insights: insights,
      ),
    );
  }
}
