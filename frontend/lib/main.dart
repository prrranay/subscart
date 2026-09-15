import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/schedule/presentation/screens/schedule_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar styles
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: SusCartApp(),
    ),
  );
}

class SusCartApp extends StatelessWidget {
  const SusCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SusCart Meal Subscription',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const ScheduleScreen(),
    );
  }
}
