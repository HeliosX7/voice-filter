import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:voicefilter/utilities/constants.dart';

class DialogBox {
  information(BuildContext context, String title, String desc) {
    print(
      "dialog : " + Theme.of(context).primaryColor.toString(),
    );
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              title,
              style: TextStyle(
                color: myBlue,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  return Navigator.pop(context);
                },
                child: FaIcon(
                  FontAwesomeIcons.checkCircle,
                  color: myBlue,
                ),
              ),
            ],
          );
        });
  }
}
