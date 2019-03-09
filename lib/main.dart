import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './LoginPage/login.dart';
import 'package:connect_yaar/ProfilePage/profile.dart';
// import 'HomePage/pages/New_Group/searchGroup.dart';
import 'PrivacyPage/privacyPolicy.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'UserPinPage/userPin.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:flutter/services.dart';
import 'home.dart';
import 'models/user.dart';
import 'ProfilePage/profile.dart';
import 'package:fluttertoast/fluttertoast.dart'; //
import 'package:connect_yaar/models/data-service.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Oye Yaaro',
        debugShowCheckedModeBanner: false,
        home: MainPage(),
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.indigo[900],
          accentColor: Colors.indigo[900],
        ),
        routes: <String, WidgetBuilder>{
          '/profilepage': (BuildContext context) => ProfilePage(
                userPin: currentUser.userId,
              ),
          '/loginpage': (BuildContext context) => LoginPage(),
          '/homepage': (BuildContext context) => HomePage(),
          '/mainpage': (BuildContext context) => MainPage(),
          '/privacypolicy': (BuildContext context) => PrivacyPolicyPage(),
          // '/searchPage': (BuildContext context) => SearchGroupList(),
        });
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  static const platform = const MethodChannel('plmlogix.recordvideo/info');

  //#connectivity
  var _connectionStatus = 'Unknown';
  Connectivity connectivity;
  StreamSubscription<ConnectivityResult> subscription;

  //#fcm
  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  //#class var
  bool isLoggedIn;
  String userPhone;
  String userPin;
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    checkPermission();
    isLoggedIn = false;
    super.initState();
    print('init main: islogin-$isLoggedIn, userPin-$userPin');

//#connectivity
    connectivity = new Connectivity();
    subscription =
        connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectionStatus = result.toString();
        //temp
        if (result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile) {
          FirebaseAuth.instance.currentUser().then((user) => user != null
              ? setState(() {
                  print('fb user..');
                  isLoggedIn = true;
                })
              : null);
          _loadUserState().then((result) {
            this.checkUserProfile();
          });
        }
      });
      print("..." + _connectionStatus);
      if (result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile) {
        setState(() {
          print('got connection');
        });
      }
      if (result == ConnectivityResult.none) {
        print('no  internet');
      }
    });

    //#fcm
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
      print('Token:${token}');
    });
  }

  Future<String> checkPermission() async {
    final res = await SimplePermissions.requestPermission(
        Permission.ReadExternalStorage);
    print("permission request result is " + res.toString());
    final res1 = await SimplePermissions.requestPermission(
        Permission.WriteExternalStorage);
    print("permission request result is " + res1.toString());
    final res2 = await SimplePermissions.requestPermission(Permission.Camera);
    print("permission request result is " + res2.toString());
    final res3 = await SimplePermissions.requestPermission(
        Permission.AccessFineLocation);
    print("permission request result is " + res3.toString());
    final res4 =
        await SimplePermissions.requestPermission(Permission.RecordAudio);
    print("permission request result is " + res4.toString());
    final res5 =
        await SimplePermissions.requestPermission(Permission.PhotoLibrary);
    print("permission request result is " + res5.toString());

    return "result";
  }

  _loadUserState() async {
    // print("in main userLoaded: ${currentUser.userId} , ${currentUser.username} , ${currentUser.groupId} , ${currentUser.collegeName} , ${currentUser.phone} , ${currentUser.email} , ${currentUser.filterActive} ,");

    // #check phone no in mobile locale storage
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      this.userPhone = (prefs.getString('userPhone') ?? null);
      this.userPin = (prefs.getString('userPin') ?? null); 

      print('in userPhone: $userPhone');
      print('in userPin: $userPin');
    });
  }

  Future<void> checkUserProfile() async {
    print('in checking user profile:${this.userPhone},${this.userPin}');
    if (this.isLoggedIn == true || userPhone != null) {
      //&&
      print('you are login(firebase)');
      if (this.userPin == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserPinPage(phone: this.userPhone),
          ),
        );
      } else if (this.userPin != null) {
        http.Response response = await http.post(
            "http://54.200.143.85:4200/getProfile",
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"pin": '${this.userPin}'}));

        if (response.statusCode == HttpStatus.OK) {
          var result = jsonDecode(response.body);

          if (result['success'] == true) {
            http.Response respo = await http.post(
                "http://54.200.143.85:4200/setMember", //to set user
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({"pin": "${userPin}"}));
            // print(respo.body);
            print('res success..${result['data'][0]['Mobile']}');
            // currentUser.toString();
            await dataService.initialize();
            // # reg to sinch
            registerUserSinch(this.userPhone).then((onValue) {
              print('reg succes to sinch');
            });

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
            );
          } else {
            Fluttertoast.showToast(msg: 'getProfile service Response failed');
            // print('res false..incorrecr  pin...give toast');
          }
        } else {
          // print('response.statusCode...service res failed');
          Fluttertoast.showToast(msg: 'getProfile service Response failed');
        }
      }
    } else {
      print('you are not login');
      print("go to privacy ");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PrivacyPolicyPage(),
        ),
      );
    }
  }

  //#register user to sinch
  Future<String> registerUserSinch(String phone) async {
    var sendMap = <String, dynamic>{
      'from': phone,
    };
    String result;
    try {
      result = await platform.invokeMethod('initsinch', sendMap);
    } on PlatformException catch (e) {}
    return result;
  }

  loadingSpinner(_scaffoldKey) {
    print('internet : ${_connectionStatus}');
    if (this._connectionStatus == 'ConnectivityResult.none' ||
        this._connectionStatus == 'Unknown') {
      return Container(
          child: Column(children: <Widget>[
        Text(
          "No Internet Connection",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        Padding(padding: EdgeInsets.all(10.0)),
        CircularProgressIndicator(
          valueColor: new AlwaysStoppedAnimation(Colors.white),
        ),
      ]));
    } else {
      return Text('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(fit: StackFit.expand, children: <Widget>[
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.3, 0.4, 0.5, 0.6, 0.7, 0.8],
              colors: [
                Color(0xffb00ddf0),
                Color(0xffb00dcf2),
                Color(0xffb00bae3),
                Color(0xffb008bd0),
                Color(0xffb0081cc),
                Color(0xffb0082cd),
              ],
            ),
          ),
        ),
        Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Expanded(
              flex: 2,
              child: Container(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                    Text(
                      "Oye Yaaro",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 40.0,
                      ),
                    ),
                    Padding(padding: EdgeInsets.all(10.0)),
                    Text(
                      "Relive Nostalgia!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    Padding(padding: EdgeInsets.only(top: 40.0)),
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 60.0,
                      child:
                          // ShaderMask(
                          //   blendMode: BlendMode.srcIn,
                          //   shaderCallback: (Rect bounds) {
                          //     return ui.Gradient.linear(
                          //       Offset(4.0, 24.0),
                          //       Offset(24.0, 4.0),
                          //       [
                          //         Color(0xffb6de9f5),
                          //         Color(0xffb98b6fc),
                          //       ],
                          //     );
                          //   },
                          //   child: Icon(
                          //     Icons.group,
                          //     size: 80.0,
                          //   ),
                          // )
                          Icon(
                        Icons.group,
                        color: Colors.indigo[900],
                        size: 80.0,
                      ),
                    ),
                    Padding(padding: EdgeInsets.all(40.0)),
                    loadingSpinner(_scaffoldKey),
                  ])))
        ])
      ]),
    );
  }
}
