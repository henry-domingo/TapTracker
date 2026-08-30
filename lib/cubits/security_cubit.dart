import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/entities.dart';
import '../repositories/app_repositories.dart';

class SecurityState extends Equatable {
  const SecurityState({
    this.pinEnabled = false,
    this.biometricEnabled = false,
    this.autoLockTimeout = AutoLockTimeout.immediate,
    this.savedPdfPasswordBanks = const [],
  });

  final bool pinEnabled;
  final bool biometricEnabled;
  final AutoLockTimeout autoLockTimeout;
  final List<String> savedPdfPasswordBanks;

  SecurityState copyWith({
    bool? pinEnabled,
    bool? biometricEnabled,
    AutoLockTimeout? autoLockTimeout,
    List<String>? savedPdfPasswordBanks,
  }) {
    return SecurityState(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      savedPdfPasswordBanks: savedPdfPasswordBanks ?? this.savedPdfPasswordBanks,
    );
  }

  @override
  List<Object?> get props => [
        pinEnabled,
        biometricEnabled,
        autoLockTimeout,
        savedPdfPasswordBanks,
      ];
}

class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit(this._repository) : super(const SecurityState());

  final SecureSettingsRepository _repository;

  Future<void> load() async {
    final timeout = await _repository.getAutoLockTimeout();
    final passwords = await _repository.getSavedBankPdfPasswords();
    emit(
      state.copyWith(
        autoLockTimeout: timeout,
        savedPdfPasswordBanks: passwords.keys.toList()..sort(),
      ),
    );
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
    final updated = [...state.savedPdfPasswordBanks];
    if (!updated.contains(bank)) {
      updated.add(bank);
      updated.sort();
      emit(state.copyWith(savedPdfPasswordBanks: updated));
    }
  }

  Future<void> deletePdfPassword(String bank) async {
    await _repository.deleteBankPdfPassword(bank);
    final updated = [...state.savedPdfPasswordBanks]..remove(bank);
    emit(state.copyWith(savedPdfPasswordBanks: updated));
  }
}
