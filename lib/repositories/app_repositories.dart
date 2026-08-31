import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/entities.dart';

class SecureSettingsRepository {
  SecureSettingsRepository({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  Future<void> saveBankPdfPassword(String bank, String password) async {
    await _secureStorage.write(key: 'pdf_password_$bank', value: password);
  }

  Future<void> deleteBankPdfPassword(String bank) async {
    await _secureStorage.delete(key: 'pdf_password_$bank');
  }

  Future<Map<String, String>> getSavedBankPdfPasswords() async {
    final all = await _secureStorage.readAll();
    return {
      for (final entry in all.entries)
        if (entry.key.startsWith('pdf_password_'))
          entry.key.replaceFirst('pdf_password_', ''): entry.value,
    };
  }

  Future<String?> getBankPdfPassword(String bank) async {
    return _secureStorage.read(key: 'pdf_password_$bank');
  }

  Future<void> saveAutoLockTimeout(AutoLockTimeout timeout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auto_lock_timeout', timeout.name);
  }

  Future<AutoLockTimeout> getAutoLockTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('auto_lock_timeout');
    return AutoLockTimeout.values.firstWhere(
      (item) => item.name == raw,
      orElse: () => AutoLockTimeout.immediate,
    );
  }

  Future<void> savePinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pin_enabled', enabled);
  }

  Future<bool> getPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('pin_enabled') ?? false;
  }

  Future<void> saveBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
  }

  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }
}

class LocalDataRepository {
  static final Random _random = Random.secure();
  final List<CardProfile> _cards = [];
  final List<StatementRecord> _statements = [];
  final List<TransactionRecord> _transactions = [];

  List<CardProfile> getCards() => List.unmodifiable(_cards);
  List<StatementRecord> getStatements() => List.unmodifiable(_statements);
  List<TransactionRecord> getTransactions() => List.unmodifiable(_transactions);

  void addOrUpdateCard(CardProfile card) {
    final existing = _cards.indexWhere((item) => item.id == card.id);
    if (existing == -1) {
      _cards.add(card);
    } else {
      _cards[existing] = card;
    }
  }

  void deleteCard(String cardId) {
    _cards.removeWhere((card) => card.id == cardId);
    final statementIds = _statements
        .where((statement) => statement.cardId == cardId)
        .map((statement) => statement.id)
        .toSet();
    _statements.removeWhere((statement) => statement.cardId == cardId);
    _transactions.removeWhere(
      (transaction) =>
          transaction.cardId == cardId ||
          (transaction.statementId != null &&
              statementIds.contains(transaction.statementId)),
    );
  }

  void addStatement(StatementRecord statement) {
    _statements.add(statement);
  }

  void updateStatement(StatementRecord statement) {
    final idx = _statements.indexWhere((item) => item.id == statement.id);
    if (idx != -1) {
      _statements[idx] = statement;
    }
  }

  void deleteStatement(String statementId) {
    _statements.removeWhere((statement) => statement.id == statementId);
    _transactions.removeWhere((tx) => tx.statementId == statementId);
  }

  void addOrUpdateTransaction(TransactionRecord transaction) {
    final idx = _transactions.indexWhere((item) => item.id == transaction.id);
    if (idx == -1) {
      _transactions.add(transaction);
    } else {
      _transactions[idx] = transaction;
    }
  }

  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(1 << 32).toRadixString(16)}';
}
