import 'dart:async';
import 'dart:io' as io;
import 'package:file/file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:file/local.dart';
import 'package:voicefilter/screens/filter_screen.dart';
import 'package:voicefilter/services/auth_service.dart';
import 'package:voicefilter/utilities/constants.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmbeddingScreen extends StatefulWidget {
  final LocalFileSystem localFileSystem;
  EmbeddingScreen({localFileSystem})
      : this.localFileSystem = localFileSystem ?? LocalFileSystem();
  @override
  _EmbeddingScreenState createState() => _EmbeddingScreenState();
}

class _EmbeddingScreenState extends State<EmbeddingScreen> {
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;

  _init() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/embedding_';
        io.Directory appDocDirectory;
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath =
            appDocDirectory.path + customPath + DateTime.now().toString();

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

  @override
  void initState() {
    super.initState();
    _init();
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
                          Image.asset(
                            'assets/audio1.png',
                            width: width,
                          ),
                          SizedBox(
                            height: 40,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            child: Text(
                              "Welcome! thank you for signing up\nCan you please greet us with a 'hello'\nWe'll use it as your reference speech for the voice filter",
                              textScaleFactor: 1.1,
                              style: TextStyle(
                                letterSpacing: 1.1,
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Raleway',
                              ),
                            ),
                          ),
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

  Future<void> _logout() async {
    await FirebaseAuthentication().signOut(context);
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

  Future<void> uploadReferenceSpeech() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    DatabaseReference dbRef = FirebaseDatabase.instance.reference();
    final StorageReference storageRef = FirebaseStorage.instance.ref();
    io.File audioFile = io.File(_current.path);

    final StorageUploadTask uploadTask = storageRef
        .child("ref_speech")
        .child(user.email + ".wav")
        .putFile(audioFile);
    var audioUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
    print(audioUrl);

    dbRef.child(user.email.split('@')[0]).update({
      'embedding': audioUrl,
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
    });

    await uploadReferenceSpeech().whenComplete(() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FilterScreen(),
        ),
      );
    });
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
