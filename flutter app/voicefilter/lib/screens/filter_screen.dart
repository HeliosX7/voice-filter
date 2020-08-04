import 'dart:async';
import 'dart:io' as io;
import 'package:file/file.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:file/local.dart';
import 'package:voicefilter/services/api.dart';
import 'package:voicefilter/services/auth_service.dart';
import 'package:voicefilter/utilities/constants.dart';
import 'package:voicefilter/widgets/custom_painter.dart';
import 'package:voicefilter/widgets/player_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FilterScreen extends StatefulWidget {
  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class UserData {
  String userEmail;
  String refUrl;
  UserData(this.userEmail, this.refUrl);
}

class _FilterScreenState extends State<FilterScreen> {
  Future<UserData> getUserData() async {
    String userEmail;
    String refUrl;
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    userEmail = user.email.split('@')[0];
    DatabaseReference dbRef =
        FirebaseDatabase.instance.reference().child(userEmail);
    await dbRef.once().then((DataSnapshot snapshot) {
      refUrl = snapshot.value["embedding"];
      print("user :" + userEmail);
      print("ref :" + refUrl);
    });

    return UserData(userEmail, refUrl);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getUserData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return VoiceFilter(
            userData: snapshot.data,
          );
        } else
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(myBlue),
              ),
            ),
          );
      },
    );
  }
}

class VoiceFilter extends StatefulWidget {
  final UserData userData;
  final LocalFileSystem localFileSystem;
  VoiceFilter({
    localFileSystem,
    this.userData,
  }) : this.localFileSystem = localFileSystem ?? LocalFileSystem();
  @override
  _VoiceFilterState createState() => _VoiceFilterState();
}

class _VoiceFilterState extends State<VoiceFilter> {
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;
  String timeKey;

  @override
  void initState() {
    super.initState();
    _init();
    print("init 2:");
    print(widget.userData.refUrl);
  }

  Widget getCirclePainter() {
    double percentage = ((120 + _current.metering.averagePower) / 1.2);
    return Container(
      height: 50,
      width: 50,
      child: CustomPaint(
        foregroundPainter: CirclePainter(
          lineColor: myBlue.withOpacity(0.3),
          completeColor: myBlue,
          completePercent: percentage,
          width: 8,
        ),
      ),
    );
  }

  Widget underlinedText(text) {
    double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(
        left: 25,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 20,
          ),
          Text(
            text,
            textScaleFactor: 0.9,
            style: TextStyle(
              letterSpacing: 1.1,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
              fontFamily: 'Raleway',
            ),
          ),
          Divider(
            color: myBlue,
            thickness: 2,
            indent: width * 0.01,
            endIndent: width * 0.78,
          ),
          SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _currentStatus == RecordingStatus.Unset
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    myBlue,
                  ),
                ),
              )
            : Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Image.asset(
                                'assets/audio2.png',
                                width: width * 0.55,
                              ),
                              getCirclePainter(),
                              Text(
                                _current.duration.inSeconds.toString() + " s",
                                style: TextStyle(
                                  color: myBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(),
                            ],
                          ),
                          SizedBox(
                            height: 40,
                          ),
                          timeKey != null ? getInputStream() : Container(),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          FontAwesomeIcons.stopCircle,
                          color: myBlue,
                        ),
                        onPressed: _currentStatus != RecordingStatus.Unset
                            ? _stop
                            : null,
                      ),
                      Column(
                        children: <Widget>[
                          _buildText(_currentStatus),
                          SizedBox(
                            height: 10,
                          ),
                          InkWell(
                            onTap: micResponse,
                            child: CircleAvatar(
                              backgroundColor: myBlue,
                              radius: 25,
                              child: Icon(
                                Icons.mic,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          FontAwesomeIcons.signOutAlt,
                          color: myBlue,
                        ),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget getPlayer(text, url) {
    return Column(
      children: <Widget>[
        underlinedText(text),
        PlayerWidget(
          url: url,
        ),
      ],
    );
  }

  Widget getInputStream() {
    return StreamBuilder(
      stream: FirebaseDatabase()
          .reference()
          .child(widget.userData.userEmail)
          .child(timeKey)
          .onValue,
      builder: (context, snap) {
        if (snap.hasData &&
            !snap.hasError &&
            snap.data.snapshot.value != null) {
          var data = snap.data.snapshot.value;
          return Column(
            children: <Widget>[
              getPlayer("INPUT AUDIO", data["input"]),
              data["output"] == '-'
                  ? Container()
                  : getPlayer("FILTERED AUDIO", data["output"]),
            ],
          );
        } else
          return Center(
              child: Text(
            "Let's get started",
            textScaleFactor: 1.1,
            style: TextStyle(
              letterSpacing: 1.1,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
              fontFamily: 'Raleway',
            ),
          ));
      },
    );
  }

  void micResponse() {
    switch (_currentStatus) {
      case RecordingStatus.Initialized:
        {
          _start();
          break;
        }
      case RecordingStatus.Recording:
        {
          _pause();
          break;
        }
      case RecordingStatus.Paused:
        {
          _resume();
          break;
        }
      case RecordingStatus.Stopped:
        {
          _init();
          break;
        }
      default:
        break;
    }
  }

  Future<void> uploadInputSpeech(String _timeKey) async {
    DatabaseReference dbRef = FirebaseDatabase.instance.reference();
    final StorageReference storageRef = FirebaseStorage.instance.ref();
    io.File audioFile = io.File(_current.path);

    final StorageUploadTask uploadTask = storageRef
        .child("input_speech")
        .child(widget.userData.userEmail + _timeKey + ".wav")
        .putFile(audioFile);
    var audioUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
    print(audioUrl);

    dbRef.child(widget.userData.userEmail).child(_timeKey).set({
      'input': audioUrl,
      'output': '-',
    }).whenComplete(() async {
      await runVoiceFilterBackend(
          widget.userData.userEmail, timeKey, audioUrl, widget.userData.refUrl);
    });
  }

  _stop() async {
    var result = await _recorder.stop();
    print("Stop recording: ${result.path}");
    print("Stop recording: ${result.duration}");
    File file = widget.localFileSystem.file(result.path);
    print("File length: ${await file.length()}");

    setState(() {
      _current = result;
      _currentStatus = _current.status;
      //timeKey = DateTime.now().toString().split('.')[0];
      timeKey = DateTime.now().millisecondsSinceEpoch.toString();
    });

    await uploadInputSpeech(timeKey);
  }

  Future<void> _logout() async {
    await FirebaseAuthentication().signOut(context);
  }

  _init() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/audio_';
        io.Directory appDocDirectory;
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath =
            appDocDirectory.path + customPath + DateTime.now().toString();
        //DateTime.now().millisecondsSinceEpoch.toString();

        _recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await _recorder.initialized;
        // after initialization
        var current = await _recorder.current(channel: 0);
        print(current);
        // should be "Initialized", if all working fine
        setState(() {
          _current = current;
          _currentStatus = current.status;
          print(_currentStatus);
        });
      } else {
        Scaffold.of(context).showSnackBar(
            SnackBar(content: Text("You must accept permissions")));
      }
    } catch (e) {
      print(e);
    }
  }

  _start() async {
    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);
      setState(() {
        _current = recording;
      });

      const tick = const Duration(milliseconds: 50);
      Timer.periodic(tick, (Timer t) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = await _recorder.current(channel: 0);
        setState(() {
          _current = current;
          _currentStatus = _current.status;
        });
      });
    } catch (e) {
      print(e);
    }
  }

  _resume() async {
    await _recorder.resume();
    setState(() {});
  }

  _pause() async {
    await _recorder.pause();
    setState(() {});
  }

  Widget _buildText(RecordingStatus status) {
    var text = "";
    switch (_currentStatus) {
      case RecordingStatus.Initialized:
        {
          text = 'Start';
          break;
        }
      case RecordingStatus.Recording:
        {
          text = 'Pause';
          break;
        }
      case RecordingStatus.Paused:
        {
          text = 'Resume';
          break;
        }
      case RecordingStatus.Stopped:
        {
          text = 'Initialize';
          break;
        }
      default:
        break;
    }
    return Text(
      text,
      style: TextStyle(
        color: myBlue,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w900,
        fontFamily: 'Spartan',
      ),
    );
  }
}
