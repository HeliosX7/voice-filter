import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:voicefilter/screens/embedding_screen.dart';
import 'package:voicefilter/screens/filter_screen.dart';
import 'package:voicefilter/screens/login_register_screen.dart';
import '../widgets/dialogBox.dart';

class FirebaseAuthentication {
  Future<void> signIn(context, email, password) async {
    try {
      AuthResult result =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(result);

      DatabaseReference dbRef = FirebaseDatabase.instance
          .reference()
          .child(result.user.email.split('@')[0]);
      dbRef.once().then((DataSnapshot snapshot) {
        String val = snapshot.value["embedding"];
        if (val == '-') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmbeddingScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FilterScreen(),
            ),
          );
        }
      });
    } catch (e) {
      print("signin error:" + e.toString());
      DialogBox()
          .information(context, "ALERT", "Your login details are incorrect");
    }
  }

  Future<void> signUp(context, email, password) async {
    try {
      AuthResult result =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(result);

      DatabaseReference dbRef = FirebaseDatabase.instance.reference();
      dbRef.child(result.user.email.split('@')[0]).set({
        'embedding': '-',
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmbeddingScreen(),
        ),
      );
    } catch (e) {
      DialogBox().information(context, "ERROR", e.toString());
      print(e);
      return e;
    }
  }

  Future<void> signOut(context) async {
    await FirebaseAuth.instance.signOut().then(
          (value) => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginRegisterScreen(),
            ),
          ),
        );
  }
}
