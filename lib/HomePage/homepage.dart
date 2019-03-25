// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../HomePage/pages/Chats/chat_screen.dart';
// import '../HomePage/pages/Camera/camera.dart';
// import '../HomePage/pages/Groups/groups_screen.dart';
// import '../HomePage/pages/Network/network_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:connect_yaar/ProfilePage/profile.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:connect_yaar/models/user.dart';
// import 'package:connect_yaar/feed/feeds.dart';


// class Choice {
//   const Choice({this.title, this.icon});
//   final String title;
//   final IconData icon;
// }

// class ConnectYaarHomePage extends StatefulWidget {
//   final String userPin;
//   ConnectYaarHomePage({
//     this.userPin,
//   });
//   @override
//   _ConnectYaarHomePageState createState() => _ConnectYaarHomePageState();
// }

// class _ConnectYaarHomePageState extends State<ConnectYaarHomePage>
//     with SingleTickerProviderStateMixin {
//   var downloadedSongPath;
//   //#fcm
//   FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

//   TabController _tabController;
//   String userPhone;
//   String userPin;
  

//   List<Choice> choices = const <Choice>[
//     // const Choice(
//     //     title: 'Settings', icon: Icons.settings), //#nav to next(settings page)
//     const Choice(title: 'Profile', icon: Icons.person),
//     // const Choice(title: 'Log out', icon: Icons.exit_to_app),
//   ];

//   Future<bool> onBackPress() {
//     openDialog();
//     return Future.value(false);
//   }

//   // exit from app
//   Future<Null> openDialog() async {
//     switch (await showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return SimpleDialog(
//             contentPadding:
//                 EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
//             children: <Widget>[
//               Container(
//                 color: Colors.indigo[900],
//                 margin: EdgeInsets.all(0.0),
//                 padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
//                 height: 100.0,
//                 child: Column(
//                   children: <Widget>[
//                     Container(
//                       child: Icon(
//                         Icons.exit_to_app,
//                         size: 30.0,
//                         color: Colors.white,
//                       ),
//                       margin: EdgeInsets.only(bottom: 10.0),
//                     ),
//                     Text(
//                       'Exit app',
//                       style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18.0,
//                           fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       'Are you sure to exit app?',
//                       style: TextStyle(color: Colors.white70, fontSize: 14.0),
//                     ),
//                   ],
//                 ),
//               ),
//               SimpleDialogOption(
//                 onPressed: () {
//                   Navigator.pop(context, 0);
//                 },
//                 child: Row(
//                   children: <Widget>[
//                     Container(
//                       child: Icon(
//                         Icons.cancel,
//                       ),
//                       margin: EdgeInsets.only(right: 10.0),
//                     ),
//                     Text(
//                       'CANCEL',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     )
//                   ],
//                 ),
//               ),
//               SimpleDialogOption(
//                 onPressed: () {
//                   Navigator.pop(context, 1);
//                 },
//                 child: Row(
//                   children: <Widget>[
//                     Container(
//                       child: Icon(
//                         Icons.check_circle,
//                       ),
//                       margin: EdgeInsets.only(right: 10.0),
//                     ),
//                     Text(
//                       'YES',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     )
//                   ],
//                 ),
//               ),
//             ],
//           );
//         })) {
//       case 0:
//         break;
//       case 1:
//         exit(0);
//         break;
//     }
//   }

//   void onItemMenuPress(Choice choice) {
//     // if (choice.title == 'Log out') {
//     //   FirebaseAuth.instance.signOut().then((action) {
//     //     clearSharedPref();
//     //     Navigator.pushReplacementNamed(context, '/loginpage');
//     //   }).catchError((e) {
//     //     print("*err:*" + e);
//     //   });
//     // } else
//     if (choice.title == 'Profile') {
//       print('profil called...');
//       Navigator.push(
//           context, MaterialPageRoute(builder: (context) => ProfilePage()));
//     } else {
//       print('settings called...');
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     currentUser.toString();
//     //#fbauth
//     FirebaseAuth.instance.currentUser().then((user) {
//       print('FB USER:${user}');
//     });

//     //#fcm
//     _firebaseMessaging.configure(
//       onMessage: (Map<String, dynamic> message) {
//         print('on message $message');
//       },
//       onResume: (Map<String, dynamic> message) {
//         print('on resume $message');
//       },
//       onLaunch: (Map<String, dynamic> message) {
//         print('on launch $message');
//       },
//     );
//     _firebaseMessaging.requestNotificationPermissions(
//         const IosNotificationSettings(sound: true, badge: true, alert: true));
//     _firebaseMessaging.getToken().then((token) {
//       print('Token****:${token}');
//       print('pin:${widget.userPin}');
//       var documentReference =
//           Firestore.instance.collection('userTokens').document(widget.userPin);

//       Firestore.instance.runTransaction((transaction) async {
//         await transaction.set(
//           documentReference,
//           {'token': token, 'id': widget.userPin},
//         ).then((onValue) {
//           print('token added***');
//         });
//       });
//     });

//     _tabController = new TabController(vsync: this, initialIndex: 1, length: 5);
//     _loadUserState().then((result) {
//       //#getUserProfile and store data in sharedPreferences
//       getUserProfile();
//     });
//   }

//   _loadUserState() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       this.userPhone = prefs.getString('userPhone');
//       this.userPin = prefs.getString('userPin');
//       print('...............................loaded data.....${userPhone},${userPin}');
//     });
//   }

//   clearSharedPref() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     prefs.clear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Oye Yaaro',
//           style: TextStyle(fontSize: 22.0),
//         ),
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Colors.white,
//           tabs: <Widget>[
//             Tab(text: "CHAT"),
//             Tab(
//               // child: Text('GP.CHAT',style: TextStyle(fontWeight: FontWeight.bold,)),
//               text: "GP.CHAT",
//             ),
//             Tab(
//                 child: Image.asset('assets/video_call.png',
//                     width: 23.0, height: 23.0)
//                 // icon: new Icon(Icons.videocam) //camera_roll
//                 ),
//             Tab(
//               text: "ALBUMS",
//             ),
//             Tab(
//               text: "FEEDS",
//             ),
//           ],
//         ),
//         actions: <Widget>[
//           IconButton(
//             icon: Icon(Icons.home),
//             onPressed: () {
//               //  Navigator.pushReplacementNamed(context, '/homepage');
//                Navigator.of(context).pushNamedAndRemoveUntil(
//                         '/homepage', (Route<dynamic> route) => false);
//             },
//           ),
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 4.0),
//           ),
//           PopupMenuButton<Choice>(
//             onSelected: onItemMenuPress,
//             itemBuilder: (BuildContext context) {
//               return choices.map((Choice choice) {
//                 return PopupMenuItem<Choice>(
//                     value: choice,
//                     child: Row(
//                       children: <Widget>[
//                         Icon(
//                           choice.icon,
//                           color: Colors.indigo[900]
//                         ),
//                         Container(
//                           width: 10.0,
//                         ),
//                         Text(
//                           choice.title,
//                         ),
//                       ],
//                     ));
//               }).toList();
//             },
//           ),
//         ],
//       ),
//       body: WillPopScope(
//         child: Stack(
//           children: <Widget>[
//             new TabBarView(
//               controller: _tabController,
//               children: <Widget>[
//                 new ChatScreenState(),
//                 new GroupScreenState(),
//                 new CameraScreen(),
//                 new NetworkScreen(),                                
//               ],
//             ),
//           ],
//         ),
//         onWillPop: onBackPress,
//       ),
//       // floatingActionButton: new FloatingActionButton(
//       //   backgroundColor: Theme.of(context).accentColor,
//       //   child: Icon(
//       //     Icons.search,
//       //     color: Colors.white,
//       //   ),
//       //   onPressed: () {
//       //     Navigator.push(
//       //       context,
//       //       MaterialPageRoute(
//       //         builder: (context) => CreateGroup(
//       //             ),
//       //       ),
//       //     );
//       //   },
//       // ),
//     );
//   }

//   getUserProfile() async {
//     print('in GET Profile******************');
//     try {
//       http.Response response = await http.post(
//           "http://oyeyaaroapi.plmlogix.com/getProfile",
//           headers: {"Content-Type": "application/json"},
//           body: jsonEncode({"pin": '${this.userPin}'}));
//       var profileResult = jsonDecode(response.body);
//       if (profileResult['success'] == true) {
//       // print("clg-----------------....------->${profileResult['data'][0]['College']}");
//       // print("gid-----------------....------->${profileResult['data'][0]['Groups'][0]['dialog_id']}");
      
        
//         // SharedPreferences prefs = await SharedPreferences.getInstance();
//     // setState(() {
//     //   this.userGroupId = prefs.getString('groupId');
//     //   this.userClgNm = prefs.getString('collegeName');
//     // });

    

//       } else {
//         print('res false..');
//       }
//     } catch (e) {
//       print('Got Service Error ${e}');
//     }
//   }
// }
