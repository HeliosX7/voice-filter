import 'package:flutter/material.dart';
import 'package:voicefilter/services/auth_service.dart';
import 'package:voicefilter/widgets/dialogbox.dart';
import 'package:voicefilter/utilities/constants.dart';

class LoginRegisterScreen extends StatefulWidget {
  @override
  _LoginRegisterScreenState createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  DialogBox dialogBox = DialogBox();

  final _formKey = GlobalKey<FormState>();

  bool login = true;

  String _email = "";
  String _password = "";

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 50,
              ),
              Image.asset(
                "assets/audio3.png",
                width: 0.6 * width,
              ),
              SizedBox(
                height: 15,
              ),
              Text(
                "Voice Filter",
                style: TextStyle(
                  fontFamily: "Spartan",
                  fontSize: 30,
                  color: myBlue,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0, 5),
                        blurRadius: 15,
                      ),
                    ]),
                child: Container(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 25),
                  child: Column(
                    children: screenInputs(),
                  ),
                ),
              ),
              Container(
                child: Column(
                  children: screenButtons(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> screenInputs() {
    return [
      TextFormField(
        style: TextStyle(
            color: Colors.black,
            fontFamily: 'Spartan',
            fontSize: 16,
            fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontFamily: 'Montserrat',
            fontSize: 14,
          ),
        ),
        validator: (value) {
          return value.isEmpty ? 'Email is required' : null;
        },
        onSaved: (value) {
          return _email = value;
        },
      ),
      SizedBox(
        height: 10,
      ),
      TextFormField(
        style: TextStyle(
            color: Colors.black,
            fontFamily: 'Spartan',
            fontSize: 16,
            fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontFamily: 'Montserrat',
            fontSize: 14,
          ),
        ),
        obscureText: true,
        validator: (value) {
          return value.isEmpty ? 'Password is required' : null;
        },
        onSaved: (value) {
          return _password = value;
        },
      ),
    ];
  }

  List<Widget> screenButtons() {
    if (login) {
      return [
        SizedBox(
          height: 20,
        ),
        InkWell(
          onTap: submitForm,
          child: Container(
            width: 100,
            decoration: BoxDecoration(
              color: myBlue,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "LOGIN",
                  style: TextStyle(
                      fontFamily: 'Spartan',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5),
                ),
              ),
            ),
          ),
        ),
        FlatButton(
          child: Text(
            "Don't have an account? Register",
            style:
                TextStyle(color: myBlue, fontFamily: 'Poppins', fontSize: 12),
          ),
          onPressed: () {
            setState(() {
              login = !login;
            });
          },
        )
      ];
    } else {
      return [
        SizedBox(
          height: 20,
        ),
        InkWell(
          onTap: submitForm,
          child: Container(
            width: 120,
            decoration: BoxDecoration(
              color: myBlue,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "REGISTER",
                  style: TextStyle(
                    fontFamily: 'Spartan',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        FlatButton(
          child: Text(
            "Don't have an account? Register",
            style: TextStyle(
              color: myBlue,
              fontFamily: 'Poppins',
              fontSize: 12,
            ),
          ),
          onPressed: () {
            setState(() {
              login = !login;
            });
          },
        )
      ];
    }
  }

  void submitForm() async {
    print("submi form");
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();

      try {
        if (login) {
          await FirebaseAuthentication().signIn(context, _email, _password);
        } else {
          await FirebaseAuthentication().signUp(context, _email, _password);
        }
      } catch (e) {
        print(e);
        DialogBox().information(context, "ERROR", e.toString());
      }
    }
  }
}
