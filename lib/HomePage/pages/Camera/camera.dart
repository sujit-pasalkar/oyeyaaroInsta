import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../HomePage/ChatPage/playVideo.dart';
import '../../../models/group_model.dart';
import '../../../models/user.dart';
import 'package:http/http.dart' as http;
import '../../../cameraModule/views/recordClip.dart';
import '../../../ProfilePage/profile.dart';

class CameraScreen extends StatefulWidget {
  final ScrollController hideButtonController;

  CameraScreen({@required this.hideButtonController, Key key})
      : super(key: key);
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const platform = const MethodChannel('plmlogix.recordvideo/info'); //1
  Directory directory;
  Directory thumbailDirectory;

  List<bool> showShareVideoCheckBox = <bool>[];
  List<GroupModel> groupList;
  File videoFile;
  SharedPreferences prefs;
  String myId;
  String myName;
  String userPhone;
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  //share video to group 
  List<String> selectedIndexes = [];

  @override
  void initState() {
    super.initState();
    directory = new Directory('/storage/emulated/0/OyeYaaro/Videos');
    readLocal();
  }

  Future<List<String>> listDir() async {
    print(
        'inlistDir() ...*****************************************:${showShareVideoCheckBox.length}');
    print('1.DIR *** ${directory}');
    List<String> videos = <String>[];
    var exists = await directory.exists();
    print('2.exist ');

    if (exists) {
      print('showShareVideoCheckBox::${showShareVideoCheckBox.length}');
      print('videos::${videos.length}');

      directory.listSync(recursive: true, followLinks: true).forEach((f) {
        print("3.PATH*****:" + f.path);
        if (f.path.toString().endsWith('.mp4')) {
          print("***adding : ${f.path}");
          videos.add(f.path);
          showShareVideoCheckBox.add(false);
        }
      });
      print('Showvid:${showShareVideoCheckBox.length}');
      print('videos:${videos.length}');

      return videos;
    } else {
      videos.add('empty');
      print('ShowvisL:${showShareVideoCheckBox.length}');
      return videos;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: this.selectedIndexes.length == 0
          ? AppBar(
              title: Text("Oye Yaaro"),
              actions: <Widget>[
                _menuBuilder(),
              ],
              backgroundColor: Color(0xffb00bae3),
            )
          : AppBar(
              title: Text("Oye Yaaro"),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteVideos();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    shareVideo();
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
        ],
      ),
      floatingActionButton: new FloatingActionButton(
        backgroundColor: Color(0xffb00bae3),
        child: 
        Image(
          image: new AssetImage("assets/video_call.png"),
          width: 25.0,
          height: 25.0,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        ),
        // Icon(
        //   Icons.camera_alt,
        //   color: Colors.white,
        //   size: 25.0,
        // ),
        onPressed: () {
          //write function logic here
          opneCamera(); //3 //userPhone
        },
      ),
    );
  }

  share() async {
    var platform = const MethodChannel("plmlogix.recordvideo/info");
    for (var video in this.selectedIndexes) {
      print('share: ${video}');
      var data = <String, String>{
        'title': 'shareVideo',
        'path': video,
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
      if (dataList[0] == 'empty') {
        // return Center(
        //   child: Text('${directory.toString()} Path not Exist'),
        // );
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
              'Folder Not Found',
              style: TextStyle(color: Color(0xffb00bae3)),
            ),
          ],
        ),
      ));
      } else {
        return GridView.count(
          primary: false,
          padding: EdgeInsets.all(8.0),
          crossAxisSpacing: 8.0,
          crossAxisCount: 2,
          controller: widget.hideButtonController,
          children: videoGrid(dataList),
        );
      }
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
      ));
    }
  }

  List<Widget> videoGrid(dataList) {
    List<Widget> btnlist = List<Widget>();
    for (var i = 0; i < dataList.length; i++) {
      print('dataList : ${dataList[i]}');
      btnlist.add(
        GestureDetector(
          onLongPress: this.showShareVideoCheckBox[i] != true
              ? () {
                  print('adding : ${i}, ${dataList[i]}');
                  addToSelectedIndexes(dataList[i], i);
                }
              : () {
                  print('removing : ${i}');
                  this.removeFromSelectedIndexes(dataList[i], i);
                },
          onTap: this.selectedIndexes.length == 0
              ? () {
                  print('videoName::${dataList[i]}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PlayScreen(url: dataList[i], type: 'file'),
                    ),
                  );
                }
              : this.showShareVideoCheckBox[i] != true
                  ? () {
                      print('adding : ${i}, ${dataList[i]}');
                      addToSelectedIndexes(dataList[i], i);
                    }
                  : () {
                      print('removing : ${i}');
                      this.removeFromSelectedIndexes(dataList[i], i);
                    },
          child: Container(
            margin: EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
                color: Colors.black,
                image: DecorationImage(
                  image: FileImage(
                    File('/storage/emulated/0/OyeYaaro/Thumbnails/' +
                        (dataList[i].toString().split("/").last)
                            .replaceAll('mp4', 'png')),
                  ),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(10.0)),
            child: GestureDetector(
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 0.0,
                    right: 0.0,
                    top: 0.0,
                    bottom: 0.0,
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                      right: 0.0,
                      top: 0.0,
                      child: showShareVideoCheckBox[i] == true
                          ? Icon(Icons.check_circle, color: Colors.white)
                          : Text("")
                      )
                ],
              ),
            ),
          ),
        ),
      );
    }
    return btnlist;
  }

  //new
  addToSelectedIndexes(video, i) {
    setState(() {
      showShareVideoCheckBox[i] = !showShareVideoCheckBox[i];
    });
    this.selectedIndexes.add(video);
    print('selected vid: ${this.selectedIndexes}');
  }

  removeFromSelectedIndexes(video, i) {
    setState(() {
      showShareVideoCheckBox[i] = !showShareVideoCheckBox[i];
    });
    this.selectedIndexes.remove(video);
    print('${video.runtimeType}');
  }

  deleteVideos() {
    print('in delete vid');
    for (var video in this.selectedIndexes) {
      print('videos to delete : ${video}');
      File f = new File.fromUri(Uri.file(video));
      f.delete();
    }

    for (var i = 0; i < this.showShareVideoCheckBox.length; i++) {
      this.showShareVideoCheckBox[i] = false;
    }

    setState(() {
      this.selectedIndexes = [];
      print('after rm : ${selectedIndexes}');
    });
  }

  shareVideo() {
    print('calleed shareVideo()');
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
                              snapshot.data, /* video, i */
                            ))
                          : Center(child: CircularProgressIndicator());
                    },
                  )
                ],
              ));
        }).then((onValue) {
      setState(() {
      });
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
    //show loading true
    Navigator.pop(context);
    setState(() {
    });
    final snackBar = SnackBar(
      content: Text('Sending..'),
    );
    _scaffoldKey.currentState.showSnackBar(snackBar); //not work

    for (var video in this.selectedIndexes) {
      print('-----------------started......................');
      var result = await http.get('http://54.200.143.85:4200/time');
      var res = jsonDecode(result.body);
      print('TimeStamp got:-----${res['timestamp']}');
      var timestamp = res['timestamp'];
      print('TimeStamp set:-----${timestamp}');

      videoFile = new File(video);

      var stream =
          new http.ByteStream(DelegatingStream.typed(videoFile.openRead()));
      var length = await videoFile.length();
      var uri = Uri.parse("http://54.200.143.85:4200/uploadVideo");
      var request = new http.MultipartRequest("POST", uri);

      request.headers["time"] = timestamp;
      request.headers["dialogId"] = groupList[position].ids;
      request.headers["senderId"] = this.myId;
      request.headers["type"] = "group";

      var multipartFile =
          new http.MultipartFile('file', stream, length, filename: "Heloo");
      print(
          '${stream}..${length}..${uri}..${request}..${timestamp}..${groupList[position].ids}');
      request.files.add(multipartFile);
      // send
      var response = await request.send();
      // print(response.statusCode);
      response.stream.transform(utf8.decoder).listen((value) {
        print('video uploaded seccuss..');
        print(value);
      });
//
      print(
          '--->${this.groupList[position].ids}');
      var documentReference = Firestore.instance
          .collection('groups')
          .document(this.groupList[position].ids)
          .collection(this.groupList[position].ids)
          .document(
              timestamp);

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'senderId': this.myId,
            'idTo': this.groupList[position].ids,
            'timestamp': timestamp,
            'msg':
                "http://54.200.143.85:4200/Media/Videos/${groupList[position].ids}/${timestamp}.mp4",
            'type': 2,
            'members': '', //groupMembers,//err
            'senderName': this.myName,
            'groupName': this.groupList[position].name,
            'thumbnail': "http://54.200.143.85:4200/Media/Frames/" +
                this.groupList[position].ids +
                "/" +
                timestamp +
                "_1.jpg"
          },
        );
      }).then((onValue) {
        print('sent to firebase');
      });
    }

    print('---------All videos sent------------');
    for (var i = 0; i < this.showShareVideoCheckBox.length; i++) {
      this.showShareVideoCheckBox[i] = false;
    }

    setState(() {
      this.selectedIndexes = [];
      print('after rm : ${selectedIndexes}');
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
        print('Group members :res*****:${groupMembers['data']}');
        return groupMembers['data'];
      }
    } catch (e) {}
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    this.myId = prefs.getString('userPin') ?? ''; //id
    print('MY USER ID: ${this.myId}');
    this.myName = prefs.getString('userName');
    this.userPhone = prefs.getString('userPhone');

    setState(() {});
  }

  Future<void> opneCamera() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RecordClip()),
    );
    // print('came  back cameara...');
  }

  Widget _menuBuilder() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.white,
      ),
      tooltip: "Menu",
      onSelected: _onMenuItemSelect,
      itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'Profile',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0),
                child: Row(
                  children: <Widget>[
                    Text("Profile"),
                    Spacer(),
                    Icon(Icons.person),
                  ],
                ),
              ),
            ),
          ],
    );
  }

  _onMenuItemSelect(String option) {
    switch (option) {
      case 'Profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
                  userPin: currentUser.userId,
                ),
          ),
        );
        break;
    }
  }
}
