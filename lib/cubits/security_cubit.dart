import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:local_auth/local_auth.dart';

import '../models/entities.dart';
import '../repositories/app_repositories.dart';

class SecurityState extends Equatable {
  const SecurityState({
    this.pinEnabled = false,
    this.biometricEnabled = false,
    this.autoLockTimeout = AutoLockTimeout.immediate,
    this.savedPdfPasswordBanks = const [],
    this.biometricsAvailable = false,
    this.authenticationInProgress = false,
    this.lastAuthenticationMessage,
  });

  final bool pinEnabled;
  final bool biometricEnabled;
  final AutoLockTimeout autoLockTimeout;
  final List<String> savedPdfPasswordBanks;
  final bool biometricsAvailable;
  final bool authenticationInProgress;
  final String? lastAuthenticationMessage;

  SecurityState copyWith({
    bool? pinEnabled,
    bool? biometricEnabled,
    AutoLockTimeout? autoLockTimeout,
    List<String>? savedPdfPasswordBanks,
    bool? biometricsAvailable,
    bool? authenticationInProgress,
    Object? lastAuthenticationMessage = _unset,
  }) {
    return SecurityState(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      savedPdfPasswordBanks: savedPdfPasswordBanks ?? this.savedPdfPasswordBanks,
      biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
      authenticationInProgress:
          authenticationInProgress ?? this.authenticationInProgress,
      lastAuthenticationMessage: lastAuthenticationMessage == _unset
          ? this.lastAuthenticationMessage
          : lastAuthenticationMessage as String?,
    );
  }

  static const Object _unset = Object();

  @override
  List<Object?> get props => [
        pinEnabled,
        biometricEnabled,
        autoLockTimeout,
        savedPdfPasswordBanks,
        biometricsAvailable,
        authenticationInProgress,
        lastAuthenticationMessage,
      ];
}

class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit(
    this._repository, {
    LocalAuthentication? localAuthentication,
  })  : _localAuthentication = localAuthentication ?? LocalAuthentication(),
        super(const SecurityState());

  final SecureSettingsRepository _repository;
  final LocalAuthentication _localAuthentication;

  Future<void> load() async {
    final timeout = await _repository.getAutoLockTimeout();
    final passwords = await _repository.getSavedBankPdfPasswords();
    var biometricsAvailable = false;
    try {
      final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      final isDeviceSupported = await _localAuthentication.isDeviceSupported();
      biometricsAvailable = canCheckBiometrics || isDeviceSupported;
    } catch (_) {
      biometricsAvailable = false;
    }
    emit(
      state.copyWith(
        autoLockTimeout: timeout,
        savedPdfPasswordBanks: passwords.keys.toList()..sort(),
        biometricsAvailable: biometricsAvailable,
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

  Future<String?> getPdfPassword(String bank) {
    return _repository.getBankPdfPassword(bank);
  }

  Future<void> deletePdfPassword(String bank) async {
    await _repository.deleteBankPdfPassword(bank);
    final updated = [...state.savedPdfPasswordBanks]..remove(bank);
    emit(state.copyWith(savedPdfPasswordBanks: updated));
  }

  Future<void> authenticateBiometrics() async {
    emit(
      state.copyWith(
        authenticationInProgress: true,
        lastAuthenticationMessage: null,
      ),
    );
    try {
      final authenticated = await _localAuthentication.authenticate(
        localizedReason:
            'Authenticate to unlock TapTracker with biometrics or system credentials',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      emit(
        state.copyWith(
          authenticationInProgress: false,
          lastAuthenticationMessage:
              authenticated ? 'Authentication successful.' : 'Authentication cancelled.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          authenticationInProgress: false,
          lastAuthenticationMessage: 'Authentication failed on this device.',
        ),
      );
    }
  }
}
