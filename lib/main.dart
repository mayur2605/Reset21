import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'ui/screens/checklist_screen.dart';
import 'ui/design_system.dart';

void main() async {
  // Global error handler — catches unhandled exceptions
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      dev.log('[main] dotenv.load failed: $e', name: 'Reset21');
    }

    // Initialize Hive + Supabase + Sync Queue
    try {
      await DatabaseService.initialize();
    } catch (e) {
      dev.log('[main] DatabaseService.initialize failed: $e', name: 'Reset21');
    }

    // Initialize local notifications
    try {
      await NotificationService.initialize();
    } catch (e) {
      dev.log('[main] NotificationService.initialize failed: $e', name: 'Reset21');
    }

    // Catch Flutter framework errors (render, layout, etc.)
    FlutterError.onError = (details) {
      dev.log(
        '[FlutterError] ${details.exceptionAsString()}',
        name: 'Reset21',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }, (error, stackTrace) {
    // Catch uncaught async errors
    dev.log(
      '[UncaughtError] $error',
      name: 'Reset21',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reset21',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const ChecklistScreen(),
    );
  }
}
