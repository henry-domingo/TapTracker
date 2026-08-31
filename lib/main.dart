import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  runApp(const TapTrackerApp());
}
