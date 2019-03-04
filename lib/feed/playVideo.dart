import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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
    String url = await download(widget.mediaUrl);

    _controller = VideoPlayerController.file(File(url));

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
          Navigator.of(context).pop();
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
      appBar: new AppBar(
        title: new Text(
          'Video',
          style: TextStyle(fontSize: 22.0),
        ),
        backgroundColor: Color(0xffb00bae3),
      ),
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

  Future<String> download(String url) async {
    String externalStorage = (await getExternalStorageDirectory()).path;
    String songnm = url.replaceAll('http://54.200.143.85:4200/feeds/', '');
    String dir = '$externalStorage/OyeYaaro/.cache/videofiles';
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
    String trimmedsongname = songnm.replaceAll(new RegExp(r"\s+\b|\b\s"), "");
    File file = new File('$dir/$trimmedsongname');
    if (file.existsSync()) {
      return file.path;
    }
    http.Response response = await http.get(
      url,
    );
    var bytes = response.bodyBytes;
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
