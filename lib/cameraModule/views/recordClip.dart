import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/commonFunctions.dart';
import 'package:camera/camera.dart';
import './audioList.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../mdels/config.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as path;

class RecordClip extends StatefulWidget {
  @override
  _RecordClipState createState() => _RecordClipState();
}

class _RecordClipState extends State<RecordClip> with TickerProviderStateMixin {
  List<CameraDescription> cameras;
  bool _isReady = false;
  bool _toggleCamera = false;
  CameraController controller;
  String filePath;
  String commonDir;
  String audioFile;
  String filename;
  bool _isRecording = false;
  int timer;
  String time;
  int _duration;
  String audioDisplay;
  AudioPlayer audioPlayer;
  double value;
  AnimationController _controller;

  bool allowDeactivate = true;

  int kStartValue = 30;
  int kEndValue = 30;

  // double scale = 4.1;

  @override
  void initState() {
    super.initState();
    value = 0.0;
    getPermissions();
    initializeCameras();
    CommonFunctions.createdirectories();
    initializeDir();
    filename = (new DateTime.now().millisecondsSinceEpoch).toString();
    audioPlayer = new AudioPlayer();
    _duration = 30;
    audioDisplay = 'Not Selected';
    time = '0.0';

    _controller = new AnimationController(
      vsync: this,
      duration: new Duration(seconds: kStartValue),
    );

    _controller.forward(from: 0.0);

    // controller.notifyListeners();
  }

  @override
  void dispose() {
    if (audioPlayer != null) audioPlayer.stop();
    disposeCtrl();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  disposeCtrl() async {
    if (controller != null) await controller.dispose();
    super.dispose();
  }

  getPermissions() async {}
  initializeDir() async {
    commonDir = (await getApplicationDocumentsDirectory()).path;
    filePath = '$commonDir${Config.videoRecordTempPath}/$filename.mp4';
    (await getApplicationDocumentsDirectory())
        .list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) {
      print(entity.path);
    });
  }

  Future<void> initializeCameras() async {
    try {
      cameras = await availableCameras();
      controller = CameraController(cameras[0], ResolutionPreset.high);
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isReady = true;
        });
      });
      controller.addListener(() {
        print("camera preview size;" + controller.value.previewSize.toString());
      });
    } on CameraException catch (e) {
      CommonFunctions.showSnackbar(context, e.description);
    }

    
  }

  Widget build(BuildContext context) {
    if (!_isReady) {
      return Container();
    } else {
      if (cameras.isEmpty) {
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No Camera Found',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.white,
            ),
          ),
        );
      }
      if (!controller.value.isInitialized) {
        return Container();
      }

      return Container(
        child: Stack(
          children: <Widget>[
            // GestureDetector(
            //   onScaleUpdate: (one) {
            //     print(one.scale);
            //       setState(() {
            //         // scale = one.scale;
            //       });
            //   },
            //   child: 
              new Transform.scale(
                scale: 1.1/ controller.value.aspectRatio,
                child: 
                new Center(
                  child: new AspectRatio(
                      aspectRatio:controller.value.aspectRatio,
                      child: new CameraPreview(controller)),
                ),
              ),
            // ),
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
                        child: !_isRecording
                            ? InkWell(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50.0)),
                                onTap: allowDeactivate
                                    ? () {
                                        _navigateAndDisplaySelection(context);
                                      }
                                    : null,
                                child: Container(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.library_music,
                                    color: Colors.white,
                                    size: 40.0,
                                  ),
                                ),
                              )
                            : SizedBox(height: 0, width: 0),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Material(
                        color: Colors.transparent,
                        child: _buildChild(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: Colors.transparent,
                        child: !_isRecording
                            ? InkWell(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50.0)),
                                onTap: () {
                                  if (!_toggleCamera) {
                                    setState(() {
                                      _toggleCamera = true;
                                    });
                                    onCameraSelected(cameras[1]);
                                  } else {
                                    setState(() {
                                      _toggleCamera = false;
                                    });
                                    onCameraSelected(cameras[0]);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.cached,
                                    color: Colors.white,
                                    size: 40.0,
                                  ),
                                ),
                              )
                            : SizedBox(height: 0, width: 0),
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
  }

  Widget _buildChild() {
    if (!_isRecording) {
      return InkWell(
        borderRadius: BorderRadius.all(Radius.circular(50.0)),
        onTap: () {
          onVideoRecordButtonPressed();
        },
        child: Container(
          padding: EdgeInsets.all(4.0),
          child: Image.asset(
            'assets/video-camera-icon.png',
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

  void onCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) await controller.dispose();
    controller = CameraController(cameraDescription, ResolutionPreset.high);

    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        CommonFunctions.showSnackbar(
            context, 'Camera Error: ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      CommonFunctions.showSnackbar(context, e.description);
    }

    if (mounted) setState(() {});
  }

  _navigateAndDisplaySelection(BuildContext context) async {
    setState(() {
      allowDeactivate = false;
    });
    await Future.delayed(Duration(milliseconds: 1000));
    final downloadedSongPath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioList(),
        ));
    setState(() {
      allowDeactivate = true;
    });
    audioFile = downloadedSongPath[0];
    setState(() {
      _duration = downloadedSongPath[1].inSeconds;
      kStartValue = _duration;
      kEndValue = _duration;
    });

    if (downloadedSongPath[0] != null && downloadedSongPath[0] != '') {
      setState(() {
        audioDisplay = path.basenameWithoutExtension(downloadedSongPath[0]);
      });
    }
  }

  void onStopButtonPressed() {
    print("Timer 100 ms, elapsed: ");
    if (audioPlayer != null) {
      audiostop();
    }
    stopVideoRecording().then((_) {
      if (mounted)
        setState(() {
          _isRecording = false;
        });
    });
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
      CommonFunctions a = new CommonFunctions();
      String res = await a.mergeAudio(filePath, audioFile);
      await a.moveProcessedFile(res);
      Future.delayed(const Duration(seconds: 2), () => "1");
      Navigator.pop(context);
    } on CameraException catch (e) {
      print(e);
      return null;
    }
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((String filePath) {
      if (mounted) setState(() {});
    });
  }

  Future<String> startVideoRecording() async {
    if (!controller.value.isInitialized) {
      CommonFunctions.showSnackbar(context, 'Error: select a camera first.');
      return null;
    }

    if (controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }
    startCountdown();
    audioplay();

    setState(() {
      _isRecording = true;
    });

    try {
      await controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      CommonFunctions.showSnackbar(context, e.description);
      return null;
    }
    return filePath;
  }

  Future<void> audioplay() async {
    if (audioFile != null && audioFile != "") {
      audioPlayer.play(audioFile, isLocal: true);
      await audioPlayer.setReleaseMode(ReleaseMode.LOOP);
    }
  }

  Future<void> audiostop() async {
    await audioPlayer.stop();
  }

  startCountdown() async {
    setState(() {
      kStartValue = _duration;
      kEndValue = 0;
    });
    await Future.delayed(Duration(seconds: _duration));
    onStopButtonPressed();
  }
}

class Countdown extends AnimatedWidget {
  Animation<int> animation;

  Countdown({Key key, this.animation}) : super(key: key, listenable: animation);

  @override
  build(BuildContext context) {
    return new Text(
      animation.value.toString(),
      style: new TextStyle(fontSize: 150.0),
    );
  }
}
