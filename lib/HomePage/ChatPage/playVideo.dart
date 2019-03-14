import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter/services.dart';

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
  double aspect; //= 0.6666666667;
  // = 3/2;

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
      aspect = aspect;//_controller.value.aspectRatio; //10 / 15;
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        aspectRatio:aspect,// _controller.value.aspectRatio,
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
    _chewieController.exitFullScreen();
    print('isFullScreen:${_chewieController.isFullScreen}');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _chewieController.toggleFullScreen();
    _controller.removeListener(listener);
    _chewieController.removeListener(listener);
    _controller.dispose();
    _chewieController.dispose();
    print('exited');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);
    aspect =queryData.size.width/queryData.size.height;
    return new MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        // appBar: new AppBar(
        //   title: new Text(
        //     // queryData.size.width.toString()+":"+queryData.size.height.toString(),
        //     "Video",
        //     style: TextStyle(fontSize: 22.0),
        //   ),
        //   backgroundColor: Color(0xffb00bae3).withOpacity(1),
        // ),
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
