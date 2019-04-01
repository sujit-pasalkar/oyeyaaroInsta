import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connect_yaar/models/group_model.dart';
import '../const.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../groupInfoTabsPage.dart';
import '../../../feed/playVideo.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../feed/image_view.dart';
import 'package:flutter/services.dart';
import '../../../ProfilePage/profile.dart';
import '../../../ProfilePage/memberPictures.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import '../../../models/data-service.dart';
import 'package:thumbnails/thumbnails.dart';
import '../../pages/Network/network_screen.dart';
import '../../../cameraModule/controllers/commonFunctions.dart';
import '../../pages/New_Group/createNewGroup.dart';
import '../../pages/recording/getVideo.dart';

class Choice {
  const Choice({this.title, this.icon});
  final String title;
  final IconData icon;
}

//#for CustomApp bar(HEADER)
// class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final VoidCallback onTap;
//   final AppBar appBar;
//   const CustomAppBar({Key key, this.onTap, this.appBar}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(onTap: onTap, child: appBar);
//   }

//   // TODO: implement preferredSize
//   @override
//   Size get preferredSize => new Size.fromHeight(kToolbarHeight);
// }

class Chat extends StatefulWidget {
  final String peerId;
  final String chatType;
  final String name;
  final List<GroupModel> groupInfo;
  final String adminId;
  // final ScrollController hideButtonController;

  Chat({
    Key key,
    @required this.peerId,
    @required this.chatType,
    @required this.name,
    @required this.groupInfo,
    @required this.adminId,
    // @required this.hideButtonController
  }) : super(key: key);

  @override
  State createState() => new ChatScreenState(
      peerId: peerId,
      chatType: chatType,
      groupInfo: groupInfo,
      name: name,
      adminId: adminId);
}

enum PlayerState { stopped, playing, paused }

class ChatScreenState extends State<Chat> {
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  ScrollController hideButtonController;

  String peerId;
  String adminId;

  ChatScreenState({
    Key key,
    @required this.peerId,
    @required this.chatType,
    @required this.groupInfo,
    @required this.name,
    @required this.adminId,
    // @required this.hideButtonController
  }) {
    textEditingController.addListener(() {
      if (textEditingController.text.isEmpty) {
        setState(() {
          isSearching = false;
        });
      } else {
        setState(() {
          isSearching = true;
        });
      }
    });
  }

  int type = 10;

  //delete data
  bool isLongpressedForDelete = false;
  List<dynamic> indexesToDelete = [];
  List<dynamic> indexesToDeleteFrmAlbum = [];

  // vars
  var downloadedSongPath;
  final String name;
  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  bool isLoading;
  bool showShortSongs;
  bool showShortSongsLongSongs;

  String chatType;
  String myId;
  String myName;
  String id;
  String timestamp;

  List<GroupModel> groupInfo;
  var groupMembersArr = [];
  List<dynamic> listMessage = [];
  SharedPreferences prefs;

  File imageFile;
  String imageUrl;

  //#songList
  bool isPlaying = false;
  bool isSearching = false;
  List searchresult = new List();
  List songSearchresult2 = new List();

  List<dynamic> _songList1;
  List<dynamic> _songList2;

  bool textSending = false;

  String searchText = "";
  AudioPlayer audioPlayer;
  PlayerState playerState = PlayerState.stopped;
  Duration duration;
  Duration position;
  get songisPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;
  get durationText => duration?.toString()?.split('.')?.first ?? '';
  get positionText => position?.toString()?.split('.')?.first ?? '';
  String playingSongInList;

  @override
  void initState() {
    super.initState();
    getGroupsMember();
    isLoading = false;
    isSearching = false;
    imageUrl = '';
    timestamp = '';
    values();
    _initAudioPlayer();
    readLocal();
  }

  Future values() async {
    _songList1 = List();
    _songList2 = List();

    http.post(
      "http://oyeyaaroapi.plmlogix.com/getAudioListForChat",
      headers: {"Content-Type": "application/json"},
    ).then((response) {
      var res = jsonDecode(response.body);
      _songList1.addAll(res);
    });

    http.post(
      "http://oyeyaaroapi.plmlogix.com/getAudioList",
      headers: {"Content-Type": "application/json"},
    ).then((response) {
      var res = jsonDecode(response.body);
      _songList2.addAll(res);
    });
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return new Scaffold(
      key: _scaffoldKey,
      appBar: !isLongpressedForDelete && this.indexesToDelete.length == 0
          ? AppBar(
              title: GestureDetector(
                child: Text(this.name),
                onTap: () {
                  audioPlayer.stop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Members(
                            peerId: widget.peerId, groupName: widget.name)),
                  );
                },
              ),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.group_add),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GrpInfoTabsHome(
                              peerId: widget.peerId,
                              chatType: widget.chatType,
                              groupName: widget.name),
                        ));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/homepage', (Route<dynamic> route) => false);
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  tooltip: "Menu",
                  onSelected: onItemMenuPress,
                  itemBuilder: (BuildContext context) => adminId == myId
                      ? [
                          PopupMenuItem<String>(
                            value: 'Restore Media',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.0),
                              child: Row(
                                children: <Widget>[
                                  Text("Restore Media"),
                                  Spacer(),
                                  Icon(Icons.photo_library),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'Hide Media',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.0),
                              child: Row(
                                children: <Widget>[
                                  Text("Hide Media"),
                                  Spacer(),
                                  Icon(Icons.photo_size_select_large),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'Albums',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.0),
                              child: Row(
                                children: <Widget>[
                                  Text("Albums"),
                                  Spacer(),
                                  Icon(Icons.local_movies),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'Add Participants',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.0),
                              child: Row(
                                children: <Widget>[
                                  Text("Add Participants"),
                                  Spacer(),
                                  Icon(Icons.group_add),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'Delete Group',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.0),
                              child: Row(
                                children: <Widget>[
                                  Text("Delete Group"),
                                  Spacer(),
                                  Icon(Icons.delete),
                                ],
                              ),
                            ),
                          ),
                        ]
                      : [
                          PopupMenuItem<String>(
                            value: 'Restore Media',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.0),
                              child: Row(
                                children: <Widget>[
                                  Text("Restore Media"),
                                  Spacer(),
                                  Icon(Icons.photo_library),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'Hide Media',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.0),
                              child: Row(
                                children: <Widget>[
                                  Text("Hide Media"),
                                  Spacer(),
                                  Icon(Icons.photo_size_select_large),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'Albums',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.0),
                              child: Row(
                                children: <Widget>[
                                  Text("Albums"),
                                  Spacer(),
                                  Icon(Icons.local_movies),
                                ],
                              ),
                            ),
                          ),
                        ],
                )
              ],
              backgroundColor: Color(0xffb00bae3),
            )
          : new AppBar(
              title: Text(
                '${this.indexesToDelete.length.toString()}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteMsg();
                  },
                ),
              ],
              backgroundColor: Color(0xffb00bae3),
            ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                // List of messages

                buildListMessage(),

                songList(width), //short

                songlist2(width), //long

                // Input content
                buildInput(),
              ],
            ),

            // Loading
            buildLoading()
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  void onItemMenuPress(String choice) {
    switch (choice) {
      case 'Restore Media':
        {
          this.setPref(10);
        }
        break;
      case 'Hide Media':
        {
          this.setPref(0);
          // for (var i = 0; i < listMessage.length; i++) {
          //   // print(snapshot.data.documents[1]['type']);
          //   if(listMessage[i]['type'] == 1 ||listMessage[i]['type'] == 2){
          //     continue;
          //   }
          //   else{
          //     listMessage.add(listMessage[i]);
          //   }
          // }
        }
        break;
      case 'Delete Group':
        {
          deleteGroup();
        }
        break;
      case 'Albums':
        {
          audioPlayer.stop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NetworkScreen(
                    hideButtonController: hideButtonController,
                    dialogId: widget.peerId,
                  ),
            ),
          );
        }
        break;
      case 'Add Participants':
        {
          //call add member service
          //  addMember();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateNewGroup(
                    appBarName: "Add Participants",
                    groupName: widget.name,
                    groupId: widget.peerId,
                  ),
            ),
          );
        }
    }
  }

  // addMember()async {
  //   Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => NetworkScreen(
  //                   hideButtonController: hideButtonController,
  //                   dialogId: widget.peerId,
  //                 ),
  //           ),
  //         );
  // }

  deleteGp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPin = prefs.getString('userPin');

    http.Response response = await http.post(
        "http://oyeyaaroapi.plmlogix.com/deleteGroup",
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"dialog_id": peerId, "user_pin": userPin}));
    var res = jsonDecode(response.body);
    print('delete group res :$res');
    Navigator.pop(context);
  }

  //confirm delet group
  deleteGroup() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: Color(0xffb00bae3),
                padding: EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Text(
                      "Delete '${widget.name}' group?",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                height: 50,
                child: Row(
                  children: <Widget>[
                    SimpleDialogOption(
                      onPressed: () {
                        print('pressed cancel');
                        Navigator.pop(context, 0);
                      },
                      child: Row(
                        children: <Widget>[
                          Container(
                            child: Icon(
                              Icons.cancel,
                              color: Color(0xffb00bae3),
                            ),
                            margin: EdgeInsets.only(right: 10.0),
                          ),
                          Text(
                            'CANCEL',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        print('pressed yes');
                        Navigator.pop(context, 0);
                        deleteGp();
                      },
                      child: Row(
                        children: <Widget>[
                          Container(
                            child: Icon(
                              Icons.check_circle,
                              color: Color(0xffb00bae3),
                            ),
                            margin: EdgeInsets.only(right: 10.0),
                          ),
                          Text(
                            'DELETE',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        });
  }

  void _initAudioPlayer() {
    audioPlayer = new AudioPlayer();

    audioPlayer.durationHandler = (d) => setState(() {
          duration = d;
        });

    audioPlayer.positionHandler = (p) => setState(() {
          position = p;
        });

    audioPlayer.completionHandler = () {
      onComplete();
      setState(() {
        position = duration;
      });
    };

    audioPlayer.errorHandler = (msg) {
      // print('audioPlayer error : $msg');
      setState(() {
        playerState = PlayerState.stopped;
        duration = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    };
  }

  void onComplete() {
    setState(() {
      playerState = PlayerState.stopped;
      isPlaying = false;
    });
  }

  getGroupsMember() async {
    try {
      http.Response response = await http.post(
          "http://oyeyaaroapi.plmlogix.com/getJoinedArray",
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"dialog_id": '${widget.peerId}'}));
      var groupMembers = jsonDecode(response.body);
      if (groupMembers['success'] == true) {
        // print('Group members :res*****:${groupMembers['data']}');
        groupMembersArr = groupMembers['data'];
        // print('Group members :added*****:${groupMembers['data']}');
      }
    } catch (e) {}
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        // isShowSticker = false; //
      });
    }
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    this.myId = prefs.getString('userPin') ?? '';
    this.myName = prefs.getString('userName');
    this.type = prefs.getInt('hideChatMedia');
    setState(() {});
  }

  setPref(int value) async {
    print('$value is set');
    prefs = await SharedPreferences.getInstance();
    prefs.setInt('hideChatMedia', value);
    setState(() {
      this.type = prefs.getInt('hideChatMedia');
    });
  }

  Future getCameraImage() async {
    try {
      print('in getCameraImage');
      File compressedImage =
          await ImagePicker.pickImage(source: ImageSource.camera);

      int fileSize = await compressedImage.length();

      if ((fileSize / 1024) > 500) {
        imageFile = await FlutterNativeImage.compressImage(compressedImage.path,
            percentage: 75, quality: 75);
      } else {
        imageFile = compressedImage;
      }
      uploadImageFile(imageFile);
    } catch (e) {
      print('Err in getCameraImage: ' + e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future getGalleryImage() async {
    try {
      print('in getGalleryImage');
      File compressedImage =
          await ImagePicker.pickImage(source: ImageSource.gallery);

      int fileSize = await compressedImage.length();

      if ((fileSize / 1024) > 500) {
        imageFile = await FlutterNativeImage.compressImage(compressedImage.path,
            percentage: 75, quality: 75);
      } else {
        imageFile = compressedImage;
      }
      uploadImageFile(imageFile);
    } catch (e) {
      print('Err in getGalleryImage: ' + e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future getCameraVideo() async {
    try {
      setState(() {
        isLoading = true;
      });
      print('in get camera video');

      var originalVideoUrl =
          await ImagePicker.pickVideo(source: ImageSource.camera)
              .then((onValue) {
        return onValue;
      }).catchError((onError) {
        return null;
      });
      if (originalVideoUrl != null) {
        print('originalVideoUrl :  $originalVideoUrl');
        var fileSize = await originalVideoUrl.length();
        print("Original vedio file size: " +
            (fileSize / 1024).toString() +
            " KB");
        // if ((fileSize / 1024) <= 500000) { //70 mb
        CommonFunctions cmf = new CommonFunctions();
        cmf.compressVideo(originalVideoUrl.path).then((value) async {
          File imageFile = new File(value);
          fileSize = await imageFile.length();
          print("Compressed vedio file size: " +
              (fileSize / 1024).toString() +
              " KB");

          http.Response responseTime =
              await http.get('http://oyeyaaroapi.plmlogix.com/time');
          timestamp = jsonDecode(responseTime.body)['timestamp'];
          print('Got timestamp : $timestamp');
          uploadVideoFile(imageFile, timestamp);
        }).catchError((error) {
          print('Error Compressing: $error');
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg: 'Unable to upload this file');
        });
        // } else {
        //   setState(() {
        //     isLoading = false;
        //   });
        //   Fluttertoast.showToast(msg: 'Oops video size is greater than 500MB!');
        // }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('error while opening: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future getGalleryVideo() async {
    print('in get Gallery video');
    try {
      setState(() {
        isLoading = true;
      });

      var originalVideoUrl =
          await ImagePicker.pickVideo(source: ImageSource.gallery)
              .then((onValue) {
        return onValue;
      }).catchError((onError) {
        return null;
      });
      if (originalVideoUrl != null) {
        print('originalVideoUrl :  $originalVideoUrl');
        var fileSize = await originalVideoUrl.length();
        print("Original vedio file size: " +
            (fileSize / 1024).toString() +
            " KB");

        CommonFunctions cmf = new CommonFunctions();
        cmf.compressVideo(originalVideoUrl.path).then((value) async {
          File imageFile = new File(value);
          fileSize = await imageFile.length();
          print("Compressed vedio file size: " +
              (fileSize / 1024).toString() +
              " KB");

          http.Response responseTime =
              await http.get('http://oyeyaaroapi.plmlogix.com/time');
          timestamp = jsonDecode(responseTime.body)['timestamp'];
          print('Got timestamp : $timestamp');
          uploadVideoFile(imageFile, timestamp);
        }).catchError((error) {
          print('Error Compressing: $error');
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg: 'Unable to upload this file');
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }

      // var originalVideoUrl =
      //     await ImagePicker.pickVideo(source: ImageSource.gallery);
      // int fileSize = await originalVideoUrl.length();
      // print(
      //     "Original vedio file size: " + (fileSize / 1024).toString() + " KB");

      // CommonFunctions cmf = new CommonFunctions();
      // cmf.compressVideo(originalVideoUrl.path).then((value) async {
      //   imageFile = new File(value);
      //   int fileSize = await imageFile.length();
      //   print("Compressed vedio file size: " +
      //       (fileSize / 1024).toString() +
      //       " KB");
      //   if (imageFile != null) {
      //     http.Response responseTime =
      //         await http.get('http://oyeyaaroapi.plmlogix.com/time');
      //     timestamp = jsonDecode(responseTime.body)['timestamp'];
      //     print('Got timestamp : $timestamp');
      //     uploadVideoFile(imageFile, timestamp);
      //   }
      // }).catchError((error) {
      //   print('Error Compressing: $error');
      //   setState(() {
      //     isLoading = false;
      //   });
      //   Fluttertoast.showToast(msg: 'Unable to upload this file');
      // });

    } catch (e) {
      print('error while opening: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future uploadVideoFile(imageFile, timestamp) async {
    try {
      print('VideoFILE **: $imageFile');
      setState(() {
        this.isLoading = true;
      });

      //s3
      String mediaUrl = await dataService.uploadFileToS3(
          imageFile, 'videos/${widget.peerId}/' + timestamp, '.mp4');
      print('Uploaded to s3 url:$mediaUrl');

      //video thumb  s3
      String thumb = await Thumbnails.getThumbnail(
          thumbnailFolder: '/storage/emulated/0/OyeYaaro/.thumbnails',
          videoFile: imageFile.path,
          imageType: ThumbFormat.PNG,
          quality: 30);
      print('video thumbnail created');

      String thumbUrl = await dataService.uploadFileToS3(
          File(thumb), 'videos/${widget.peerId}/' + timestamp, ".jpeg");
      print('video thumbnail uploaded to s3: $thumbUrl');

      print("uploaded video mediaUrl: " + mediaUrl);
      print("uploaded video thumbUrl: " + thumbUrl);

      //call service
      http.Response response =
          await http.post("http://oyeyaaroapi.plmlogix.com/uploadVideos",
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "timestamp": timestamp,
                "dialogId": widget.peerId,
                "senderId": this.myId,
                "type": "group"
              }));
      print('uploadVideo service  res : $response');

      setState(() {
        onSendMessage(mediaUrl, 2, timestamp, thumbUrl);
      });
    } catch (e) {
      print('err while uploading : ${e}');
      setState(() {
        this.isLoading = false;
      });
    }
  }

  Future uploadImageFile(imageFile) async {
    print('upload img private : $imageFile');
    try {
      setState(() {
        this.isLoading = true;
      });
      http.Response responseTime =
          await http.get('http://oyeyaaroapi.plmlogix.com/time');
      timestamp = jsonDecode(responseTime.body)['timestamp'];

      String mediaUrl = await dataService.uploadFileToS3(imageFile,
          'images/${widget.peerId}/' + timestamp.toString(), '.jpeg');
      print('$mediaUrl');

      //call service
      http.Response response =
          await http.post("http://oyeyaaroapi.plmlogix.com/uploadImages",
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "timestamp": timestamp,
                "dialogId": widget.peerId,
                "senderId": this.myId,
                "type": "group"
              }));

      print('res: $response');

      setState(() {
        onSendMessage(mediaUrl, 1, timestamp);
      });
    } catch (e) {
      print('err while uploading : ${e}');
      setState(() {
        this.isLoading = false;
      });
    }
  }

  void onTextMessage(String content, int type) async {
    setState(() {
      textSending = true;
    });
    var result = await http.get('http://oyeyaaroapi.plmlogix.com/time');
    var res = jsonDecode(result.body);
    timestamp = res['timestamp'];

    if (content.trim() != '') {
      textEditingController.clear();
      var documentReference = Firestore.instance
          .collection('groups')
          .document(widget.peerId)
          .collection(widget.peerId)
          .document(timestamp);
      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'senderId': this.myId,
            'idTo': widget.peerId,
            'timestamp': timestamp,
            'msg': content,
            'type': type,
            'members': groupMembersArr,
            'senderName': this.myName,
            'groupName': widget.name
          },
        );
      }).then((onValue) {
        print('$content sent');
        setState(() {
          textSending = false;
        });
      });
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
      setState(() {
        textSending = false;
      });
    }
  }

  void onSendMessage(String content, int type, time, [thumbUrl]) {
    print('in ontextMsg.......send: $content');
    print('TimeStamp got in type():-----$type');
    print('TimeStamp got in time():-----$time');
    print('TimeStamp got in thumbUrl():-----$thumbUrl');

    if (content.trim() != '') {
      try {
        textEditingController.clear();

        var documentReference = Firestore.instance
            .collection('groups')
            .document(widget.peerId)
            .collection(widget.peerId)
            .document(time);

        if (type == 2) {
          Firestore.instance.runTransaction((transaction) async {
            await transaction.set(
              documentReference,
              {
                'senderId': this.myId,
                'idTo': widget.peerId,
                'timestamp': time,
                'msg': content,
                'type': type,
                'members': groupMembersArr,
                'senderName': this.myName,
                'groupName': widget.name,
                'thumbnail': thumbUrl,
              },
            );
          }).then((onValue) {
            setState(() {
              this.isLoading = false;
            });
          });
          listScrollController.animateTo(0.0,
              duration: Duration(milliseconds: 300), curve: Curves.easeOut);
        } else {
          //img
          Firestore.instance.runTransaction((transaction) async {
            await transaction.set(
              documentReference,
              {
                'senderId': this.myId,
                'idTo': widget.peerId,
                'timestamp': time,
                'msg': content,
                'type': type,
                'members': groupMembersArr,
                'senderName': this.myName,
                'groupName': widget.name
              },
            );
          }).then((onValue) {
            setState(() {
              this.isLoading = false;
            });
            print('image uploaded to firebase');
          });
        }
        listScrollController.animateTo(0.0,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      } catch (e) {
        print('image set errr: $e');
      }
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  Future<String> getTime(timestamp) async {
    http.Response responseTime =
        await http.get('http://oyeyaaroapi.plmlogix.com/time');

    var getTimestamp = jsonDecode(responseTime.body)['timestamp'];
    // print('ServerTimestamp $getTimestamp');

    int now = (DateTime.now().toLocal().millisecondsSinceEpoch / 1000).ceil();
    // print("PhoneNow-$now");

    // print("msgTimestamp:" + timestamp);

    int differenceInSeconds = now - int.parse(getTimestamp);
    // print("diff-$differenceInSeconds");

    getTimestamp = (int.parse(timestamp) + differenceInSeconds).toString();

    // print("ShowTime" +
    //     DateFormat('dd MMM kk:mm').format(DateTime.fromMillisecondsSinceEpoch(
    //         int.parse(getTimestamp) * 1000)));

    // print("PhoneTimw :" +
    //     DateFormat('dd MMM kk:mm')
    //         .format(DateTime.fromMillisecondsSinceEpoch(now * 1000)));

    return DateFormat('dd MMM kk:mm').format(
        DateTime.fromMillisecondsSinceEpoch(int.parse(getTimestamp) * 1000));
  }

  Widget buildItem(int index, DocumentSnapshot document) {
    if (document['senderId'] == this.myId) {
      // Right (my message)
      return Stack(
        children: <Widget>[
          Row(
            children: <Widget>[
              // Text
              document['type'] == 0
                  ? GestureDetector(
                      onLongPress: () {
                        adddeleteMsgIdx(index, document['timestamp'], 0);
                      },
                      child: Container(
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(document['senderName'],
                                      style: new TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                ),
                                FutureBuilder<String>(
                                  future: getTime(document['timestamp']),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    switch (snapshot.connectionState) {
                                      case ConnectionState.none:
                                        return Text(
                                            DateFormat('dd MMM kk:mm').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        int.parse(document[
                                                                'timestamp']) *
                                                            1000)),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic));
                                      case ConnectionState.active:
                                      case ConnectionState.waiting:
                                        return Text(
                                            DateFormat('dd MMM kk:mm').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        int.parse(document[
                                                                'timestamp']) *
                                                            1000)),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic));
                                      case ConnectionState.done:
                                        if (snapshot.hasError)
                                          return Text(
                                              DateFormat('dd MMM kk:mm').format(
                                                  DateTime
                                                      .fromMillisecondsSinceEpoch(
                                                          int.parse(document[
                                                                  'timestamp']) *
                                                              1000)),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12.0,
                                                  fontStyle: FontStyle.italic));
                                        return Text(
                                          snapshot.data,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic),
                                        );
                                    }
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle
                                                .italic)); // unreachable
                                  },
                                )
                              ],
                            ),
                            new Container(
                              margin: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                document['msg'],
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                        width: 200.0,
                        margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: greyColor2,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    )
                  : SizedBox(height: 0, width: 0),

              document['type'] == 1 && this.type == 10
                  // Image
                  ? GestureDetector(
                      onLongPress: () {
                        adddeleteMsgIdx(index, document['timestamp'], 1);
                      },
                      onTap: () {
                        audioPlayer.stop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewer(
                                  imageUrl: document['msg'],
                                ),
                          ),
                        );
                      },
                      child: Container(
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(document['senderName'],
                                      overflow: TextOverflow.ellipsis,
                                      style: new TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                ),
                                FutureBuilder<String>(
                                  future: getTime(document['timestamp']),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    switch (snapshot.connectionState) {
                                      case ConnectionState.none:
                                        return Text(
                                            DateFormat('dd MMM kk:mm').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        int.parse(document[
                                                                'timestamp']) *
                                                            1000)),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic));
                                      case ConnectionState.active:
                                      case ConnectionState.waiting:
                                        return Text(
                                            DateFormat('dd MMM kk:mm').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        int.parse(document[
                                                                'timestamp']) *
                                                            1000)),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic));
                                      case ConnectionState.done:
                                        if (snapshot.hasError)
                                          return Text(
                                              DateFormat('dd MMM kk:mm').format(
                                                  DateTime
                                                      .fromMillisecondsSinceEpoch(
                                                          int.parse(document[
                                                                  'timestamp']) *
                                                              1000)),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12.0,
                                                  fontStyle: FontStyle.italic));
                                        return Text(
                                          snapshot.data,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic),
                                        );
                                    }
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle
                                                .italic)); // unreachable
                                  },
                                )
                              ],
                            ),
                            Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.0)),
                            Material(
                              child: CachedNetworkImage(
                                placeholder: Container(
                                  child: CircularProgressIndicator(
                                      valueColor:
                                          new AlwaysStoppedAnimation<Color>(
                                              Color(0xffb00bae3))),
                                  padding: EdgeInsets.all(70.0),
                                  decoration: BoxDecoration(
                                    color: greyColor2,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8.0),
                                    ),
                                  ),
                                ),
                                errorWidget: Material(
                                  child: Image.asset(
                                    'images/no_img.png',
                                    width: 200.0,
                                    height: 200.0,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8.0),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                ),
                                imageUrl: document['msg'],
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8.0)),
                              clipBehavior: Clip.hardEdge,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                        width: 200.0,
                        margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                        ),
                        decoration: BoxDecoration(
                            color: greyColor2,
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                    )
                  : SizedBox(height: 0, width: 0),

              // Video
              document['type'] == 2 && this.type == 10
                  ? GestureDetector(
                      onLongPress: () {
                        adddeleteMsgIdx(index, document['timestamp'], 2);
                      },
                      onTap: () {
                        audioPlayer.stop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayVideo(
                                  mediaUrl: document['msg'],
                                ),
                          ),
                        );
                      },
                      child: Container(
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(document['senderName'],
                                      style: new TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                ),
                                FutureBuilder<String>(
                                  future: getTime(document['timestamp']),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    switch (snapshot.connectionState) {
                                      case ConnectionState.none:
                                        return Text(
                                            DateFormat('dd MMM kk:mm').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        int.parse(document[
                                                                'timestamp']) *
                                                            1000)),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic));
                                      case ConnectionState.active:
                                      case ConnectionState.waiting:
                                        return Text(
                                            DateFormat('dd MMM kk:mm').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        int.parse(document[
                                                                'timestamp']) *
                                                            1000)),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic));
                                      case ConnectionState.done:
                                        if (snapshot.hasError)
                                          return Text(
                                              DateFormat('dd MMM kk:mm').format(
                                                  DateTime
                                                      .fromMillisecondsSinceEpoch(
                                                          int.parse(document[
                                                                  'timestamp']) *
                                                              1000)),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12.0,
                                                  fontStyle: FontStyle.italic));
                                        return Text(
                                          snapshot.data,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic),
                                        );
                                    }
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle
                                                .italic)); // unreachable
                                  },
                                )
                              ],
                            ),
                            Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.0)),
                            Container(
                              width: double.infinity,
                              height: 142.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15.0),
                                ),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(document['thumbnail']),
                                ),
                              ),
                              child: Icon(
                                Icons.play_circle_filled,
                                size: 60.0,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        width: 250.0,
                        height: 180.0,
                        decoration: BoxDecoration(
                          color: greyColor2,
                          borderRadius: BorderRadius.all(
                            Radius.circular(15.0),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                        margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                          // right: 10.0
                        ),
                      ),
                    )
                  : SizedBox(height: 0, width: 0),
              // playSong  audio long....short
              document['type'] == 3
                  ? GestureDetector(
                      onLongPress: () {
                        adddeleteMsgIdx(index, document['timestamp'], 3);
                      },
                      onTapUp: (TapUpDetails details) {
                        isPlaying
                            ? stop()
                            : play(
                                document['msg'].toString(),
                                document['msg'].toString().replaceAll(
                                    'http://oyeyaaroapi.plmlogix.com/AudioChat/',
                                    ''));
                      },
                      child: Container(
                        height: 103.0,
                        width: 130.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                        ),
                        margin: EdgeInsets.only(
                            // bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                            ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(document['senderName'],
                                style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                            Container(
                              height: 60.0,
                              width: 60.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              child: playPauseIcon(document['msg']
                                      .toString()
                                      .replaceAll(
                                          'http://oyeyaaroapi.plmlogix.com/AudioChat/',
                                          ''))
                                  ? Container(
                                      margin: EdgeInsets.all(3),
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8.0),
                                        ),
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          LayoutBuilder(
                                              builder: (context, constraint) {
                                            return new Icon(
                                              Icons.pause,
                                              size: 40.0,
                                              color: Colors.white,
                                            );
                                          }),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      margin: EdgeInsets.all(3),
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8.0),
                                        ),
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          Image.asset('assets/short.png',
                                              width: 40.0, height: 40.0)
                                        ],
                                      ),
                                    ),
                            ),
                            FutureBuilder<String>(
                              future: getTime(document['timestamp']),
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.none:
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle.italic));
                                  case ConnectionState.active:
                                  case ConnectionState.waiting:
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle.italic));
                                  case ConnectionState.done:
                                    if (snapshot.hasError)
                                      return Text(
                                          DateFormat('dd MMM kk:mm').format(
                                              DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      int.parse(document[
                                                              'timestamp']) *
                                                          1000)),
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic));
                                    return Text(
                                      snapshot.data,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12.0,
                                          fontStyle: FontStyle.italic),
                                    );
                                }
                                return Text(
                                    DateFormat('dd MMM kk:mm').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            int.parse(document['timestamp']) *
                                                1000)),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12.0,
                                        fontStyle:
                                            FontStyle.italic)); // unreachable
                              },
                            )
                          ],
                        ),
                      ),
                    )
                  : SizedBox(height: 0, width: 0),
              document['type'] == 4
                  ?
                  // playSong  audio ...long   type = 4
                  GestureDetector(
                      onLongPress: () {
                        adddeleteMsgIdx(index, document['timestamp'], 4);
                      },
                      onTapUp: (TapUpDetails details) {
                        print("onTapUp");
                        isPlaying
                            ? stop()
                            : play(
                                document['msg'].toString(),
                                document['msg'].toString().replaceAll(
                                    'http://oyeyaaroapi.plmlogix.com/Audio/',
                                    ''));
                      },
                      child: Container(
                        height: 103.0,
                        width: 130.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                        ),
                        margin: EdgeInsets.only(
                            // bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                            ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(document['senderName'],
                                style: new TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                            Container(
                              height: 60.0,
                              width: 60.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              child: playPauseIcon(document['msg']
                                      .toString()
                                      .replaceAll(
                                          'http://oyeyaaroapi.plmlogix.com/Audio/',
                                          ''))
                                  ? Container(
                                      margin: EdgeInsets.all(3),
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8.0),
                                        ),
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          LayoutBuilder(
                                              builder: (context, constraint) {
                                            return new Icon(
                                              Icons.pause,
                                              size: 40.0,
                                              color: Colors.white,
                                            );
                                          }),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      margin: EdgeInsets.all(3),
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8.0),
                                        ),
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          LayoutBuilder(
                                              builder: (context, constraint) {
                                            return new Icon(
                                              Icons.music_note,
                                              size: 40.0,
                                              color: Colors.white,
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                            ),
                            FutureBuilder<String>(
                              future: getTime(document['timestamp']),
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.none:
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle.italic));
                                  case ConnectionState.active:
                                  case ConnectionState.waiting:
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle.italic));
                                  case ConnectionState.done:
                                    if (snapshot.hasError)
                                      return Text(
                                          DateFormat('dd MMM kk:mm').format(
                                              DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      int.parse(document[
                                                              'timestamp']) *
                                                          1000)),
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic));
                                    return Text(
                                      snapshot.data,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12.0,
                                          fontStyle: FontStyle.italic),
                                    );
                                }
                                return Text(
                                    DateFormat('dd MMM kk:mm').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            int.parse(document['timestamp']) *
                                                1000)),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12.0,
                                        fontStyle:
                                            FontStyle.italic)); // unreachable
                              },
                            )
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 0,
                      width: 0,
                    )
            ],
            mainAxisAlignment: MainAxisAlignment.end,
          ),
          this.isLongpressedForDelete &&
                  this.indexesToDelete.contains(document['timestamp'])
              ? GestureDetector(
                  onTap: () {
                    removeFrmIndexesToDelete(document['timestamp']);
                  },
                  child: Container(
                    height: document['type'] == 0
                        ? 50.0
                        : document['type'] == 1
                            ? 240.0
                            : document['type'] == 2
                                ? 180.0
                                : document['type'] == 3
                                    ? 103.0
                                    : document['type'] == 4 ? 103.0 : 0.0,
                    width: 500,
                    color: Colors.lightBlue[200].withOpacity(0.5),
                  ),
                )
              : SizedBox(height: 0, width: 0)
        ],
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastMessageLeft(
                        index) //&& ((document['type'] != 1 ||document['type'] != 2) || this.type == 10)
                    ? this.type == 10
                        ? new GestureDetector(
                            onTap: () {
                              print('open this user profile');
                              audioPlayer.stop();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ProfilePage(
                                          userPin: document['senderId'])));
                            },
                            child: new Container(
                              width: 50.0,
                              height: 50.0,
                              decoration: new BoxDecoration(
                                color: Color(0xffb00bae3),
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                margin: EdgeInsets.all(1.5),
                                decoration: new BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                    margin: EdgeInsets.all(1.0),
                                    decoration: new BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[300],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(40.0),
                                      child: Image.network(
                                        'http://oyeyaaroapi.plmlogix.com/getAvatarImageNow/${document['senderId']}',
                                        fit: BoxFit.cover,
                                      ),
                                    )),
                              ),
                            ),
                          )
                        : (document['type'] == 1 || document['type'] == 2)
                            ? Container(width: 50.0)
                            : new GestureDetector(
                                onTap: () {
                                  print('open this user profile');
                                  audioPlayer.stop();
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ProfilePage(
                                              userPin: document['senderId'])));
                                },
                                child: new Container(
                                  width: 50.0,
                                  height: 50.0,
                                  decoration: new BoxDecoration(
                                    color: Color(0xffb00bae3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    margin: EdgeInsets.all(1.5),
                                    decoration: new BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Container(
                                        margin: EdgeInsets.all(1.0),
                                        decoration: new BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey[300],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(40.0),
                                          child: Image.network(
                                            'http://oyeyaaroapi.plmlogix.com/getAvatarImageNow/${document['senderId']}',
                                            fit: BoxFit.cover,
                                          ),
                                        )),
                                  ),
                                ),
                              )
                    : Container(width: 50.0),
                //txt

                document['type'] == 0
                    ? Container(
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(document['senderName'],
                                      style: new TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                ),
                                FutureBuilder<String>(
                                  future: getTime(document['timestamp']),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    switch (snapshot.connectionState) {
                                      case ConnectionState.none:
                                        return Text(
                                            DateFormat('dd MMM kk:mm').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        int.parse(document[
                                                                'timestamp']) *
                                                            1000)),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic));
                                      case ConnectionState.active:
                                      case ConnectionState.waiting:
                                        return Text(
                                            DateFormat('dd MMM kk:mm').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        int.parse(document[
                                                                'timestamp']) *
                                                            1000)),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic));
                                      case ConnectionState.done:
                                        if (snapshot.hasError)
                                          return Text(
                                              DateFormat('dd MMM kk:mm').format(
                                                  DateTime
                                                      .fromMillisecondsSinceEpoch(
                                                          int.parse(document[
                                                                  'timestamp']) *
                                                              1000)),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12.0,
                                                  fontStyle: FontStyle.italic));
                                        return Text(
                                          snapshot.data,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic),
                                        );
                                    }
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle
                                                .italic)); // unreachable
                                  },
                                )
                              ],
                            ),
                            new Container(
                              margin: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                document['msg'],
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                        width: 200.0,
                        decoration: BoxDecoration(
                            color: Colors.indigo[100],
                            borderRadius: BorderRadius.circular(8.0)),
                        margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 15.0 : 10.0,
                            left: 5.0),
                      )
                    : SizedBox(height: 0, width: 0),

                //img
                document['type'] == 1 && this.type == 10
                    ? GestureDetector(
                        onLongPress: () {
                          adddeleteMsgIdx(index, document['timestamp'], 1);
                        },
                        onTap: () {
                          audioPlayer.stop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageViewer(
                                    imageUrl: document['msg'],
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          child: new Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(document['senderName'],
                                        overflow: TextOverflow.ellipsis,
                                        style: new TextStyle(
                                            fontSize: 12.0,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  FutureBuilder<String>(
                                    future: getTime(document['timestamp']),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<String> snapshot) {
                                      switch (snapshot.connectionState) {
                                        case ConnectionState.none:
                                          return Text(
                                              DateFormat('dd MMM kk:mm').format(
                                                  DateTime
                                                      .fromMillisecondsSinceEpoch(
                                                          int.parse(document[
                                                                  'timestamp']) *
                                                              1000)),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12.0,
                                                  fontStyle: FontStyle.italic));
                                        case ConnectionState.active:
                                        case ConnectionState.waiting:
                                          return Text(
                                              DateFormat('dd MMM kk:mm').format(
                                                  DateTime
                                                      .fromMillisecondsSinceEpoch(
                                                          int.parse(document[
                                                                  'timestamp']) *
                                                              1000)),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12.0,
                                                  fontStyle: FontStyle.italic));
                                        case ConnectionState.done:
                                          if (snapshot.hasError)
                                            return Text(
                                                DateFormat('dd MMM kk:mm')
                                                    .format(DateTime
                                                        .fromMillisecondsSinceEpoch(
                                                            int.parse(document[
                                                                    'timestamp']) *
                                                                1000)),
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12.0,
                                                    fontStyle:
                                                        FontStyle.italic));
                                          return Text(
                                            snapshot.data,
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic),
                                          );
                                      }
                                      return Text(
                                          DateFormat('dd MMM kk:mm').format(
                                              DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      int.parse(document[
                                                              'timestamp']) *
                                                          1000)),
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle
                                                  .italic)); // unreachable
                                    },
                                  )
                                ],
                              ),
                              Padding(
                                  padding: EdgeInsets.symmetric(vertical: 5.0)),
                              Material(
                                child: CachedNetworkImage(
                                  placeholder: Container(
                                    child: CircularProgressIndicator(
                                        valueColor:
                                            new AlwaysStoppedAnimation<Color>(
                                                Color(0xffb00bae3))),
                                    padding: EdgeInsets.all(70.0),
                                    decoration: BoxDecoration(
                                      color: greyColor2,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                  errorWidget: Material(
                                    child: Image.asset(
                                      'images/no_img.png',
                                      width: 200.0,
                                      height: 200.0,
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8.0),
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                  ),
                                  imageUrl: document['msg'],
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                                clipBehavior: Clip.hardEdge,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                          width: 200.0,
                          margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 15.0 : 10.0,
                          ),
                          decoration: BoxDecoration(
                              color: Colors.indigo[100],
                              borderRadius: BorderRadius.circular(8.0)),
                        ),
                      )
                    : SizedBox(height: 0, width: 0),

                // video
                document['type'] == 2 && this.type == 10
                    ? Container(
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(document['senderName'],
                                      style: new TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                ),
                                FutureBuilder<String>(
                                  future: getTime(document['timestamp']),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    switch (snapshot.connectionState) {
                                      case ConnectionState.none:
                                        return Text(
                                            DateFormat('dd MMM kk:mm').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        int.parse(document[
                                                                'timestamp']) *
                                                            1000)),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic));
                                      case ConnectionState.active:
                                      case ConnectionState.waiting:
                                        return Text(
                                            DateFormat('dd MMM kk:mm').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        int.parse(document[
                                                                'timestamp']) *
                                                            1000)),
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic));
                                      case ConnectionState.done:
                                        if (snapshot.hasError)
                                          return Text(
                                              DateFormat('dd MMM kk:mm').format(
                                                  DateTime
                                                      .fromMillisecondsSinceEpoch(
                                                          int.parse(document[
                                                                  'timestamp']) *
                                                              1000)),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12.0,
                                                  fontStyle: FontStyle.italic));
                                        return Text(
                                          snapshot.data,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic),
                                        );
                                    }
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle
                                                .italic)); // unreachable
                                  },
                                )
                              ],
                            ),
                            Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.0)),
                            Container(
                              width: double.infinity,
                              height: 142.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15.0),
                                ),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(document['thumbnail']),
                                ),
                              ),
                              child: GestureDetector(
                                child: Icon(
                                  Icons.play_circle_filled,
                                  size: 60.0,
                                  color: Colors.white,
                                ),
                                onTap: () {
                                  audioPlayer.stop();
                                  print(
                                      'opening video : ${document['thumbnail']}');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlayVideo(
                                            mediaUrl: document['msg'],
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        width: 250.0,
                        height: 180.0,
                        decoration: BoxDecoration(
                          color: Colors.indigo[100],
                          borderRadius: BorderRadius.all(
                            Radius.circular(15.0),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                        margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 15.0 : 10.0,
                            left: 5.0),
                      )
                    : SizedBox(height: 0, width: 0),

                //audio long....short
                document['type'] == 3
                    ? Container(
                        height: 103.0,
                        width: 130.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                        ),
                        margin: EdgeInsets.only(
                            // bottom: isLastMessageRight(index) ? 5.0 : 10.0,
                            left: 5.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(document['senderName'],
                                      style: new TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            Container(
                              height: 60.0,
                              width: 60.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              child: GestureDetector(
                                child: playPauseIcon(document['msg']
                                        .toString()
                                        .replaceAll(
                                            'http://oyeyaaroapi.plmlogix.com/AudioChat/',
                                            ''))
                                    ? Container(
                                        margin: EdgeInsets.all(3),
                                        padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8.0),
                                          ),
                                        ),
                                        child: Column(
                                          children: <Widget>[
                                            LayoutBuilder(
                                                builder: (context, constraint) {
                                              return new Icon(
                                                Icons.pause,
                                                size: 40.0,
                                                color: Colors.white,
                                              );
                                            }),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        margin: EdgeInsets.all(3),
                                        padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8.0),
                                          ),
                                        ),
                                        child: Column(
                                          children: <Widget>[
                                            Image.asset('assets/short.png',
                                                width: 40.0, height: 40.0)
                                          ],
                                        ),
                                      ),
                                onTapUp: (TapUpDetails details) {
                                  print("onTapUp");
                                  isPlaying
                                      ? stop()
                                      : play(
                                          document['msg'].toString(),
                                          document['msg'].toString().replaceAll(
                                              'http://oyeyaaroapi.plmlogix.com/AudioChat/',
                                              ''));
                                },
                              ),
                            ),
                            FutureBuilder<String>(
                              future: getTime(document['timestamp']),
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.none:
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle.italic));
                                  case ConnectionState.active:
                                  case ConnectionState.waiting:
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle.italic));
                                  case ConnectionState.done:
                                    if (snapshot.hasError)
                                      return Text(
                                          DateFormat('dd MMM kk:mm').format(
                                              DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      int.parse(document[
                                                              'timestamp']) *
                                                          1000)),
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic));
                                    return Text(
                                      snapshot.data,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12.0,
                                          fontStyle: FontStyle.italic),
                                    );
                                }
                                return Text(
                                    DateFormat('dd MMM kk:mm').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            int.parse(document['timestamp']) *
                                                1000)),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12.0,
                                        fontStyle:
                                            FontStyle.italic)); // unreachable
                              },
                            )
                          ],
                        ),
                      )
                    : SizedBox(height: 0, width: 0),
//type 4....long
                document['type'] == 4
                    ? Container(
                        height: 103.0,
                        width: 130.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                        ),
                        margin: EdgeInsets.only(
                            // bottom: isLastMessageRight(index) ? 5.0 : 10.0,
                            left: 5.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(document['senderName'],
                                      style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            Padding(
                                padding: EdgeInsets.symmetric(vertical: 2.0)),
                            GestureDetector(
                              child: Row(
                                children: <Widget>[
                                  playPauseIcon(document['msg']
                                          .toString()
                                          .replaceAll(
                                              'http://oyeyaaroapi.plmlogix.com/Audio/',
                                              ''))
                                      ? Container(
                                          margin: EdgeInsets.all(3),
                                          padding: EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(8.0),
                                            ),
                                          ),
                                          child: Column(
                                            children: <Widget>[
                                              LayoutBuilder(builder:
                                                  (context, constraint) {
                                                return Icon(
                                                  Icons.pause,
                                                  size: 40.0,
                                                  color: Colors.white,
                                                );
                                              }),
                                            ],
                                          ),
                                        )
                                      : Container(
                                          margin: EdgeInsets.all(3),
                                          padding: EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(8.0),
                                            ),
                                          ),
                                          child: Column(
                                            children: <Widget>[
                                              LayoutBuilder(builder:
                                                  (context, constraint) {
                                                return Icon(
                                                  Icons.music_note,
                                                  size: 40.0,
                                                  color: Colors.white,
                                                );
                                              }),
                                            ],
                                          ),
                                        )
                                ],
                              ),
                              onTapUp: (TapUpDetails details) {
                                print("onTapUp");
                                isPlaying
                                    ? stop()
                                    : play(
                                        document['msg'].toString(),
                                        document['msg'].toString().replaceAll(
                                            'http://oyeyaaroapi.plmlogix.com/Audio/',
                                            ''));
                              },
                            ),
                            FutureBuilder<String>(
                              future: getTime(document['timestamp']),
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.none:
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle.italic));
                                  case ConnectionState.active:
                                  case ConnectionState.waiting:
                                    return Text(
                                        DateFormat('dd MMM kk:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                        document['timestamp']) *
                                                    1000)),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontStyle: FontStyle.italic));
                                  case ConnectionState.done:
                                    if (snapshot.hasError)
                                      return Text(
                                          DateFormat('dd MMM kk:mm').format(
                                              DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      int.parse(document[
                                                              'timestamp']) *
                                                          1000)),
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic));
                                    return Text(
                                      snapshot.data,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12.0,
                                          fontStyle: FontStyle.italic),
                                    );
                                }
                                return Text(
                                    DateFormat('dd MMM kk:mm').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            int.parse(document['timestamp']) *
                                                1000)),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12.0,
                                        fontStyle:
                                            FontStyle.italic)); // unreachable
                              },
                            )
                          ],
                        ),
                      )
                    : SizedBox(
                        height: 0,
                        width: 0,
                      )
              ],
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        // margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  bool playPauseIcon(songName) {
    print('--${songName}');
    if (songName == playingSongInList && isPlaying) {
      return true;
    } else
      return false;
  }

  //song play stop pause
  Future<int> play(url, songName) async {
    setState(() {
      position = null;
      duration = null;
    });
    final result = await audioPlayer.play(url, isLocal: false);
    if (result == 1)
      setState(() {
        playerState = PlayerState.playing;
        isPlaying = true;
        playingSongInList = songName;
      });
    return result;
  }

  Future<int> pause() async {
    final result = await audioPlayer.pause();
    if (result == 1) setState(() => playerState = PlayerState.paused);
    return result;
  }

  Future<int> stop() async {
    final result = await audioPlayer.stop();
    if (result == 1) {
      setState(() {
        playerState = PlayerState.stopped;
        position = new Duration();
        isPlaying = false;
      });
    }
    return result;
  }

  bool isLastMessageLeft(int index) {
    // if (this.type == 10) {
    if ((index >= 0 &&
            index < listMessage.length - 1 &&
            listMessage != null &&
            listMessage[index + 1]['senderName'] !=
                listMessage[index]['senderName']) ||
        (index == listMessage.length - 1 &&
            listMessage[index]['senderId'] != this.myId)) {
      return true;
    } else {
      return false;
    }
    // }else{
    //   if(
    //     (index >= 0 &&
    //           index < listMessage.length - 1 &&
    //           listMessage != null &&
    //           recursion(index))
    //           // listMessage[index + 1]['senderName'] !=
    //           //     listMessage[index]['senderName'])

    //                ||
    //       (index == listMessage.length - 1 &&
    //           listMessage[index]['senderId'] != this.myId)
    //   ){
    //     return true;
    //   }else{
    //   return false;
    //   }
    // }
  }

  // if ((index >= 0 &&
  //         index < listMessage.length - 1 &&
  //         listMessage != null &&
  //         listMessage[index + 1]['senderName'] !=
  //             listMessage[index]['senderName']) ||
  //     (index == listMessage.length - 1 &&
  //         listMessage[index]['senderId'] != this.myId)) {
  //   return true;
  // } else {
  //   return false;
  // }

  //  recursion(index){
  //    if((listMessage[index + 1]['type'] != 1 || listMessage[index + 1]['type'] != 2) && listMessage[index + 1]['senderName'] !=listMessage[index]['senderName']){
  //      print('not in recursion : ${index+1}');
  //     return true;
  //    }
  //    else{
  //      print('in recursion : ${index+1}');
  //      recursion(index+1);
  //    }
  //  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['senderId'] != id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    Navigator.pop(context);
    return Future.value(false);
  }

  songList(width) {
    //type 3
    if (isSearching) {
      return Container(
        color: Colors.deepPurple[50],
        height: 50.0,
        width: width,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: searchresult.length,
          itemBuilder: (BuildContext context, int index) {
            String listData = searchresult[index];
            return GestureDetector(
              child: Row(
                children: <Widget>[
                  playPauseIcon(listData)
                      ? position != null && duration != null
                          ? Icon(Icons.pause_circle_outline)
                          : SizedBox(
                              child: new CircularProgressIndicator(
                                  valueColor: new AlwaysStoppedAnimation(
                                      Color(0xffb00bae3)),
                                  strokeWidth: 1.0),
                              height: 20.0,
                              width: 20.0,
                            )
                      : Image.asset('assets/short.png',
                          width: 25.0, height: 25.0),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 5.0, 0.0),
                  ),
                  Text(
                    listData.replaceAll('.mp3', ''),
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 15.0, 0.0),
                  )
                ],
              ),
              onTapUp: (TapUpDetails details) {
                print("onTapUp");
                isPlaying
                    ? stop()
                    : play(
                        "http://oyeyaaroapi.plmlogix.com/AudioChat/" +
                            listData.toString(),
                        listData);
              },
              onLongPress: () {
                print("onLongPress");
                onTextMessage(
                    "http://oyeyaaroapi.plmlogix.com/AudioChat/" +
                        listData.toString(),
                    3);
              },
            );
          },
        ),
      );
    } else
      return Container();
    // Text('');
  }

  songlist2(width) {
    if (isSearching) {
      return Container(
        color: Colors.blue[50],
        height: 50.0,
        width: width,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: songSearchresult2.length,
          itemBuilder: (BuildContext context, int index) {
            String listData = songSearchresult2[index];
            return GestureDetector(
              child: Row(
                children: <Widget>[
                  playPauseIcon(listData)
                      ? position != null && duration != null
                          ? Icon(Icons.pause_circle_outline)
                          : SizedBox(
                              child: new CircularProgressIndicator(
                                  valueColor: new AlwaysStoppedAnimation(
                                      Color(0xffb00bae3)),
                                  strokeWidth: 1.0),
                              height: 20.0,
                              width: 20.0,
                            )
                      : Icon(Icons.music_note),
                  Text(
                    listData.replaceAll('.mp3', ''),
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 15.0, 0.0),
                  )
                ],
              ),
              onTapUp: (TapUpDetails details) {
                print("onTapUp");
                isPlaying
                    ? stop()
                    : play(
                        "http://oyeyaaroapi.plmlogix.com/Audio/" +
                            listData.toString(),
                        listData);
              },
              onLongPress: () {
                print("onLongPress"); //add loading true
                onTextMessage(
                    "http://oyeyaaroapi.plmlogix.com/Audio/" +
                        listData.toString(),
                    4);
              },
            );
          },
        ),
      );
    } else
      return Container();
    //  Text('');
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor:
                        new AlwaysStoppedAnimation<Color>(Color(0xffb00bae3))),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  Widget buildInput() {
    return Container(
      child: Column(
        children: <Widget>[
          !isSearching
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Material(
                      child: new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 1.0),
                        child: new IconButton(
                          icon: new Icon(Icons.image),
                          onPressed: getGalleryImage,
                          color: primaryColor,
                        ),
                      ),
                      color: Colors.white,
                    ),
                    Material(
                      child: new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 1.0),
                        child: new IconButton(
                          icon: new Icon(Icons.video_library),
                          onPressed: getGalleryVideo,
                          color: primaryColor,
                        ),
                      ),
                      color: Colors.white,
                    ),
                    Material(
                      child: new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 1.0),
                        child: new IconButton(
                          icon: new Icon(Icons.photo_camera),
                          onPressed: getCameraImage,
                          color: primaryColor,
                        ),
                      ),
                      color: Colors.white,
                    ),
                    Material(
                      child: new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 1.0),
                        child: new IconButton(
                          icon: new Icon(Icons.videocam),
                          onPressed: getCameraVideo,
                          color: primaryColor,
                        ),
                      ),
                      color: Colors.white,
                    ),
                    Material(
                      child: new Container(
                          margin: new EdgeInsets.symmetric(horizontal: 1.0),
                          child: GestureDetector(
                            onTap: () {
                              recordedVideoPage();
                            },
                            child: Image(
                              color: Colors.black,
                              image: new AssetImage("assets/video_call.png"),
                              width: 21.0,
                              height: 21.0,
                              fit: BoxFit.scaleDown,
                            ),
                          )),
                    ),
                  ],
                )
              : Text(''),
          Row(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(5.0, 0.0, 0.0, 0.0),
              ),
              Flexible(
                child: Container(
                    decoration: BoxDecoration(
                        color: greyColor2,
                        borderRadius: BorderRadius.circular(50.0)),
                    padding: EdgeInsets.all(15.0),
                    child: GestureDetector(
                      child: TextField(
                        textCapitalization: TextCapitalization.sentences,
                        // keyboardType: TextInputType.text,
                        cursorColor: Color(0xffb00bae3),
                        style: TextStyle(color: primaryColor, fontSize: 15.0),
                        controller: textEditingController,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: greyColor),
                        ),
                        focusNode: focusNode,
                        onChanged: (input) {
                          print(input.length);
                          if (input.length >= 1) {
                            setState(() {
                              this.isSearching = true;
                            });
                            searchOperation(input);
                          } else {
                            stop();
                          }
                        },
                        onTap: () {
                          print('ontap-');
                          setState(() {
                            this.isSearching = true;
                          });
                          searchOperation('a');
                        },
                      ),
                    )),
              ),
              // Button send message
              Container(
                decoration: BoxDecoration(
                    color: Color(0xffb00bae3),
                    borderRadius: BorderRadius.circular(50.0)),
                margin: new EdgeInsets.symmetric(horizontal: 8.0),
                child: new IconButton(
                  icon: new Icon(Icons.send),
                  onPressed: !textSending
                      ? () {
                          onTextMessage(textEditingController.text, 0);
                        }
                      : null,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 4.0),
          ),
        ],
      ),
      width: double.infinity,
      height: isSearching == true ? 70.0 : 105.0,
      decoration: new BoxDecoration(
        border: new Border(top: new BorderSide(color: greyColor2, width: 0.9)),
        color: Colors.white,
      ),
    );
  }

  recordedVideoPage() async {
    final recordedVideoPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GetVideo(),
      ),
    );
    if(recordedVideoPath != null){
      setState(() {
        isLoading = true;
      });
      print('selected record  video path  : $recordedVideoPath');
    http.Response responseTime =
        await http.get('http://oyeyaaroapi.plmlogix.com/time');
    timestamp = jsonDecode(responseTime.body)['timestamp'];
    print('Got timestamp : $timestamp');
    File imageFile = new File(recordedVideoPath);
    uploadVideoFile(imageFile, timestamp);
    }
    
  }

  // not done
  openOptions() {
    showModalBottomSheet(
        context: context,
        builder: (builder) {
          return new Container(
            decoration: new BoxDecoration(
                color: Colors.transparent,
                borderRadius: new BorderRadius.only(
                    topLeft: const Radius.circular(10.0),
                    topRight: const Radius.circular(10.0))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.delete_outline),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {},
                )
              ],
            ),
            height: 60.0,
          );
        });
  }

  // Future<List<dynamic>> calculate(List<dynamic> snap) async {
  //   if (this.type == 10) {
  //     listMessage = snap;
  //     return listMessage;
  //   } else {
  //     for (var i = 0; i < snap.length; i++) {
  //       if (snap[i]['type'] == 1 || snap[i]['type'] == 2) {
  //         continue;
  //       } else {
  //         print(snap[i]['type']);
  //         listMessage.add(snap[i]);
  //       }
  //     }
  //     return listMessage;
  //   }
  // }

  Widget buildListMessage() {
    return Flexible(
      child: widget.peerId == ''
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor)))
          : StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance
                  .collection('groups')
                  .document(widget.peerId)
                  .collection(widget.peerId)
                  .orderBy('timestamp', descending: true)
                  // .limit(12)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor: new AlwaysStoppedAnimation<Color>(
                              Color(0xffb00bae3))));
                } else {
                  if (this.type == 10) {
                    listMessage = snapshot.data.documents;
                  } else {
                    listMessage = [];
                    for (var i = 0; i < snapshot.data.documents.length; i++) {
                      // print(snapshot.data.documents[1]['type']);
                      if (snapshot.data.documents[i]['type'] == 1 ||
                          snapshot.data.documents[i]['type'] == 2) {
                        continue;
                      } else {
                        listMessage.add(snapshot.data.documents[i]);
                      }
                    }
                  }

                  print('-----listMessage----${listMessage.length}');
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(3.0, 10.0, 5.0, 0.0),
                    itemBuilder: (context, index) => buildItem(
                          index,
                          listMessage[index],
                          // snapshot.data.documents[index]
                        ),
                    itemCount: listMessage.length,
                    // snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }

  void searchOperation(String searchText) {
    searchresult.clear();
    songSearchresult2.clear();

    if (isSearching != null) {
      for (int i = 0; i < _songList1.length; i++) {
        String data = _songList1[i];
        if (data.toLowerCase().contains(searchText.toLowerCase())) {
          searchresult.add(data); //remove .mp4  nt here
        }
      }

      for (int i = 0; i < _songList2.length; i++) {
        String data = _songList2[i];
        if (data.toLowerCase().contains(searchText.toLowerCase())) {
          songSearchresult2.add(data);
        }
      }

      if (searchresult.length == 0 && songSearchresult2.length == 0) {
        isSearching = false;
      }
    }
  }

  deleteMsg() async {
    for (var i = 0; i < this.indexesToDelete.length; i++) {
      await Firestore.instance
          .collection('groups')
          .document(widget.peerId)
          .collection(widget.peerId)
          .document(this.indexesToDelete[i])
          .delete()
          .catchError((e) {
        print("got err while deleting msg:" + e);
      });
    }

    //call delete from album service
    http.Response response =
        await http.post("http://oyeyaaroapi.plmlogix.com/deleteMsgs",
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "dialog_id": peerId,
              "type": "group",
              "msgs": this.indexesToDeleteFrmAlbum,
            }));
    var res = jsonDecode(response.body);
    print('indexes to delete album : $indexesToDeleteFrmAlbum');

    print('delete from album  res :$res');

    setState(() {
      isLongpressedForDelete = false;
      indexesToDelete = [];
    });
  }

  adddeleteMsgIdx(index, timestamp, type) {
    setState(() {
      this.indexesToDelete.add(timestamp);
      this.isLongpressedForDelete = true;
      this.indexesToDeleteFrmAlbum.add({"timestamp": timestamp, "type": type});
    });
    print('after added in album [] : $indexesToDeleteFrmAlbum');
  }

  removeFrmIndexesToDelete(timestamp) {
    setState(() {
      this.indexesToDelete.remove(timestamp);

      for (var i = 0; i < indexesToDeleteFrmAlbum.length; i++) {
        var item = indexesToDeleteFrmAlbum[i]['timestamp'];
        print('$item');
        if (indexesToDeleteFrmAlbum[i]['timestamp'] == timestamp) {
          indexesToDeleteFrmAlbum.removeAt(i);
        }
      }
      print('after removed from [] : $indexesToDeleteFrmAlbum');

      if (this.indexesToDelete.length == 0) {
        this.isLongpressedForDelete = false;
      }
    });
  }
}
