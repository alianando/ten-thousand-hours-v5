import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ten_thousands_hours/providers/storage_pro.dart';
import 'package:ten_thousands_hours/root/root.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ten_thousands_hours/views/home_page/home_page.dart';
import 'package:ten_thousands_hours/views/test.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  await Supabase.initialize(
    url: 'https://faxpnrwmphxnwgpfuwqa.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZheHBucndtcGh4bndncGZ1d3FhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAzMTYxNTgsImV4cCI6MjA1NTg5MjE1OH0.wASq1D9W_nB3U-XOzaoCsjIWgeQ6CJMNZZW3ub6ySSo',
  );
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(sharedPreferences)],
      child: const Root(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const HomePage(),
      home: const TestView(),
    );
  }
}
