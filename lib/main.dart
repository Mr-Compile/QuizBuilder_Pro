import 'package:flutter/material.dart';
import 'app.dart';
import 'services/service_locator.dart';

/// Entry point for QuizBuilder Pro.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize shared preferences early so the rest of the app can use it.
  await ServiceLocator.prefs;
  runApp(const QuizBuilderProApp());
}
