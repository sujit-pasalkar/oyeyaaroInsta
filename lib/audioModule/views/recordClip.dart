import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/commonFunctions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_recorder/audio_recorder.dart';
import 'package:path/path.dart' as path;
import '../models/config.dart';
import './audioList.dart';
import 'dart:io';

class RecordClip extends StatefulWidget {
  @override
  _RecordClipState createState() => _RecordClipState();
}

class _RecordClipState extends State<RecordClip> {
  String recordingPath;
  String backgroundMusic;
  bool _isRecording = false;
  int timer;
  String time;
  int _duration;
  String audioDisplay;

  AudioRecorder audioRecorder = AudioRecorder();

  AudioPlayer audioPlayer;

  Color micColor = Colors.black;

  Timer animation;

  @override
  void initState() {
    super.initState();
    CommonFunctions.createdirectories();
    initializeDir();
    audioPlayer = AudioPlayer();
    _duration = 30;
    audioDisplay = 'Not Selected';
    time = '0.0';

    animation = Timer.periodic(new Duration(milliseconds: 500), (timer) {
      if (!_isRecording) {
        setState(() {
          micColor = Colors.black;
        });
      } else {
        if (micColor == Colors.green) {
          setState(() {
            micColor = Colors.blue;
          });
        } else {
          setState(() {
            micColor = Colors.green;
          });
        }
      }
    });
  }

  @override
  void dispose() async {
    super.dispose();
    if (audioPlayer != null) audioPlayer.stop();
    if (await AudioRecorder.isRecording) AudioRecorder.stop();
    if (animation.isActive) animation.cancel();
  }

  initializeDir() async {
    recordingPath =
        '${(await getApplicationDocumentsDirectory()).path}${Config.audioRecordTempPath}/${(DateTime.now().millisecondsSinceEpoch).toString()}';
    (await getApplicationDocumentsDirectory())
        .list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) {
      print(entity.path);
    });
  }

  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            color: Colors.grey.shade200,
            child: Icon(
              Icons.mic,
              size: 150.0,
              color: micColor,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 120.0,
              padding: EdgeInsets.all(20.0),
              color: Color.fromRGBO(00, 00, 00, 0.7),
              child: Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                        onTap: () {
                          _navigateAndDisplaySelection(context);
                        },
                        child: Container(
                          padding: EdgeInsets.all(4.0),
                          child: Image.asset(
                            'assets/ic_music_select.png',
                            width: 42.0,
                            height: 42.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Material(
                      color: Colors.transparent,
                      child: _buildChild(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChild() {
    if (!_isRecording) {
      return InkWell(
        borderRadius: BorderRadius.all(Radius.circular(50.0)),
        onTap: () {
          onAudioRecordButtonPressed();
        },
        child: Container(
          padding: EdgeInsets.all(4.0),
          child: Image.asset(
            'assets/mic-icon.png',
            width: 72.0,
            height: 72.0,
          ),
        ),
      );
    } else {
      return InkWell(
        borderRadius: BorderRadius.all(Radius.circular(50.0)),
        onTap: () {
          onStopButtonPressed();
        },
        child: Container(
          padding: EdgeInsets.all(4.0),
          child: Image.asset(
            'assets/stop-flat.png',
            width: 72.0,
            height: 72.0,
          ),
        ),
      );
    }
  }

  _navigateAndDisplaySelection(BuildContext context) async {
    final downloadedSongPath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioList(),
        ));
    backgroundMusic = downloadedSongPath;
    if (backgroundMusic.isNotEmpty) {
      setState(() {
        audioDisplay = path.basenameWithoutExtension(backgroundMusic);
      });
    }
  }

  void onStopButtonPressed() async {
    await audioPlayer.stop();
    stopAudioRecording().then((_) {
      if (mounted)
        setState(() {
          _isRecording = false;
        });
    });
  }

  Future<void> stopAudioRecording() async {
    try {
      Recording recording = await AudioRecorder.stop();
      print("recordingPath: " + recording.path);
      CommonFunctions commonFunctions = new CommonFunctions();
      // String res =
      //     await commonFunctions.mergeAudio(recording.path, backgroundMusic);
      // await commonFunctions.moveProcessedFile(res);
      await commonFunctions.moveProcessedFile(recording.path);
      Future.delayed(const Duration(seconds: 2), () => "1");
      Navigator.pop(context);
    } on Exception catch (e) {
      print(e);
      return null;
    }
  }

  void onAudioRecordButtonPressed() {
    startAudioRecording().then(() {
      if (mounted) setState(() {});
    });
  }

  startAudioRecording() async {
    startCountdown();
    audioplay();
    setState(() {
      _isRecording = true;
    });

    try {
      await AudioRecorder.start(path: recordingPath);
    } on Exception catch (e) {
      CommonFunctions.showSnackbar(context, e.toString());
      return null;
    }
  }

  Future<void> audioplay() async {
    if (backgroundMusic.isNotEmpty) {
      audioPlayer.play(backgroundMusic, isLocal: true, volume: 0.7);
      await audioPlayer.setReleaseMode(ReleaseMode.LOOP);
    }
  }

  startCountdown() {
    return Timer.periodic(
      Duration(seconds: 1),
      (Timer t) => () {
            handleTimeout(t);
          },
    );
  }

  void handleTimeout(Timer t) {
    setState(() {
      time = t.tick.toString();
    });
    if (t.tick == _duration) {
      t.cancel();
    }
  }
}
