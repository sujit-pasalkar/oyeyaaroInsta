import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import '../models/config.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  bool loading = true;
  String loadingMsg = "Loading Songs..";

  AudioPlayer _audioPlayer;
  Duration _duration;
  Duration _position;
  String applicationDir;

  bool isPlaying = false;

  int currentId = -1;

  @override
  void initState() {
    AudioPlayer.logEnabled = true;
    _initAudioPlayer();
    getSongs();
    super.initState();
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
      setState(() {
        _duration = Duration(seconds: 0);
        _position = Duration(seconds: 0);
      });
    };
  }

  void onComplete() {
    setState(() {
      isPlaying = false;
    });
    playNext();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
          title: Text('Songs'),
          backgroundColor: Color(0xffb00bae3),
        ),
        body: Stack(
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
                                  leading: isPlaying && currentId == index
                                      ? IconButton(
                                          icon:
                                              Icon(Icons.pause_circle_outline),
                                          iconSize: 40.0,
                                          color: Colors.black,
                                          onPressed: () {
                                            _stop();
                                          },
                                        )
                                      : IconButton(
                                          icon: Icon(Icons.play_circle_outline),
                                          iconSize: 40.0,
                                          color: Colors.black,
                                          onPressed: () {
                                            _play(
                                                'http://oyeyaaroapi.plmlogix.com/Audio/' +
                                                    searchresult[index]
                                                        .toString(),
                                                index);
                                          },
                                        ),
                                  title: Text(
                                    searchresult[index]
                                        .toString()
                                        .replaceAll('.mp3', ''),
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                  trailing: ClipOval(
                                    child: Container(
                                      child: IconButton(
                                        icon: new Image.asset(
                                            "assets/video_call_inactive.png"),
                                        iconSize: 25.0,
                                        onPressed: () async {
                                          Fluttertoast.showToast(
                                            msg: "Downloading...",
                                          );
                                          String path = await download(
                                              'http://oyeyaaroapi.plmlogix.com/Audio/' +
                                                  searchresult[index]
                                                      .toString());
                                          Navigator.pop(context, path);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                Divider()
                              ],
                            );
                          })),
              isPlaying
                  ? Container(
                      padding: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: Color(0xffb00bae3)),
                      height: 55,
                      child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              searchresult[currentId][0],
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25),
                            ),
                          ),
                          title: Container(
                            width: width / 2,
                            child: Text(
                              searchresult[currentId]
                                  .toString()
                                  .replaceAll('.mp3', ''),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _position != null && _duration != null
                                ? <Widget>[
                                    IconButton(
                                      icon: Icon(Icons.skip_previous),
                                      iconSize: 35.0,
                                      color: Colors.black,
                                      onPressed: () {
                                        playPrev();
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.pause),
                                      iconSize: 35.0,
                                      color: Colors.black,
                                      onPressed: () {
                                        _stop();
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.skip_next),
                                      iconSize: 35.0,
                                      color: Colors.black,
                                      onPressed: () {
                                        playNext();
                                      },
                                    )
                                  ]
                                : <Widget>[CircularProgressIndicator()],
                          )),
                    )
                  : SizedBox(
                      height: 0.0,
                      width: 0.0,
                    )
            ])
          ],
        ));
  }

  getSongs() async {
    var response = await http.post(
      "http://oyeyaaroapi.plmlogix.com/getAudioList",
      headers: {"Content-Type": "application/json"},
    );
    var res = jsonDecode(response.body);
    setState(() {
      this.songList = res;
      this.searchresult = this.songList;
      this.loading = false;
      this.loadingMsg = "";
    });
  }

  _play(url, idx) async {
    await _audioPlayer.stop();
    setState(() {
      _position = null;
      _duration = null;
    });

    String path = await download(url);

    final result = await _audioPlayer.play(path);
    if (result == 1) {
      setState(() {
        isPlaying = true;
        currentId = idx;
      });
    } else {
      print('play failed .. result : $result');
    }
  }

  Future<int> _stop() async {
    final result = await _audioPlayer.stop();
    if (result == 1) {
      setState(() {
        isPlaying = false;
        _position = new Duration();
      });
    }
    return result;
  }

  Future<dynamic> download(String url) async {
    applicationDir = (await getExternalStorageDirectory()).path;
    String songnm = url.replaceAll('http://oyeyaaroapi.plmlogix.com/Audio/', '');
    String dir = '$applicationDir/OyeYaaro${Config.musicDownloadFolderPath}';
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
    Fluttertoast.showToast(
      msg: "Download Completed",
    );
    return file.path;
  }

  void searchOperation(String searchText) {
    this.searchresult = [];
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

  playNext() {
    if (currentId + 1 < searchresult.length && currentId + 1 >= 0) {
      setState(() {
        currentId = currentId + 1;
      });
      _play(
          'http://oyeyaaroapi.plmlogix.com/Audio/' +
              searchresult[currentId].toString(),
          currentId);
    } else {
      setState(() {
        currentId = 0;
      });
      _play(
          'http://oyeyaaroapi.plmlogix.com/Audio/' +
              searchresult[currentId].toString(),
          currentId);
    }
  }

  playPrev() {
    if (currentId - 1 < searchresult.length && currentId - 1 >= 0) {
      setState(() {
        currentId = currentId - 1;
      });
      _play(
          'http://oyeyaaroapi.plmlogix.com/Audio/' +
              searchresult[currentId].toString(),
          currentId);
    } else {
      setState(() {
        currentId = searchresult.length - 1;
      });
      _play(
          'http://oyeyaaroapi.plmlogix.com/Audio/' +
              searchresult[currentId].toString(),
          currentId);
    }
  }
}
