import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicefilter/screens/filter_screen.dart';
import 'package:voicefilter/screens/login_register_screen.dart';
import 'package:voicefilter/utilities/constants.dart';

class AuthManager extends StatefulWidget {
  @override
  _AuthManagerState createState() => _AuthManagerState();
}

class _AuthManagerState extends State<AuthManager> {
  FirebaseUser user;

  Future<void> getUserData() async {
    user = await FirebaseAuth.instance.currentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getUserData(),
      builder: (context, futureSnapshot) {
        if (futureSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  myBlue,
                ),
              ),
            ),
          );
        } else if (futureSnapshot.connectionState == ConnectionState.done &&
            user != null) {
          print('valid user');
          return FilterScreen();
        } else {
          print('No user');
          return LoginRegisterScreen();
        }
      },
    );
  }
}
