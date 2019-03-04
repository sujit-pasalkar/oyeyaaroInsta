import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import '../../../models/user.dart';
import '../../../models/group_model.dart';
import 'package:http/http.dart' as http;
import '../../../audioModule/views/recordClip.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioRecordingScreen extends StatefulWidget {
  final ScrollController hideButtonController;

  AudioRecordingScreen({@required this.hideButtonController, Key key})
      : super(key: key);
  @override
  _AudioRecordingScreenState createState() => _AudioRecordingScreenState();
}

enum PlayerState { stopped, playing, paused }

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  static const platform = const MethodChannel('plmlogix.recordvideo/info');

  Directory directory;

  List<bool> showShareAudioCheckBox = <bool>[];
  List<GroupModel> groupList;
  File audioFile;
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  List<String> selectedIndexes = [];

  AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration;
  Duration _position;

  int currentId = -1;

  bool isPlaying = false;

  List<String> tracks;

  @override
  void initState() {
    super.initState();
    directory = new Directory('/storage/emulated/0/OyeYaaro/Audios');
    if(!directory.existsSync()){
     directory.createSync(recursive: true);
   }
    _audioPlayer = new AudioPlayer();

    _audioPlayer.durationHandler = (d) => setState(() {
          _duration = d;
        });

    _audioPlayer.positionHandler = (p) => setState(() {
          _position = p;
        });

    _audioPlayer.completionHandler = () {
      setState(() {
        _playerState = PlayerState.stopped;
        isPlaying = false;
      });
      playNext();
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

  @override
  void dispose(){
    super.dispose();
    _audioPlayer.stop();
  }

  @override
  void deactivate(){
    super.deactivate();
    _audioPlayer.stop();
  }

  Future<List<String>> listDir() async {
    List<String> audios = <String>[];
    bool exists = await directory.exists();

    if (exists) {
      directory.listSync(recursive: true, followLinks: true).forEach((f) {
        if (f.path.toString().endsWith('.mp3')) {
          audios.add(f.path);
          showShareAudioCheckBox.add(false);
        }
      });

      setState(() {
        tracks = audios;
      });
      return audios;
    } else {
      setState(() {
        tracks = [];
      });
      audios.add('empty');
      return audios;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: this.selectedIndexes.length == 0
          ? null
          : AppBar(
              title: Text("Oye Yaaro"),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteAudios();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    shareAudio();
                  },
                ),
                this.selectedIndexes.length == 1
                    ? IconButton(
                        icon: Icon(Icons.mobile_screen_share),
                        onPressed: () {
                          share();
                        },
                      )
                    : Text('')
              ],
              backgroundColor: Color(0xffb00bae3),
            ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: new FutureBuilder<List<String>>(
              future: listDir(),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.hasError)
                  return Text("Error => ${snapshot.error}");
                return snapshot.hasData
                    ? body(snapshot.data)
                    : Center(child: CircularProgressIndicator());
              },
            ),
          ),
          isPlaying
              ? Container(
                  padding: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: Color(0xffb00bae3)),
                  height: 55,
                  child: ListTile(
                    title: Container(
                      child: Text(
                        tracks[currentId].split("/").last,
                        overflow: TextOverflow.fade,
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
                    ),
                  ),
                )
              : SizedBox(
                  height: 0.0,
                  width: 0.0,
                )
        ],
      ),
      floatingActionButton: isPlaying
          ? null
          : FloatingActionButton(
              backgroundColor: Color(0xffb00bae3),
              child: Icon(
                Icons.mic,
                size: 35.0,
              ),
              onPressed: () {
                openRecorder();
              },
            ),
    );
  }

  share() async {
    MethodChannel platform = const MethodChannel("plmlogix.recordvideo/info");
    for (String audio in this.selectedIndexes) {
      Map<String, String> data = <String, String>{
        'title': 'shareVideo',
        'path': audio,
      };
      try {
        await platform.invokeMethod('shareVideo', data);
      } catch (e) {
        print(e);
      }
    }
  }

  Widget body(dataList) {
    if (dataList.length != 0) {
      return Container(
        padding: EdgeInsets.only(top: 5.0),
        child: ListView(
          children: tracksBuilder(dataList),
        ),
      );
    } else {
      return Center(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.folder,
                size: 80.0,
                color: Color(0xffb00bae3),
              ),
              Text(
                'Folder is Empty',
                style: TextStyle(color: Color(0xffb00bae3)),
              ),
            ],
          ),
        ),
      );
    }
  }

  List<Widget> tracksBuilder(dataList) {
    List<Widget> tracks = <Widget>[];
    for (int i = 0; i < dataList.length; i++) {
      tracks.add(
        ListTile(
          leading: Icon(
            Icons.music_note,
            size: 40.0,
            color: Colors.black,
          ),
          title: Text(dataList[i].split("/").last),
          trailing: isPlaying && currentId == i
              ? IconButton(
                  icon: Icon(Icons.pause_circle_outline),
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
                    _play(dataList[i], i);
                  },
                ),
        ),
      );
      tracks.add(Divider());
      if (i == dataList.length - 1) {
        tracks.add(SizedBox(height: 60.0));
      }
    }
    return tracks;
  }

  addToSelectedIndexes(audio, i) {
    setState(() {
      showShareAudioCheckBox[i] = !showShareAudioCheckBox[i];
    });
    this.selectedIndexes.add(audio);
  }

  removeFromSelectedIndexes(audio, i) {
    setState(() {
      showShareAudioCheckBox[i] = !showShareAudioCheckBox[i];
    });
    this.selectedIndexes.remove(audio);
  }

  deleteAudios() {
    for (String audio in this.selectedIndexes) {
      File f = new File.fromUri(Uri.file(audio));
      f.delete();
    }

    for (var i = 0; i < this.showShareAudioCheckBox.length; i++) {
      this.showShareAudioCheckBox[i] = false;
    }

    setState(() {
      this.selectedIndexes = [];
    });
  }

  _play(url, idx) async {
    setState(() {
      _position = null;
      _duration = null;
    });

    final result = await _audioPlayer.play(url);
    if (result == 1) {
      setState(() {
        isPlaying = true;
        _playerState = PlayerState.playing;
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
        _playerState = PlayerState.stopped;
        _position = new Duration();
      });
    }
    return result;
  }

  playNext() {
    if (currentId + 1 < tracks.length && currentId + 1 >= 0) {
      setState(() {
        currentId = currentId + 1;
      });
      _play(tracks[currentId], currentId);
    } else {
      setState(() {
        currentId = 0;
      });
      _play(tracks[currentId], currentId);
    }
  }

  playPrev() {
    if (currentId - 1 < tracks.length && currentId - 1 >= 0) {
      setState(() {
        currentId = currentId - 1;
      });
      _play(tracks[currentId], currentId);
    } else {
      setState(() {
        currentId = tracks.length - 1;
      });
      _play(tracks[currentId], currentId);
    }
  }

  shareAudio() {
    showModalBottomSheet(
        context: context,
        builder: (builder) {
          return new Container(
              height: 200.0,
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'Share with Groups',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 5.0),
                  FutureBuilder<List<GroupModel>>(
                    future: fetchGroups(http.Client()),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        print("Error....${snapshot.error}");
                      return snapshot.hasData
                          ? Expanded(
                              child: groupListView(
                              snapshot.data,
                            ))
                          : Center(child: CircularProgressIndicator());
                    },
                  )
                ],
              ));
        }).then((onValue) {
      setState(() {});
    });
  }

  Widget groupListView(
    data,
  ) {
    groupList = data;
    return ListView.builder(
        shrinkWrap: true,
        itemCount: data.length,
        padding: const EdgeInsets.all(5.0),
        itemBuilder: (context, position) {
          return Column(
            children: <Widget>[
              ListTile(
                leading: Container(
                  width: 40.0,
                  height: 40.0,
                  margin: EdgeInsets.all(1.0),
                  decoration: BoxDecoration(
                    color: Color(0xffb00bae3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.group,
                    color: Colors.white,
                    size: 25.0,
                  ),
                ),
                title: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new Text(
                      '${data[position].name}',
                      style: new TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                onTap: () => _onTapGroup(
                      context,
                      position,
                    ),
              ),
              Divider(height: 5.0),
            ],
          );
        });
  }

  Future _onTapGroup(
    context,
    position,
  ) async {
    Navigator.pop(context);
    setState(() {});
    final snackBar = SnackBar(
      content: Text('Sending..'),
    );
    _scaffoldKey.currentState.showSnackBar(snackBar);

    for (String audio in this.selectedIndexes) {
      var result = await http.get('http://54.200.143.85:4200/time');
      var res = jsonDecode(result.body);
      var timestamp = res['timestamp'];

      audioFile = new File(audio);

      var stream =
          new http.ByteStream(DelegatingStream.typed(audioFile.openRead()));
      var length = await audioFile.length();
      var uri = Uri.parse("http://54.200.143.85:4200/uploadAudio");
      var request = new http.MultipartRequest("POST", uri);

      request.headers["time"] = timestamp;
      request.headers["dialogId"] = groupList[position].ids;
      request.headers["senderId"] = currentUser.userId;
      request.headers["type"] = "group";

      var multipartFile =
          new http.MultipartFile('file', stream, length, filename: "Hello");
      request.files.add(multipartFile);

      var response = await request.send();
      response.stream.transform(utf8.decoder).listen((value) {
        print('audio uploaded seccuss..');
      });

      var documentReference = Firestore.instance
          .collection('groups')
          .document(this.groupList[position].ids)
          .collection(this.groupList[position].ids)
          .document(timestamp);

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'senderId': currentUser.userId,
            'idTo': this.groupList[position].ids,
            'timestamp': timestamp,
            'msg':
                "http://54.200.143.85:4200/Media/Audios/${groupList[position].ids}/${timestamp}.mp3",
            'type': 2,
            'members': '',
            'senderName': currentUser.username,
            'groupName': this.groupList[position].name,
          },
        );
      }).then((onValue) {});
    }

    for (var i = 0; i < this.showShareAudioCheckBox.length; i++) {
      this.showShareAudioCheckBox[i] = false;
    }

    setState(() {
      this.selectedIndexes = [];
    });
  }

  getGroupsMember(peerId) async {
    try {
      http.Response response = await http.post(
          "http://54.200.143.85:4200/getJoinedArray",
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"dialog_id": '${peerId}'}));
      var groupMembers = jsonDecode(response.body);
      if (groupMembers['success'] == true) {
        return groupMembers['data'];
      }
    } catch (e) {}
  }

  Future<void> openRecorder() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RecordClip()),
    );
  }
}
