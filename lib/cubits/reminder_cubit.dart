import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    for (final offset in state.offsetDays) {
      await _notifications.show(
        statement.hashCode + offset,
        'Payment reminder',
        'Due for statement ${statement.id} in $offset day(s).',
        const NotificationDetails(
          android: AndroidNotificationDetails('due_reminders', 'Due date reminders'),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  Future<void> snooze() async {
    emit(ReminderState(offsetDays: state.offsetDays, snoozed: true));
  }
}
