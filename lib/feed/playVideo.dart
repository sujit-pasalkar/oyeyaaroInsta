import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:connect_yaar/models/data-service.dart';
import 'package:path_provider/path_provider.dart';

class PlayVideo extends StatefulWidget {
  final String mediaUrl;
  PlayVideo({Key key, this.mediaUrl}) : super(key: key);

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayVideo> {
  VideoPlayerController _controller;
  ChewieController _chewieController;
  VoidCallback listener;
  double aspect = 1.0;

  bool showVideo = false;


  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  initialize() async {
    File file;

    Directory extDir = await getExternalStorageDirectory();
    File downloadedFile = File(
        extDir.path + "/OyeYaaro/Media/" + widget.mediaUrl.replaceAll("https://s3.amazonaws.com/oyeyaaro/",""));
    bool fileExist = await downloadedFile.exists();

    if (fileExist) {
      file = downloadedFile;
    } else {
      file =
          await dataService.downloadFileFromS3(widget.mediaUrl.replaceAll("https://s3.amazonaws.com/oyeyaaro/",""));
    }

      _controller = VideoPlayerController.file(file);

      _controller.initialize().then((onValue) {
        aspect = _controller.value.aspectRatio;
        _chewieController = ChewieController(
          videoPlayerController: _controller,
          aspectRatio: aspect,
          autoPlay: false,
          looping: false,
        );

        _controller.addListener(() {
          if (_controller.value.position.inMilliseconds >=
              _controller.value.duration.inMilliseconds) {
            // Navigator.of(context).pop();
            // setState(() {
              // _controller.;
              // _controller.initialize();
              // _controller.
            // });
          }
        });

        setState(() {
          showVideo = true;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: showVideo
            ? Chewie(
                controller: _chewieController,
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}
