import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'cubits/analytics_cubit.dart';
import 'cubits/card_cubit.dart';
import 'cubits/reminder_cubit.dart';
import 'cubits/security_cubit.dart';
import 'cubits/statement_cubit.dart';
import 'models/entities.dart';
import 'repositories/app_repositories.dart';
import 'ui/home_page.dart';

class TapTrackerApp extends StatelessWidget {
  const TapTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localDataRepository = LocalDataRepository();
    final secureSettingsRepository = SecureSettingsRepository();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SecurityCubit(secureSettingsRepository)..load()),
        BlocProvider(create: (_) => CardCubit(localDataRepository)..load()),
        BlocProvider(create: (_) => StatementCubit(localDataRepository)..load()),
        BlocProvider(create: (_) => AnalyticsCubit()),
        BlocProvider(
          create: (_) => ReminderCubit(FlutterLocalNotificationsPlugin())..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'TapTracker',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: const HomePage(),
      ),
    );
  }
}

Color hexToColor(String hex) {
  final value = int.parse(hex.replaceAll('#', ''), radix: 16);
  return Color(0xFF000000 + value);
}

String utilizationBand(double utilization) {
  if (utilization > 80) return 'Critical';
  if (utilization > 50) return 'High';
  if (utilization < 30) return 'Ideal';
  return 'Low';
}
