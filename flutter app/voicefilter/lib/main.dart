import 'package:flutter/material.dart';
import 'package:voicefilter/services/auth_manager.dart';
import 'package:voicefilter/utilities/constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'voice filter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: myBlue,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthManager(),
    );
  }
}
