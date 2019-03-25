import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class PlayScreen extends StatefulWidget {
  final String url;
  // final String type;
  PlayScreen({Key key, this.url}) : super(key: key);

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  VideoPlayerController _controller;
  ChewieController _chewieController;
  VoidCallback listener;

  bool showVideo = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.url));

    _controller.initialize().then((onValue) {
      print('aspect aratio:${_controller.value.aspectRatio}');
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        aspectRatio: _controller.value.aspectRatio,
        autoPlay: false,
        looping: false,
      );

      _controller.addListener(() {
        print(
            'in controller addlistener.................................................');
        if (_controller.value.position.inMilliseconds >=
            _controller.value.duration.inMilliseconds) {
          print(
              '${_controller.value.position.inMilliseconds}: ${_controller.value.duration.inMilliseconds}');
        }
      });

      setState(() {
        showVideo = true;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _chewieController.exitFullScreen();
    print('isFullScreen:${_chewieController.isFullScreen}');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _controller.removeListener(listener);
    _chewieController.removeListener(listener);
    _controller.dispose();
    _chewieController.dispose();
    print('exited');
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: showVideo
              ? Chewie(
                  controller: _chewieController,
                )
              : CircularProgressIndicator(
                  valueColor:
                      new AlwaysStoppedAnimation<Color>(Color(0xffb00bae3))),
        ),
      ),
    );
  }
}
