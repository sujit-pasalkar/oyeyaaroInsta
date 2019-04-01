import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../const.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:video_player/video_player.dart';
import 'package:thumbnails/thumbnails.dart';
import 'package:flutter/services.dart';
// import '../playVideo.dart';
import '../../../feed/playVideo.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../feed/image_view.dart';
import '../../../ProfilePage/profile.dart';
import '../../../models/data-service.dart';
import '../../../cameraModule/controllers/commonFunctions.dart';
import '../../pages/recording/getVideo.dart';


class ChatPrivate extends StatefulWidget {
  final String chatId;
  final String name;
  final String chatType, receiverPin;
  final String mobile;

  ChatPrivate(
      {Key key,
      @required this.chatId,
      @required this.chatType,
      @required this.name,
      @required this.receiverPin,
      @required this.mobile})
      : super(key: key);

  @override
  State createState() => new ChatPrivateState(
      chatId: chatId,
      chatType: chatType,
      name: name,
      receiverPin: receiverPin,
      mobile: mobile);
}

enum PlayerState { stopped, playing, paused }

class ChatPrivateState extends State<ChatPrivate> {
  static const platform = const MethodChannel('plmlogix.recordvideo/info');
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  ChatPrivateState(
      {Key key,
      @required this.chatId,
      @required this.chatType,
      @required this.name,
      @required this.receiverPin,
      @required this.mobile}) {
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

  //delete data
  bool isLongpressedForDelete = false;
  List<dynamic> indexesToDelete = [];

  String chatId;
  String receiverPin;
  String chatType, mobile;
  String name;

  String id;
  String myId;
  String myName;
  String myPhone;
  var listMessage, timestamp;
  SharedPreferences prefs;
  String userToken;

  File imageFile;
  bool isLoading;
  String isLoadingMsg = '';
  String imageUrl;
  VideoPlayerController controller;
  bool isPlaying = false;

  //#songList
  bool isSearching = false;
  List searchresult = new List();

  List songSearchresult2 = new List();

  bool textSending = false;

  List<dynamic> _songList1;
  List<dynamic> _songList2;

  String searchText = "";
  AudioPlayer audioPlayer;
  PlayerState playerState = PlayerState.stopped;
  Duration duration;
  Duration position;
  // get songisPlaying => playerState == PlayerState.playing;
  // get isPaused => playerState == PlayerState.paused;
  // get durationText => duration?.toString()?.split('.')?.first ?? '';
  // get positionText => position?.toString()?.split('.')?.first ?? '';
  String playingSongInList;

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();
    print('in privateChat');
    isSearching = false;
    isLoading = false;
    imageUrl = '';
    timestamp = '';
    values();
    _initAudioPlayer();
    readLocal();
  }

  @override
  void dispose() {
    super.dispose();
    // remove possible overlays on dispose as they would be visible even after [Navigator.push]
    audioPlayer.stop();
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
      print('audioPlayer error : $msg');
      setState(() {
        playerState = PlayerState.stopped;
        duration = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    };
  }

  void onComplete() {
    //on audioplaying complete
    setState(() {
      playerState = PlayerState.stopped;
      isPlaying = false;
    });
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    this.myId = prefs.getString('userPin') ?? ''; //id
    // this.userToken = prefs.getString('UserToken');
    this.myName = prefs.getString('userName');
    this.myPhone = prefs.getString('userPhone');
    setState(() {});
    print('MY USER ID: ${this.myId}');
    print('MY phone:***** ${this.myPhone}');
  }

//  Future getCameraImage() async {
//     imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
//     if (imageFile != null) {
//       setState(() {
//         isLoading = false;
//       });
//       uploadImageFile(imageFile);
//     }
//   }

  Future getCameraImage() async {
    try {
      print('in getCameraImage');
      File compressedImage =
          await ImagePicker.pickImage(source: ImageSource.camera);

      int fileSize = await compressedImage.length();
      print('original img file size : $fileSize');

      if ((fileSize / 1024) > 500) {
        print('compressing img');
        imageFile = await FlutterNativeImage.compressImage(compressedImage.path,
            percentage: 75, quality: 75);
        int fileSize = await imageFile.length();
        print('compress img file size : $fileSize');
      } else {
        print('no img compression');
        imageFile = compressedImage;
      }
      setState(() {
        isLoading = false;
      });
      uploadImageFile(imageFile);
    } catch (e) {
      print('Err in getCameraImage: ' + e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future getGalleryImage() async {
    print('in getGalleryImage');
    try {
      File compressedImage =
          await ImagePicker.pickImage(source: ImageSource.gallery);

      int fileSize = await compressedImage.length();

      if ((fileSize / 1024) > 500) {
        imageFile = await FlutterNativeImage.compressImage(compressedImage.path,
            percentage: 75,
            quality:
                75); //store compress image in OyeYaaro/OyeYaaroImages/sent/ path
      } else {
        imageFile = compressedImage;
      }
      setState(() {
        isLoading = false;
      });
      uploadImageFile(imageFile);
    } catch (e) {
      print('Err in getGalleryImage: ' + e);
      setState(() {
        isLoading = false;
      });
    }
  }

  // Future getCameraVideo() async {
  //   try {
  //     setState(() {
  //       isLoading = true;
  //     });
  //     File originalVideoUrl =
  //         await ImagePicker.pickVideo(source: ImageSource.camera);
  //     print('Original Video: ${originalVideoUrl.path}');
  //     int fileSize = await originalVideoUrl.length();
  //     print(
  //         "Original vedio file size: " + (fileSize / 1024).toString() + " KB");
  //     CommonFunctions cmf = new CommonFunctions();
  //     cmf.compressVideo(originalVideoUrl.path).then((value) async {
  //       imageFile = new File(value);
  //       int fileSize = await imageFile.length();
  //       print("Compressed vedio file size: " +
  //           (fileSize / 1024).toString() +
  //           " KB");
  //       if (imageFile != null) {
  //          http.Response responseTime =
  //             await http.get('http://oyeyaaroapi.plmlogix.com/time');
  //         timestamp = jsonDecode(responseTime.body)['timestamp'];
  //         print('Got timestamp : $timestamp');
  //         uploadVideoFile(timestamp);
  //       }
  //     }).catchError((error) {
  //       print('Error Compressing: $error');
  //     });
  //   } catch (e) {
  //     print('error while opening: $e');
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

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
        // if ((fileSize / 1024) <= 500000) {
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
      // } else {
      //   setState(() {
      //     isLoading = false;
      //   });
      //   Fluttertoast.showToast(msg: 'video not selected.');
      // }
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

        // if ((fileSize / 1024) <= 500000) {
          CommonFunctions cmf = new CommonFunctions();
          cmf.compressVideo(originalVideoUrl.path).then((value) async {
            File imageFile = new File(value);
            fileSize = await imageFile.length();
            print("Compressed vedio file size: " +
                (fileSize / 1024).toString() +
                " KB");

            // if ((fileSize / 1024) <= 10000) {
              http.Response responseTime =
                  await http.get('http://oyeyaaroapi.plmlogix.com/time');
              timestamp = jsonDecode(responseTime.body)['timestamp'];
              print('Got timestamp : $timestamp');
              uploadVideoFile(imageFile, timestamp);
            // } else {
            //   setState(() {
            //     isLoading = false;
            //   });
            //   Fluttertoast.showToast(msg: 'Video size too large!');
            // }
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
        // Fluttertoast.showToast(msg: 'video not selected.');
      }
    } catch (e) {
      print('error while opening: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future uploadVideoFile(imageFile, timestamp) async {
    try {
      print('VideoFILE ******: $imageFile , timestamp : $timestamp');
      setState(() {
        this.isLoading = true;
      });

      //s3
      String mediaUrl = await dataService.uploadFileToS3(
          imageFile, 'videos/$chatId/' + timestamp.toString(), '.mp4');
      print('$mediaUrl');

      //video thumb  s3
      String thumb = await Thumbnails.getThumbnail(
          thumbnailFolder: '/storage/emulated/0/OyeYaaro/.thumbnails',
          videoFile: imageFile.path,
          imageType: ThumbFormat.PNG,
          quality: 30);

      String thumbUrl = await dataService.uploadFileToS3(
          File(thumb), "vedioThumb/$timestamp", ".jpeg");

      print("uploaded video mediaUrl: " + mediaUrl);
      print("uploaded video thumbUrl: " + thumbUrl);

      //call service
      http.Response response = await http.post(
          "http://oyeyaaroapi.plmlogix.com/uploadImages",
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "url": mediaUrl,
            "dialogId": chatId,
            "senderId": this.myId,
            "type": "private"
          }));

      print('uploadImage res : $response');

      setState(() {
        print('$imageUrl');
        onSendMessage(mediaUrl, 2, timestamp, thumbUrl);
      });
    } catch (e) {
      print('err while uploading : $e');
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

      String mediaUrl = await dataService.uploadFileToS3(
          imageFile, 'images/$chatId/' + timestamp.toString(), '.jpeg');
      print('$mediaUrl');

      //call service
      http.Response response = await http.post(
          "http://oyeyaaroapi.plmlogix.com/uploadImages",
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "url": mediaUrl,
            "dialogId": chatId,
            "senderId": this.myId,
            "type": "private"
          }));

      print('res: $response');

      setState(() {
        onSendMessage(
            mediaUrl, //"http://oyeyaaroapi.plmlogix.com/Media/Images/${chatId}/${timestamp}.jpeg",
            1,
            timestamp);
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
    print('..............${res['timestamp'].runtimeType}');
    timestamp = res['timestamp'];

    // timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = Firestore.instance
          .collection('Private')
          .document(this.chatId)
          .collection(this.chatId)
          .document(
              timestamp); //DateTime.now().millisecondsSinceEpoch.toString()

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'senderId': this.myId,
            'idTo': this.chatId,
            'receiverPin': this.receiverPin,
            'timestamp': timestamp,
            'msg': content,
            'type': type,
            'senderName': this.myName
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
            .collection('Private')
            .document(this.chatId)
            .collection(this.chatId)
            .document(time);

        if (type == 2) {
          //vid
          Firestore.instance.runTransaction((transaction) async {
            await transaction.set(
              documentReference,
              {
                'senderId': this.myId,
                'receiverPin': this.receiverPin,
                'idTo': this.chatId,
                'timestamp': time,
                'msg': content,
                'type': type,
                'senderName': this.myName,
                'thumbnail': thumbUrl,
                //  "http://oyeyaaroapi.plmlogix.com/Media/Frames/" +this.chatId +"/" +time +"_1.jpg"
              },
            );
          }).then((onValue) {
            setState(() {
              this.isLoading = false;
            });
            print('video added in firebase.');
          });
        } else {
          //img
          print('in image set');
          Firestore.instance.runTransaction((transaction) async {
            await transaction.set(
              documentReference,
              {
                'senderId': this.myId,
                'receiverPin': this.receiverPin,
                'idTo': this.chatId,
                'timestamp': time,
                'msg': content,
                'type': type,
                'senderName': this.myName
              },
            );
          }).then((onValue) {
            setState(() {
              this.isLoading = false;
            });
            print('img added in firebase.');

            print('msg sent' + this.myName);
            listScrollController.animateTo(0.0,
                duration: Duration(milliseconds: 300), curve: Curves.easeOut);
          });
        }
      } catch (e) {
        print('image set errr: $e');
      }
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  deleteMsg() async {
    //call delete servive here ..
    for (var i = 0; i < this.indexesToDelete.length; i++) {
      print('i : ${this.indexesToDelete[i]}');
      await Firestore.instance
          .collection('Private')
          .document(this.chatId)
          .collection(this.chatId)
          .document(this.indexesToDelete[i])
          // .document(this.indexesToDelete[i]['timestamp'][0]['timestamp'])
          .delete()
          .catchError((e) {
        print("got err while deleting msg:" + e);
      });
    }
    setState(() {
      isLongpressedForDelete = false;
      indexesToDelete = [];
    });
  }

  adddeleteMsgIdx(index, timestamp, msgTpe) {
    print('in deleteMsg(): $index,$timestamp,$msgTpe');
    setState(() {
      this.indexesToDelete.add(timestamp); //
      this.isLongpressedForDelete = true;
    });
  }

  Future<String> getTime(timestamp) async { //mk common
    http.Response responseTime =
        await http.get('http://oyeyaaroapi.plmlogix.com/time');

    var getTimestamp = jsonDecode(responseTime.body)['timestamp'];
    print('ServerTimestamp $getTimestamp');

    int now = (DateTime.now().toLocal().millisecondsSinceEpoch / 1000).ceil();
    print("PhoneNow-$now");

    print("msgTimestamp:" + timestamp);

    int differenceInSeconds = now - int.parse(getTimestamp);
    print("diff-$differenceInSeconds");

    getTimestamp = (int.parse(timestamp) + differenceInSeconds).toString();

    print("ShowTime" +
        DateFormat('dd MMM kk:mm').format(DateTime.fromMillisecondsSinceEpoch(
            int.parse(getTimestamp) * 1000)));

    print("PhoneTimw :" +
        DateFormat('dd MMM kk:mm')
            .format(DateTime.fromMillisecondsSinceEpoch(now * 1000)));

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
              document['type'] == 0
                  // Text
                  ? GestureDetector(
                      onLongPress: () {
                        adddeleteMsgIdx(
                            index, document['timestamp'], document['type']);
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
                                // getTime(document['timestamp']),
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
                  : document['type'] == 1
                      // Image
                      ? GestureDetector(
                          onLongPress: () {
                            adddeleteMsgIdx(
                                index, document['timestamp'], document['type']);
                          },
                          onTap: () {
                            audioPlayer.stop();
                            print(document['msg']);
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
                                    // Text(
                                    //   DateFormat('dd MMM kk:mm').format(
                                    //       DateTime.fromMillisecondsSinceEpoch(
                                    //           int.parse(document['timestamp']) *
                                    //               1000)),
                                    //   style: TextStyle(
                                    //       color: Colors.black,
                                    //       fontSize: 12.0,
                                    //       fontStyle: FontStyle.italic),
                                    // ),
                                  ],
                                ),
                                Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 5.0)),
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

                      // video
                      : document['type'] == 2
                          ? GestureDetector(
                              onLongPress: () {
                                adddeleteMsgIdx(index, document['timestamp'],
                                    document['type']);
                              },
                              onTap: () {
                                print('opening video');
                                audioPlayer.stop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PlayVideo(mediaUrl: document['msg']),
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
                                        // Text(
                                        //   DateFormat('dd MMM kk:mm').format(
                                        //       DateTime
                                        //           .fromMillisecondsSinceEpoch(
                                        //               int.parse(document[
                                        //                       'timestamp']) *
                                        //                   1000)),
                                        //   style: TextStyle(
                                        //       color: Colors.black,
                                        //       fontSize: 12.0,
                                        //       fontStyle: FontStyle.italic),
                                        // ),
                                      ],
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 5.0)),
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
                                          image: NetworkImage(
                                              document['thumbnail']),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.play_circle_filled,
                                        size: 60.0,
                                        color: Colors.white,
                                      ),
                                    )
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
                                padding:
                                    EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                                margin: EdgeInsets.only(
                                  bottom:
                                      isLastMessageRight(index) ? 20.0 : 10.0,
                                  // right: 10.0
                                ),
                              ),
                            )
                          //playSongs ....short
                          : document['type'] == 3
                              ? GestureDetector(
                                  onLongPress: () {
                                    adddeleteMsgIdx(
                                        index,
                                        document['timestamp'],
                                        document['type']);
                                  },
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
                                  child: Container(
                                    height: 103.0,
                                    width: 130.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                    ),
                                    margin: EdgeInsets.only(
                                      bottom: isLastMessageRight(index)
                                          ? 20.0
                                          : 10.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
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
                                                      '')) //isPlaying
                                              ? Container(
                                                  margin: EdgeInsets.all(3),
                                                  padding: EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(8.0),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: <Widget>[
                                                      LayoutBuilder(builder:
                                                          (context,
                                                              constraint) {
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
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(8.0),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: <Widget>[
                                                      Image.asset(
                                                          'assets/short.png',
                                                          width: 40.0,
                                                          height: 40.0)
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
                                        // Text(
                                        //   DateFormat('dd MMM kk:mm').format(
                                        //       DateTime
                                        //           .fromMillisecondsSinceEpoch(
                                        //               int.parse(document[
                                        //                       'timestamp']) *
                                        //                   1000)),
                                        //   style: TextStyle(
                                        //       color: Colors.black,
                                        //       fontSize: 12.0,
                                        //       fontStyle: FontStyle.italic),
                                        // ),
                                      ],
                                    ),
                                  ),
                                )

                              //type = 4 ...long audio
                              : GestureDetector(
                                  onLongPress: () {
                                    adddeleteMsgIdx(
                                        index,
                                        document['timestamp'],
                                        document['type']);
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
                                      bottom: isLastMessageRight(index)
                                          ? 20.0
                                          : 10.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
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
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(8.0),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: <Widget>[
                                                      LayoutBuilder(builder:
                                                          (context,
                                                              constraint) {
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
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(8.0),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: <Widget>[
                                                      LayoutBuilder(builder:
                                                          (context,
                                                              constraint) {
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
                                        // Text(
                                        //   DateFormat('dd MMM kk:mm').format(
                                        //       DateTime
                                        //           .fromMillisecondsSinceEpoch(
                                        //               int.parse(document[
                                        //                       'timestamp']) *
                                        //                   1000)),
                                        //   style: TextStyle(
                                        //       color: Colors.black,
                                        //       fontSize: 12.0,
                                        //       fontStyle: FontStyle.italic),
                                        // ),
                                      ],
                                    ),
                                  ),
                                )
            ],
            mainAxisAlignment: MainAxisAlignment.end,
          ),
          this.isLongpressedForDelete &&
                  // this.indexesToDelete.every((time) => time['timestamp'] == document['timestamp'])
                  this.indexesToDelete.contains(document['timestamp'])
              //&& this.indexesToDelete.contains({'timestamp':document['timestamp']})
              ? GestureDetector(
                  onTap: () {
                    removeFrmIndexesToDelete(document['timestamp']);
                    // print("${this.indexesToDelete[0]['timestamp'].contains(timestamp: 1549537414)}");
                    // removeFrmIndexesToDelete({'timestamp':document['timestamp']});
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
              : Container()
        ],
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                // isLastMessageLeft(index)
                //     ? Material(
                //         child: CachedNetworkImage(
                //           placeholder: Container(
                //             // padding:EdgeInsets.only(right: 15.0),
                //             child: CircularProgressIndicator(
                //               strokeWidth: 1.0,
                //               valueColor:
                //                   AlwaysStoppedAnimation<Color>(themeColor),
                //             ),
                //             width: 40.0,
                //             height: 40.0,
                //             padding: EdgeInsets.all(10.0),
                //           ),
                //           imageUrl:
                //               'http://oyeyaaroapi.plmlogix.com/Media/Images/da2dd2kgjpm85w9n/1548247221.jpeg',
                //           width: 40.0,
                //           height: 40.0,
                //           fit: BoxFit.cover,
                //         ),
                //         borderRadius: BorderRadius.all(
                //           Radius.circular(18.0),
                //         ),
                //         clipBehavior: Clip.hardEdge,
                //       )
                //     : Container(width: 35.0),
                document['type'] == 0
                    //txt
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
                                // Text(
                                //   DateFormat('dd MMM kk:mm').format(
                                //       DateTime.fromMillisecondsSinceEpoch(
                                //           int.parse(document['timestamp']) *
                                //               1000)),
                                //   style: TextStyle(
                                //       color: Colors.black,
                                //       fontSize: 12.0,
                                //       fontStyle: FontStyle.italic),
                                // ),
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
                          bottom: isLastMessageRight(index) ? 10.0 : 20.0,
                          // left: 10.0
                        ),
                      )
                    : document['type'] == 1
                        //img
                        ? GestureDetector(
                            onLongPress: () {
                              adddeleteMsgIdx(index, document['timestamp'],
                                  document['type']);
                            },
                            onTap: () {
                              audioPlayer.stop();
                              print(document['msg']);
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
                                      // Text(
                                      //   DateFormat('dd MMM kk:mm').format(
                                      //       DateTime.fromMillisecondsSinceEpoch(
                                      //           int.parse(
                                      //                   document['timestamp']) *
                                      //               1000)),
                                      //   style: TextStyle(
                                      //       color: Colors.black,
                                      //       fontSize: 12.0,
                                      //       fontStyle: FontStyle.italic),
                                      // ),
                                    ],
                                  ),
                                  Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 5.0)),
                                  Material(
                                    child: CachedNetworkImage(
                                      placeholder: Container(
                                        child: CircularProgressIndicator(
                                            valueColor:
                                                new AlwaysStoppedAnimation<
                                                    Color>(Color(0xffb00bae3))),
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

                        // video
                        : document['type'] == 2
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
                                        // Text(
                                        //   DateFormat('dd MMM kk:mm').format(
                                        //       DateTime
                                        //           .fromMillisecondsSinceEpoch(
                                        //               int.parse(document[
                                        //                       'timestamp']) *
                                        //                   1000)),
                                        //   style: TextStyle(
                                        //       color: Colors.black,
                                        //       fontSize: 12.0,
                                        //       fontStyle: FontStyle.italic),
                                        // ),
                                      ],
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 5.0)),
                                    Container(
                                        //)  SizedBox(
                                        width: double.infinity,
                                        height: 142.0,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(15.0),
                                          ),
                                          image: DecorationImage(
                                            fit: BoxFit.cover,
                                            image: NetworkImage(
                                                document['thumbnail']),
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
                                            print('opening video');
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PlayVideo(
                                                      mediaUrl: document['msg'],
                                                    ),
                                              ),
                                            );
                                          },
                                        )
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
                                padding:
                                    EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 4.0),
                                margin: EdgeInsets.only(
                                  bottom:
                                      isLastMessageRight(index) ? 10.0 : 20.0,
                                  // left: 10.0
                                  // right: 10.0
                                ),
                              )
                            //playSong short song
                            : document['type'] == 3
                                ? Container(
                                    height: 103.0,
                                    width: 130.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                    ),
                                    margin: EdgeInsets.only(
                                      bottom: isLastMessageRight(index)
                                          ? 5.0
                                          : 10.0,
                                      // left: 10.0
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                  document['senderName'],
                                                  style: new TextStyle(
                                                      fontSize: 12.0,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold)),
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
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(8.0),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: <Widget>[
                                                        LayoutBuilder(builder:
                                                            (context,
                                                                constraint) {
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
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(8.0),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: <Widget>[
                                                        Image.asset(
                                                            'assets/short.png',
                                                            width: 40.0,
                                                            height: 40.0)
                                                      ],
                                                    ),
                                                  ),
                                            onTapUp: (TapUpDetails details) {
                                              print("onTapUp");
                                              isPlaying
                                                  ? stop()
                                                  : play(
                                                      document['msg']
                                                          .toString(),
                                                      document['msg']
                                                          .toString()
                                                          .replaceAll(
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
                                        // Text(
                                        //   DateFormat('dd MMM kk:mm').format(
                                        //       DateTime
                                        //           .fromMillisecondsSinceEpoch(
                                        //               int.parse(document[
                                        //                       'timestamp']) *
                                        //                   1000)),
                                        //   style: TextStyle(
                                        //       color: Colors.black,
                                        //       fontSize: 12.0,
                                        //       fontStyle: FontStyle.italic),
                                        // ),
                                      ],
                                    ),
                                  )
                                //type = 4 long songs
                                : Container(
                                    height: 103.0,
                                    width: 130.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                    ),
                                    margin: EdgeInsets.only(
                                      bottom: isLastMessageRight(index)
                                          ? 5.0
                                          : 10.0,
                                      // right: 10.0
                                      // left: 10.0
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                  document['senderName'],
                                                  style: TextStyle(
                                                      fontSize: 12.0,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 2.0)),
                                        GestureDetector(
                                          child: Row(
                                            children: <Widget>[
                                              playPauseIcon(document['msg']
                                                      .toString()
                                                      .replaceAll(
                                                          'http://oyeyaaroapi.plmlogix.com/Audio/',
                                                          '')) //isPlaying
                                                  ? Container(
                                                      margin: EdgeInsets.all(3),
                                                      padding:
                                                          EdgeInsets.all(5),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(8.0),
                                                        ),
                                                      ),
                                                      child: Column(
                                                        children: <Widget>[
                                                          LayoutBuilder(builder:
                                                              (context,
                                                                  constraint) {
                                                            return Icon(
                                                              Icons.pause,
                                                              size: 40.0,
                                                              color:
                                                                  Colors.white,
                                                            );
                                                          }),
                                                        ],
                                                      ),
                                                    )
                                                  : Container(
                                                      margin: EdgeInsets.all(3),
                                                      padding:
                                                          EdgeInsets.all(5),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(8.0),
                                                        ),
                                                      ),
                                                      child: Column(
                                                        children: <Widget>[
                                                          LayoutBuilder(builder:
                                                              (context,
                                                                  constraint) {
                                                            return new Icon(
                                                              Icons.music_note,
                                                              size: 40.0,
                                                              color:
                                                                  Colors.white,
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
                                                    document['msg']
                                                        .toString()
                                                        .replaceAll(
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
                                        // Text(
                                        //   DateFormat('dd MMM kk:mm').format(
                                        //       DateTime
                                        //           .fromMillisecondsSinceEpoch(
                                        //               int.parse(document[
                                        //                       'timestamp']) *
                                        //                   1000)),
                                        //   style: TextStyle(
                                        //       color: Colors.black,
                                        //       fontSize: 12.0,
                                        //       fontStyle: FontStyle.italic),
                                        // ),
                                      ],
                                    ),
                                  ),
              ],
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  bool isLastMessageLeft(int index) {
    print('left last msg idx : ${index}');
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['senderId'] == this.myId) ||
        index == 0)
    {
      return true;
    } else {
      return false;
    }
  }
  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            index < listMessage.length - 1 &&
            listMessage != null &&
            listMessage[index + 1]['senderName'] !=
                listMessage[index]['senderName']) ||
        (index == listMessage.length - 1
        )) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    Navigator.pop(context);
  }

  //open bottom sheet for image video song opening

//
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return new Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomPadding: true,
      appBar: !isLongpressedForDelete && this.indexesToDelete.length == 0
          ? new AppBar(
              title: FlatButton(
                onPressed: () {
                  audioPlayer.stop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            // UserInfoPage(name: this.name, pin: this.receiverPin),
                            ProfilePage(userPin: receiverPin)),
                  );
                },
                textColor: Colors.white,
                splashColor: Color(0xffb00bae3),
                child: new Text(
                  '${this.name}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () {
                    audioPlayer.stop();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/homepage', (Route<dynamic> route) => false);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.call),
                  onPressed: () {
                    callAudio();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.video_call),
                  onPressed: () {
                    callVideo();
                  },
                ),
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
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // List of messages
              buildListMessage(),
              songList(width),

              songlist2(width),
              buildInput(),
            ],
          ),
          // Loading
          buildLoading()
        ],
      ),
      // onWillPop: onBackPress,
      // )
    );
  }

  removeFrmIndexesToDelete(timestamp) {
    setState(() {
      this.indexesToDelete.remove(timestamp);
      if (this.indexesToDelete.length == 0) {
        this.isLongpressedForDelete = false;
      }
    });
  }

  songList(width) {
    if (isSearching == true) {
      return Container(
          color: Colors.deepPurple[50],
          height: 40.0,
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
                    Padding(
                      padding: EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                    ),
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
                  final snackBar = SnackBar(
                    content: Text('Sending  "' +
                        listData.toString().replaceAll('.mp3', ' "')),
                  );
                  _scaffoldKey.currentState.showSnackBar(snackBar);
                  print("onLongPress");
                  onTextMessage(
                      "http://oyeyaaroapi.plmlogix.com/AudioChat/" +
                          listData.toString(),
                      3);
                },
              );
            },
          ));
    } else
      return Text('');
  }

  songlist2(width) {
    if (isSearching == true) {
      return Container(
        color: Colors.blue[50],
        height: 40.0,
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
                  Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                  ),
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
                print("onLongPress");
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
      return Text('');
  }

  bool playPauseIcon(songName) {
    if (songName == playingSongInList && isPlaying) {
      return true;
    } else
      return false;
  }

  // audio call
  Future<String> callAudio() async {
    var sendMap = <String, dynamic>{'from': this.mobile, 'to': this.myPhone};
    String result;
    try {
      result = await platform.invokeMethod('audioSinch', sendMap);
    } on PlatformException catch (e) {}
    return result;
  }

  //video
  Future<String> callVideo() async {
    var sendMap = <String, dynamic>{'from': this.mobile, 'to': this.myPhone};
    String result;
    try {
      result = await platform.invokeMethod('videoSinch', sendMap);
    } on PlatformException catch (e) {}
    return result;
  }

  //song play stop pause
  Future<int> play(url, songName) async {
    print('in play():$songName');
    setState(() {
      position = null;
      duration = null;
    });
    final result = await audioPlayer.play(url, isLocal: false);
    if (result == 1)
      setState(() {
        playerState = PlayerState.playing;
        isPlaying = true;
        // filteredSongIndex = index;//
        playingSongInList = songName;
        print('playing');
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

  // Widget buildSticker(){}

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xffb00bae3))),
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
                      style: TextStyle(color: primaryColor, fontSize: 15.0),
                      controller: textEditingController,
                      decoration: InputDecoration.collapsed(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: greyColor),
                      ),
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
                        print('ontapp.');
                        setState(() {
                          this.isSearching = true;
                        });
                        searchOperation('');
                      },
                    ),
                  ),
                ),
              ),
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

  void searchOperation(String searchText) {
    searchresult.clear();
    songSearchresult2.clear();
    if (isSearching != null) {
      for (int i = 0; i < _songList1.length; i++) {
        String data = _songList1[i];
        if (data.toLowerCase().contains(searchText.toLowerCase())) {
          // String changed =  data.replaceAll('.mp3', '');
          searchresult.add(data); //remove .mp4  nt here
        }
      }

      for (int i = 0; i < _songList2.length; i++) {
        String data = _songList2[i];
        if (data.toLowerCase().contains(searchText.toLowerCase())) {
          // String changed =  data.replaceAll('.mp3', '');
          songSearchresult2.add(data);
          print('****songSearchresult2 added :: ${songSearchresult2}');
          //remove .mp4  nt here
        }
      }
      if (searchresult.length == 0 && songSearchresult2.length == 0) {
        isSearching = false;
      }
    }
  }

  Future values() async {
    _songList1 = List();
    _songList2 = List();
    http.post(
      "http://oyeyaaroapi.plmlogix.com/getAudioListForChat",
      headers: {"Content-Type": "application/json"},
    ).then((response) {
      var res = jsonDecode(response.body);
      print("RES:*****${res[0]}");
      // response.body[0].f
      // for(var i= 0;i<response.body.length)
      _songList1.addAll(res);
      print('RES_List:*****${_songList1}');
    });

    http.post(
      "http://oyeyaaroapi.plmlogix.com/getAudioList",
      headers: {"Content-Type": "application/json"},
    ).then((response) {
      var res = jsonDecode(response.body);
      print("RES_songList2:*****${res[0]}");
      _songList2.addAll(res);
      print('res_SongList2:*****${_songList2}');
    });
  }

  Widget buildListMessage() {
    return Flexible(
      child: this.chatId == ''
          ? Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xffb00bae3))))
          : StreamBuilder(
              stream: Firestore.instance
                  .collection('Private')
                  .document(this.chatId)
                  .collection(this.chatId)
                  .orderBy('timestamp', descending: true)
                  // .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xffb00bae3))));
                } else {
                  listMessage = snapshot.data.documents;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) =>
                        buildItem(index, snapshot.data.documents[index]),
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }
}
