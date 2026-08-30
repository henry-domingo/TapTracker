import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/entities.dart';
import '../repositories/app_repositories.dart';

class SecurityState extends Equatable {
  const SecurityState({
    this.pinEnabled = false,
    this.biometricEnabled = false,
    this.autoLockTimeout = AutoLockTimeout.immediate,
    this.savedPdfPasswords = const {},
  });

  final bool pinEnabled;
  final bool biometricEnabled;
  final AutoLockTimeout autoLockTimeout;
  final Map<String, String> savedPdfPasswords;

  SecurityState copyWith({
    bool? pinEnabled,
    bool? biometricEnabled,
    AutoLockTimeout? autoLockTimeout,
    Map<String, String>? savedPdfPasswords,
  }) {
    return SecurityState(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      savedPdfPasswords: savedPdfPasswords ?? this.savedPdfPasswords,
    );
  }

  @override
  List<Object?> get props => [
        pinEnabled,
        biometricEnabled,
        autoLockTimeout,
        savedPdfPasswords,
      ];
}

class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit(this._repository) : super(const SecurityState());

  final SecureSettingsRepository _repository;

  Future<void> load() async {
    final timeout = await _repository.getAutoLockTimeout();
    final passwords = await _repository.getSavedBankPdfPasswords();
    emit(state.copyWith(autoLockTimeout: timeout, savedPdfPasswords: passwords));
  }

  void setPinEnabled(bool enabled) {
    emit(state.copyWith(pinEnabled: enabled));
  }

  void setBiometricEnabled(bool enabled) {
    emit(state.copyWith(biometricEnabled: enabled));
  }

  Future<void> setAutoLockTimeout(AutoLockTimeout timeout) async {
    await _repository.saveAutoLockTimeout(timeout);
    emit(state.copyWith(autoLockTimeout: timeout));
  }

  Future<void> savePdfPassword(String bank, String password) async {
    await _repository.saveBankPdfPassword(bank, password);
    final updated = Map<String, String>.from(state.savedPdfPasswords)
      ..[bank] = password;
    emit(state.copyWith(savedPdfPasswords: updated));
  }

  Future<void> deletePdfPassword(String bank) async {
    await _repository.deleteBankPdfPassword(bank);
    final updated = Map<String, String>.from(state.savedPdfPasswords)
      ..remove(bank);
    emit(state.copyWith(savedPdfPasswords: updated));
  }
}
