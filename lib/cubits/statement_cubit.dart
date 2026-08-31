import 'dart:io';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

import '../core/pdf_statement_parser.dart';
import '../models/entities.dart';
import '../repositories/app_repositories.dart';

enum ImportStatus { idle, importing, success, failed }

class StatementState extends Equatable {
  static const Object _unset = Object();

  const StatementState({
    this.statements = const [],
    this.transactions = const [],
    this.parseSummary,
    this.query = '',
    this.selectedCardId,
    this.selectedCategory,
    this.importStatus = ImportStatus.idle,
    this.importedFileName,
    this.importError,
    this.usedFallbackParser = false,
  });

  final List<StatementRecord> statements;
  final List<TransactionRecord> transactions;
  final ParseSummary? parseSummary;
  final String query;
  final String? selectedCardId;
  final String? selectedCategory;
  final ImportStatus importStatus;
  final String? importedFileName;
  final String? importError;
  final bool usedFallbackParser;

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
    Object? parseSummary = _unset,
    String? query,
    Object? selectedCardId = _unset,
    Object? selectedCategory = _unset,
    ImportStatus? importStatus,
    Object? importedFileName = _unset,
    Object? importError = _unset,
    bool? usedFallbackParser,
  }) {
    return StatementState(
      statements: statements ?? this.statements,
      transactions: transactions ?? this.transactions,
      parseSummary: parseSummary == _unset ? this.parseSummary : parseSummary as ParseSummary?,
      query: query ?? this.query,
      selectedCardId:
          selectedCardId == _unset ? this.selectedCardId : selectedCardId as String?,
      selectedCategory:
          selectedCategory == _unset ? this.selectedCategory : selectedCategory as String?,
      importStatus: importStatus ?? this.importStatus,
      importedFileName:
          importedFileName == _unset ? this.importedFileName : importedFileName as String?,
      importError: importError == _unset ? this.importError : importError as String?,
      usedFallbackParser: usedFallbackParser ?? this.usedFallbackParser,
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
        importStatus,
        importedFileName,
        importError,
        usedFallbackParser,
      ];
}

class StatementCubit extends Cubit<StatementState> {
  StatementCubit(
    this._repository, {
    PdfStatementParser parser = const PdfStatementParser(),
  })  : _parser = parser,
        super(const StatementState());

  final LocalDataRepository _repository;
  final PdfStatementParser _parser;

  void load() {
    emit(state.copyWith(
      statements: _repository.getStatements(),
      transactions: _repository.getTransactions(),
    ));
  }

  void setParseSummary(ParseSummary summary) {
    emit(
      state.copyWith(
        parseSummary: summary,
        importStatus: ImportStatus.success,
        importError: null,
      ),
    );
  }

  Future<void> importPdf({
    String? bankName,
    String? password,
    bool rememberPassword = false,
    Future<void> Function(String bank, String password)? onRememberPassword,
  }) async {
    emit(
      state.copyWith(
        importStatus: ImportStatus.importing,
        importError: null,
        usedFallbackParser: false,
      ),
    );

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      emit(
        state.copyWith(
          importStatus: ImportStatus.idle,
          importError: null,
        ),
      );
      return;
    }

    final file = result.files.single;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) {
      emit(
        state.copyWith(
          importStatus: ImportStatus.failed,
          importError: 'Unable to read selected PDF.',
          importedFileName: file.name,
        ),
      );
      return;
    }

    final parsed = _parser.parse(bytes, password: password);
    if (parsed == null) {
      emit(
        state.copyWith(
          importStatus: ImportStatus.failed,
          importError: 'Unable to parse PDF. Please verify password or edit values manually.',
          importedFileName: file.name,
        ),
      );
      return;
    }

    if (bankName != null && bankName.isNotEmpty && rememberPassword && password != null) {
      await onRememberPassword?.call(bankName, password);
    }

    emit(
      state.copyWith(
        parseSummary: parsed.summary.copyWith(
          bankDetected: bankName == null || bankName.isEmpty ? parsed.summary.bankDetected : bankName,
        ),
        importStatus: ImportStatus.success,
        importedFileName: file.name,
        importError: null,
        usedFallbackParser: parsed.usedFallback,
      ),
    );
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
    emit(state.copyWith(selectedCardId: cardId));
  }

  void setCategoryFilter(String? category) {
    emit(state.copyWith(selectedCategory: category));
  }
}
