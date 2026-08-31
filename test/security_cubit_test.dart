import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tap_tracker/cubits/security_cubit.dart';
import 'package:tap_tracker/models/entities.dart';
import 'package:tap_tracker/repositories/app_repositories.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SecurityCubit', () {
    blocTest<SecurityCubit, SecurityState>(
      'updates PIN toggle and disables biometric',
      build: () => SecurityCubit(SecureSettingsRepository()),
      act: (cubit) async {
        await cubit.setPinEnabled(true);
        await cubit.setBiometricEnabled(false);
      },
      expect: () => [
        const SecurityState(pinEnabled: true),
        const SecurityState(
          pinEnabled: true,
          biometricEnabled: false,
          lastAuthenticationMessage: 'Biometric lock disabled.',
        ),
      ],
    );

    blocTest<SecurityCubit, SecurityState>(
      'updates auto lock timeout',
      build: () => SecurityCubit(SecureSettingsRepository()),
      act: (cubit) => cubit.setAutoLockTimeout(AutoLockTimeout.fiveMinutes),
      expect: () => [
        const SecurityState(autoLockTimeout: AutoLockTimeout.fiveMinutes),
      ],
    );

    blocTest<SecurityCubit, SecurityState>(
      'enables biometric after successful authentication',
      build: () => SecurityCubit(
        SecureSettingsRepository(),
        authenticate: (_) async => true,
      ),
      act: (cubit) => cubit.setBiometricEnabled(true),
      expect: () => [
        const SecurityState(authenticationInProgress: true),
        const SecurityState(
          biometricEnabled: true,
          lastAuthenticationMessage: 'Authentication successful.',
        ),
      ],
    );
  });
}
