import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/entities.dart';

class ReminderState extends Equatable {
  const ReminderState({this.offsetDays = const [7, 3, 0], this.snoozed = false});

  final List<int> offsetDays;
  final bool snoozed;

  @override
  List<Object?> get props => [offsetDays, snoozed];
}

class ReminderCubit extends Cubit<ReminderState> {
  ReminderCubit(this._notifications) : super(const ReminderState());

  final FlutterLocalNotificationsPlugin _notifications;

  Future<void> initialize() async {
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  Future<void> setOffsets(List<int> offsets) async {
    emit(ReminderState(offsetDays: offsets, snoozed: false));
  }

  Future<void> scheduleReminder(StatementRecord statement) async {
    final dueDate = tz.TZDateTime.from(statement.dueDate, tz.local);
    for (final offset in state.offsetDays) {
      final scheduledDate = dueDate.subtract(Duration(days: offset));
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        continue;
      }
      await _notifications.zonedSchedule(
        _notificationId(statement.id, offset),
        'Payment reminder',
        'Payment for card ${statement.cardId} is due on ${statement.dueDate.toIso8601String().split('T').first}',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails('due_reminders', 'Due date reminders'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> snooze() async {
    emit(ReminderState(offsetDays: state.offsetDays, snoozed: true));
  }

  int _notificationId(String statementId, int offset) {
    final source = '$statementId:$offset';
    return source.codeUnits.fold<int>(0, (sum, value) => (sum * 31 + value) & 0x7fffffff);
  }
}
