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
  double aspect; 

  bool showVideo = false;

  @override
  void initState() {
    super.initState();

    if (widget.type == 'file') {
      print('file path : ${widget.url}');
      _controller =  VideoPlayerController.file(File(widget.url));
    } else {
      _controller = VideoPlayerController.network(widget.url + '?raw=true');
    }

    _controller.initialize().then((onValue) {
      print('aspect aratio:${_controller.value.aspectRatio}');
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        aspectRatio: _controller.value.aspectRatio,
        autoPlay: false,
        looping: false,
      );

      _controller.addListener((){
        print('in controller addlistener.................................................');
        if (_controller.value.position.inMilliseconds >=
            _controller.value.duration.inMilliseconds) {
              print('${_controller.value.position.inMilliseconds}: ${_controller.value.duration.inMilliseconds}');
          Navigator.of(context).pop(); 
        }
      });

    //   _chewieController.addListener(() {
    //     if (_controller.value.position.inMilliseconds >=
    //         _controller.value.duration.inMilliseconds) {
    //       Navigator.of(context).pop(); 
    // // _controller.dispose();
    // // _chewieController.dispose();
    //     }
    //   });

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
    _controller.removeListener(listener);
    _chewieController.removeListener(listener);
    _controller.dispose();
    _chewieController.dispose();
    print('exited');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MediaQueryData queryData;
    // queryData = MediaQuery.of(context);
    // aspect =queryData.size.width/queryData.size.height;
    return new MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: 
        Center(
          child: 
          //  _controller.value.initialized
          //     ? AspectRatio(
          //         aspectRatio: _controller.value.aspectRatio,
          //         child: VideoPlayer(_controller),
          //       )
          //     : Container(),

          showVideo
              ? 
              Chewie(
                  controller: _chewieController,
                )
              : CircularProgressIndicator(
                  valueColor:
                      new AlwaysStoppedAnimation<Color>(Color(0xffb00bae3))),
        ),

        //   floatingActionButton: FloatingActionButton(
        //   onPressed: () {
        //     setState(() {
        //       _controller.value.isPlaying
        //           ? _controller.pause()
        //           : _controller.play();
        //     });
        //   },
        //   child: Icon(
        //     _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        //   ),
        // ),
      ),
    );
  }
}
