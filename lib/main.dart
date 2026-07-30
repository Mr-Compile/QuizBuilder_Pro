import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'services/service_locator.dart';

/// Entry point for QuizForge AI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize database factory for Windows/desktop platforms
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // Initialize shared preferences early so the rest of the app can use it.
  await ServiceLocator.prefs;
  runApp(const QuizForgeApp());
}
