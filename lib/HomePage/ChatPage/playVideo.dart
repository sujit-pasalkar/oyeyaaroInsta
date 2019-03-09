import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class PlayScreen extends StatefulWidget {
  final String url;
  final String type;
  PlayScreen({Key key, this.url, this.type}) : super(key: key);

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  VideoPlayerController _controller;
  ChewieController _chewieController;
  VoidCallback listener;
  double aspect = 1.0;

  bool showVideo = false;

  @override
  void initState() {
    super.initState();

    if (widget.type == 'file') {
      _controller = VideoPlayerController.file(File(widget.url));
    } else {
      _controller = VideoPlayerController.network(widget.url + '?raw=true');
    }

    _controller.initialize().then((onValue) {
      aspect = _controller.value.aspectRatio;
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        aspectRatio: aspect,
        autoPlay: true,
        looping: false,
      );

      _chewieController.addListener(() {
        if (_controller.value.position.inMilliseconds >=
            _controller.value.duration.inMilliseconds) {
          // Navigator.of(context).pop(); //shows blank screen
          _chewieController.pause(); //not working
          _controller.pause();
        }
      });

      setState(() {
        showVideo = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text(
          'Video',
          style: TextStyle(fontSize: 22.0),
        ),
        backgroundColor: Color(0xffb00bae3),
      ),
      body: Center(
        child: showVideo
            ? Chewie(
                controller: _chewieController,
              )
            : CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(
                        Color(0xffb00bae3))),
      ),
    );
  }
}
