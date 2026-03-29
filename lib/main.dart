import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/score_provider.dart';
import 'main_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ScoreProvider())],
      child: const TrucoProApp(),
    ),
  );
}

class TrucoProApp extends StatelessWidget {
  const TrucoProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truco Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.brown,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
