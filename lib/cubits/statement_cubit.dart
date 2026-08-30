import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/entities.dart';
import '../repositories/app_repositories.dart';

class StatementState extends Equatable {
  const StatementState({
    this.statements = const [],
    this.transactions = const [],
    this.parseSummary,
    this.query = '',
    this.selectedCardId,
    this.selectedCategory,
  });

  final List<StatementRecord> statements;
  final List<TransactionRecord> transactions;
  final ParseSummary? parseSummary;
  final String query;
  final String? selectedCardId;
  final String? selectedCategory;

  List<TransactionRecord> get filteredTransactions {
    return transactions.where((tx) {
      final queryOk = query.isEmpty ||
          tx.merchant.toLowerCase().contains(query.toLowerCase()) ||
          tx.category.toLowerCase().contains(query.toLowerCase());
      final cardOk = selectedCardId == null || tx.cardId == selectedCardId;
      final categoryOk = selectedCategory == null || tx.category == selectedCategory;
      return queryOk && cardOk && categoryOk;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  StatementState copyWith({
    List<StatementRecord>? statements,
    List<TransactionRecord>? transactions,
    ParseSummary? parseSummary,
    String? query,
    String? selectedCardId,
    String? selectedCategory,
  }) {
    return StatementState(
      statements: statements ?? this.statements,
      transactions: transactions ?? this.transactions,
      parseSummary: parseSummary ?? this.parseSummary,
      query: query ?? this.query,
      selectedCardId: selectedCardId ?? this.selectedCardId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  @override
  List<Object?> get props => [
        statements,
        transactions,
        parseSummary,
        query,
        selectedCardId,
        selectedCategory,
      ];
}

class StatementCubit extends Cubit<StatementState> {
  StatementCubit(this._repository) : super(const StatementState());

  final LocalDataRepository _repository;

  void load() {
    emit(state.copyWith(
      statements: _repository.getStatements(),
      transactions: _repository.getTransactions(),
    ));
  }

  void setParseSummary(ParseSummary summary) {
    emit(state.copyWith(parseSummary: summary));
  }

  void saveCorrectedParseSummary(String cardId) {
    final summary = state.parseSummary;
    if (summary == null) {
      return;
    }
    _repository.addStatement(
      StatementRecord(
        id: _repository.newId(),
        cardId: cardId,
        statementDate: summary.statementDate,
        dueDate: summary.dueDate,
        totalAmountDue: summary.totalAmountDue,
        minimumDue: summary.minimumDue,
        transactionCount: summary.transactionCount,
      ),
    );
    load();
  }

  void deleteStatement(String statementId) {
    _repository.deleteStatement(statementId);
    load();
  }

  void recordPayment(
    String statementId, {
    required double paidAmount,
    required DateTime paymentDate,
    required String reference,
  }) {
    final statement = _repository
        .getStatements()
        .firstWhere((item) => item.id == statementId)
        .copyWith(
          isPaid: true,
          paidAmount: paidAmount,
          paymentDate: paymentDate,
          paymentReference: reference,
        );
    _repository.updateStatement(statement);
    load();
  }

  void addManualTransaction({
    required String cardId,
    required String merchant,
    required String category,
    required DateTime date,
    required double amount,
  }) {
    _repository.addOrUpdateTransaction(
      TransactionRecord(
        id: _repository.newId(),
        cardId: cardId,
        merchant: merchant,
        category: category,
        date: date,
        amount: amount,
      ),
    );
    load();
  }

  void updateTransaction(TransactionRecord transaction) {
    _repository.addOrUpdateTransaction(transaction);
    load();
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(query: query));
  }

  void setCardFilter(String? cardId) {
    emit(
      StatementState(
        statements: state.statements,
        transactions: state.transactions,
        parseSummary: state.parseSummary,
        query: state.query,
        selectedCardId: cardId,
        selectedCategory: state.selectedCategory,
      ),
    );
  }

  void setCategoryFilter(String? category) {
    emit(
      StatementState(
        statements: state.statements,
        transactions: state.transactions,
        parseSummary: state.parseSummary,
        query: state.query,
        selectedCardId: state.selectedCardId,
        selectedCategory: category,
      ),
    );
  }
}
