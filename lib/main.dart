import 'package:bhardwaj_weather/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:bhardwaj_weather/screens/home_screen.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugShowCheckedModeBanner: false;
    return MaterialApp(
      title: 'GB Weather App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
