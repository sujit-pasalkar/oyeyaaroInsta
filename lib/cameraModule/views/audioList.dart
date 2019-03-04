import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import '../mdels/config.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart'; //

class AudioList extends StatefulWidget {
  @override
  _AudioListState createState() => _AudioListState();
}

enum PlayerState { stopped, playing, paused }

class _AudioListState extends State<AudioList> {
  Directory directory;

  TextEditingController _controller = new TextEditingController();
  List<dynamic> searchresult = List<dynamic>();
  List<dynamic> songList = List<dynamic>();
  bool typing = false;
  bool loading = true; //initially true as service not called
  bool isCheckDuration = false;
  String loadingMsg = "Loading Songs..";
  String sendUrl = '';
  bool donloadSongLoading = false;

  AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration;
  Duration _position;
  String applicationDir;

  get _isPlaying => _playerState == PlayerState.playing;
  get _isPaused => _playerState == PlayerState.paused;
  get _durationText => _duration?.toString()?.split('.')?.first ?? '';
  get _positionText => _position?.toString()?.split('.')?.first ?? '';

  bool isPlaying = false;

  int curr_id = -1;

  @override
  void initState() {
    AudioPlayer.logEnabled = true;
    _initAudioPlayer();
    getSongs();
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.stop();
  }

  void _initAudioPlayer() {
    _audioPlayer = new AudioPlayer();

    _audioPlayer.durationHandler = (d) => setState(() {
          _duration = d;
          print('duration------------------------------:${_duration}');
          if (isCheckDuration == true) {
            setState(() {
              isCheckDuration = false;
              _stop();
              download(sendUrl);
            });
          }
        });

    _audioPlayer.positionHandler = (p) => setState(() {
          _position = p;
        });

    _audioPlayer.completionHandler = () {
      onComplete();
      setState(() {
        _position = _duration;
      });
    };

    _audioPlayer.errorHandler = (msg) {
      print('audioPlayer error : $msg');
      setState(() {
        _playerState = PlayerState.stopped;
        _duration = Duration(seconds: 0);
        _position = Duration(seconds: 0);
      });
    };
  }

  void onComplete() {
    setState(() {
      _playerState = PlayerState.stopped;
      isPlaying = false;
    });
    // playNext();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
          title: Text('Songs'),
          backgroundColor: Color(0xffb00bae3),
        ),
        body: donloadSongLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Stack(
                children: <Widget>[
                  Column(children: <Widget>[
                    Container(
                      margin: EdgeInsets.all(22.0),
                      padding: EdgeInsets.fromLTRB(18.0, 0.0, 0.0, 0.0),
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: TextField(
                                autofocus: false,
                                controller: _controller,
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Search by Song name..'),
                                onChanged: (input) {
                                  searchOperation(input);
                                }),
                          ),
                          this.typing
                              ? IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      this.typing = false;
                                      this._controller.text = "";
                                      print('songs : ${this.songList.length}');
                                      this.searchresult = this.songList;
                                    });
                                  },
                                )
                              : Text('')
                        ],
                      ),
                      decoration: BoxDecoration(
                          color: Colors.grey[350],
                          borderRadius: BorderRadius.circular(50.0)),
                    ),
                    Divider(height: 5.0),
                    Flexible(
                        child: this.loading
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    CircularProgressIndicator(),
                                    Padding(
                                      padding: EdgeInsets.only(top: 20),
                                    ),
                                    Text(this.loadingMsg)
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: searchresult.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return Column(
                                    children: <Widget>[
                                      ListTile(
                                        leading: isPlaying && curr_id == index
                                            ? _position != null &&
                                                    _duration != null
                                                ? IconButton(
                                                    icon: Icon(Icons
                                                        .pause_circle_outline),
                                                    iconSize: 40.0,
                                                    color: Colors.black,
                                                    onPressed: () {
                                                      _stop();
                                                    },
                                                  )
                                                : CircularProgressIndicator()
                                            : IconButton(
                                                icon: Icon(
                                                    Icons.play_circle_outline),
                                                iconSize: 40.0,
                                                color: Colors.black,
                                                onPressed: () {
                                                  if (_position == null &&
                                                      _duration == null) {
                                                    _stop().then((res) {
                                                      print('after stopped.. : ${res}');
                                                      _play(
                                                          'http://54.200.143.85:4200/Audio/' +
                                                              searchresult[
                                                                      index]
                                                                  .toString(),
                                                          index);
                                                    });
                                                  } else {
                                                    _play(
                                                        'http://54.200.143.85:4200/Audio/' +
                                                            searchresult[index]
                                                                .toString(),
                                                        index);
                                                  }
                                                  // _play(
                                                  //     'http://54.200.143.85:4200/Audio/' +
                                                  //         searchresult[index]
                                                  //             .toString(),
                                                  //     index);
                                                },
                                              ),
                                        title: Text(
                                          searchresult[index]
                                              .toString()
                                              .replaceAll('.mp3', ''),
                                          style: TextStyle(fontSize: 18.0),
                                        ),
                                        trailing: GestureDetector(
                                            child: ClipOval(
                                          child: Container(
                                              child: IconButton(
                                            icon: new Image.asset(
                                                "assets/video_call_inactive.png"),
                                            iconSize: 25.0,
                                            // color: Colors.black,
                                            onPressed: () {
                                              Fluttertoast.showToast(
                                                msg: "Downloading...",
                                              );
                                              checkDuration(
                                                  'http://54.200.143.85:4200/Audio/' +
                                                      searchresult[index]
                                                          .toString(),
                                                  index);
                                            },
                                          )),
                                        )),
                                      ),
                                      Divider()
                                    ],
                                  );
                                })),
                  ])
                ],
              ));
  }

  getSongs() async {
    var response = await http.post(
      "http://54.200.143.85:4200/getAudioList",
      headers: {"Content-Type": "application/json"},
    );
    var res = jsonDecode(response.body);
    print('Song res: ${res}');
    setState(() {
      this.songList = res;
      this.searchresult = this.songList;
      this.loading = false;
      this.loadingMsg = "";
    });
  }

  checkDuration(url, idx) async {
    setState(() {
      donloadSongLoading = true;
    });
    final result = await _audioPlayer.play(url, volume: 0.0);
    if (result == 1) {
      setState(() {
        sendUrl = url;
        isCheckDuration = true;
      });
    } else {
      print('error is : ${_duration}');
    }
  }

  // Future<int>
  _play(url, idx) async {
    print("play url----------------------: ${url} && index : ${idx}");
    final playPosition = (_position != null &&
            _duration != null &&
            _position.inMilliseconds > 0 &&
            _position.inMilliseconds < _duration.inMilliseconds)
        ? _position
        : null;
    print('playPosition : ${playPosition}');

    setState(() {
      _position = null;
      _duration = null;
    });

    final result = await _audioPlayer.play(url);
    print('result: ${result}');
    if (result == 1) {
      setState(() {
        isPlaying = true;
        _playerState = PlayerState.playing;
        curr_id = idx;
      });
    } else {
      print('play failed .. result : ${result}');
    }
  }

  Future<int> _stop() async {
    print("stop url----- ");
    final result = await _audioPlayer.stop();
    if (result == 1) {
      setState(() {
        isPlaying = false;
        _playerState = PlayerState.stopped;
        _position = new Duration();
      });
    }
    return result;
  }

  Future<dynamic> download(String url) async {
    print('send------- ${url}');
    print('duration------- ${_duration}');

    applicationDir = (await getApplicationDocumentsDirectory()).path;
    String songnm = url.replaceAll('http://54.200.143.85:4200/Audio/', '');
    String dir = '$applicationDir${Config.musicDownloadFolderPath}';
    print('getApplicationDocumentsDirectory :  ${dir}');
    String trimmedsongname = songnm.replaceAll(new RegExp(r"\s+\b|\b\s"), "");
    File file = new File('$dir/$trimmedsongname');
    if (file.existsSync()) {
      var returnObject = [];
      returnObject.add(file.path);
      returnObject.add(_duration);
      Navigator.pop(context, returnObject
          // file.path
          );
    }
    var request = await http.get(
      url,
    );
    var bytes = await request.bodyBytes;
    await file.writeAsBytes(bytes);
    print("final path :  " + file.path);
    Fluttertoast.showToast(
      msg: "Download Completed",
    );
    var returnObject = [];
    returnObject.add(file.path);
    returnObject.add(_duration);
    Navigator.pop(context, returnObject
        // file.path,
        );
  }

  // song search
  void searchOperation(String searchText) {
    this.searchresult = [];

    //now iterate for song list
    for (int i = 0; i < this.songList.length; i++) {
      String data = this.songList[i];
      if (data.toLowerCase().contains(searchText.toLowerCase())) {
        searchresult.add(this.songList[i]);
      }
    }
    setState(() {
      this.typing = true;
    });
  }
}
