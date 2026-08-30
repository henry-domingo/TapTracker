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

class TapTrackerApp extends StatefulWidget {
  const TapTrackerApp({super.key});

  @override
  State<TapTrackerApp> createState() => _TapTrackerAppState();
}

class _TapTrackerAppState extends State<TapTrackerApp> {
  final LocalDataRepository localDataRepository = LocalDataRepository();
  final SecureSettingsRepository secureSettingsRepository = SecureSettingsRepository();

  @override
  Widget build(BuildContext context) {
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
  final raw = hex.replaceAll('#', '');
  if (raw.length != 6 && raw.length != 8) {
    return const Color(0xFF000000);
  }
  final value = int.tryParse(raw, radix: 16);
  if (value == null) {
    return const Color(0xFF000000);
  }
  if (raw.length == 8) {
    return Color(value);
  }
  return Color(0xFF000000 | value);
}

String utilizationBand(double utilization) {
  if (utilization > 80) return 'Critical';
  if (utilization > 50) return 'High';
  if (utilization < 30) return 'Ideal';
  return 'Low';
}
