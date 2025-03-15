import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ten_thousands_hours/root/root.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'view/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize FFI
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  await Supabase.initialize(
    url: 'https://faxpnrwmphxnwgpfuwqa.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZheHBucndtcGh4bndncGZ1d3FhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAzMTYxNTgsImV4cCI6MjA1NTg5MjE1OH0.wASq1D9W_nB3U-XOzaoCsjIWgeQ6CJMNZZW3ub6ySSo',
  );

  runApp(
    const ProviderScope(
      child: Root(),
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
      home: const HomePage(),
      // home: const TestView(),
    );
  }
}
