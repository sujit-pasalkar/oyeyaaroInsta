import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'feed/feeds.dart';
import 'HomePage/pages/Network/network_screen.dart';
import 'HomePage/pages/recording/recordings.dart';
import 'HomePage/pages/recording/video.dart';
import 'HomePage/pages/Chats/chat_screen.dart';
import 'HomePage/pages/Groups/groups_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user.dart';
import 'HomePage/pages//SongList//audioListHome.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ScrollController hideButtonController;

  bool _isBottomBarVisible;

  int _currentIndex;

  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  PageStorageKey feedsKey = PageStorageKey('Feeds');
  PageStorageKey audioListKey = PageStorageKey('audioListKey');
  PageStorageKey videosKey = PageStorageKey('videosKey');
  PageStorageKey recordingsKey = PageStorageKey('recordingsKey');
  PageStorageKey personalKey = PageStorageKey('personalKey');
  PageStorageKey groupsKey = PageStorageKey('groupsKey');

  // static const Color color = Color(0xffb00dcf2);
  static const Color color = Color(0xffb00bae3);
  // static const Color color = Color(0xffb008bd0);
  // static const Color color = Color(0xffb0081cc);

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _isBottomBarVisible = true;
    hideButtonController = new ScrollController();
    hideButtonController.addListener(() {
      if (hideButtonController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        setState(() {
          _isBottomBarVisible = false;
        });
      }
      if (hideButtonController.position.userScrollDirection ==
          ScrollDirection.forward) {
        setState(() {
          _isBottomBarVisible = true;
        });
      }
      if (hideButtonController.offset == 0.0) {
        setState(() {
          _isBottomBarVisible = true;
        });
      }
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) {
        print('on launch $message');
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.getToken().then((token) {
      var documentReference = Firestore.instance
          .collection('userTokens')
          .document(currentUser.userId);

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {'token': token, 'id': currentUser.userId},
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: bottomBar(),
      body: WillPopScope(
        child: buildBody(),
        onWillPop: onBackPress,
      ),
    );
  }

  buildBody() {
    switch (_currentIndex) {
      case 0:
        return Feeds(
          hideButtonController: hideButtonController,
          key: feedsKey,
        );
        break;

      case 1:
        return AudioList(
          hideButtonController: hideButtonController,
          key: audioListKey,
        );
        break;
        
      case 2:
        return //RecordingScreen
        VedioRecordingScreen(
          hideButtonController: hideButtonController,
          key: recordingsKey,
        );
        break;

      case 3:
        return ChatScreenState(
          hideButtonController: hideButtonController,
          key: groupsKey,
        );
        break;
      case 4:
        return GroupScreenState(
          hideButtonController: hideButtonController,
          key: groupsKey,
        );
        break;
      // case 4:
      //   return NetworkScreen(
      //     hideButtonController: hideButtonController,
      //     key: videosKey,
      //   );
      //   break;
    }
  }

  bottomBar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 250),
      height: _isBottomBarVisible ? 60.0 : 0.0,
      child: _isBottomBarVisible
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.shifting,
              onTap: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  backgroundColor: color,
                  icon: Icon(
                    Icons.home,
                    color: Colors.black,
                  ),
                  activeIcon: Icon(
                    Icons.home,
                    color: Colors.white,
                    size: 40.0,
                  ),
                  title: SizedBox(
                    height: 0.0,
                    width: 0.0,
                  ),
                ),
                BottomNavigationBarItem(
                  backgroundColor: color,
                  icon: Icon(
                    Icons.music_note,
                    color: Colors.black,
                  ),
                  activeIcon: Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 40.0,
                  ),
                  title: SizedBox(
                    height: 0.0,
                    width: 0.0,
                  ),
                ),
                BottomNavigationBarItem(
                  backgroundColor: color,
                  icon: Image.asset(
                    "assets/video_call_inactive.png",
                    width: 30.0,
                    height: 30.0,
                  ),
                  activeIcon: Image.asset(
                    "assets/video_call.png",
                    width: 40.0,
                    height: 40.0,
                  ),
                  title: SizedBox(
                    height: 0.0,
                    width: 0.0,
                  ),
                ),
                BottomNavigationBarItem(
                  backgroundColor: color,
                  icon: Icon(
                    Icons.person,
                    color: Colors.black,
                  ),
                  activeIcon: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 40.0,
                  ),
                  title: SizedBox(
                    height: 0.0,
                    width: 0.0,
                  ),
                ),
                BottomNavigationBarItem(
                  backgroundColor: color,
                  icon: Icon(
                    Icons.group,
                    color: Colors.black,
                  ),
                  activeIcon: Icon(
                    Icons.group,
                    color: Colors.white,
                    size: 40.0,
                  ),
                  title: SizedBox(
                    height: 0.0,
                    width: 0.0,
                  ),
                ),
              ],
            )
          : Container(
              color: Colors.white,
              width: MediaQuery.of(context).size.width,
            ),
    );
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: Color(0xffb00bae3),
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
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
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),


            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }
}
