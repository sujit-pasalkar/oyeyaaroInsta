import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home.dart';
import '../models/user.dart';

class UserPinPage extends StatefulWidget {
  final String phone;
  UserPinPage({
    Key key,
    this.phone,
  }) : super(key: key);

  @override
  _UserPinPageState createState() => new _UserPinPageState();
}

class _UserPinPageState extends State<UserPinPage> {
  static const platform = const MethodChannel('plmlogix.recordvideo/info');

  String userPin;
  final formKey = GlobalKey<FormState>();
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text('Login'),
          centerTitle: true,
          backgroundColor: Color(0xffb00bae3),
        ),
        resizeToAvoidBottomPadding: true,
        body: !loading
            ? ListView(
                padding: EdgeInsets.all(15.0),
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(15.50, 130.0, 15.50, 0.0),
                  ),
                  Form(
                      key: formKey,
                      autovalidate: true,
                      child: Column(children: <Widget>[
                        TextField(
                            decoration: InputDecoration(
                              hintText: 'Enter User Pin',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (input) {
                              print(input);
                              setState(() {
                                this.userPin = input;
                              });
                            }),
                      ])),
                  Padding(
                    padding: EdgeInsets.all(20.0),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(15.50, 0.0, 15.50, 0.0),
                    child: SizedBox(
                      height: 50.0,
                      child: FlatButton(
                        child: Text(
                          'Login',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        splashColor: Colors.green,
                        color: Color(0xffb00bae3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0)),
                        onPressed: () {
                          checkUser(
                            this.userPin,
                            _scaffoldKey,
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(20.0),
                    child: new FloatingActionButton(
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                      backgroundColor: Color(0xffb00bae3),
                      onPressed: () => clearSharedPref(),
                    ),
                  )
                ],
              )
            : Center(child: CircularProgressIndicator()));
  }

  clearSharedPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    FirebaseAuth.instance.signOut().then((action) {
      Navigator.pushReplacementNamed(context, '/loginpage');
    }).catchError((e) {
      print("*err:*" + e);
    });
  }

  checkUser(userPin, _scaffoldKey) async {
    this.loading = true;
    setState(() {});
    print('check:--------${this.userPin}');
    if (formKey.currentState.validate()) {
      formKey.currentState.save();
      try {
        http.Response response = await http.post(
            "http://54.200.143.85:4200/getProfile",
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"pin": '${userPin}'}));
        if (response.statusCode == HttpStatus.OK) {
          var result = jsonDecode(response.body);
          print(result);
          if (result['success'] == true) {
            //#invite
            http.Response respo = await http.post(
                "http://54.200.143.85:4200/setMember", // true invite
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({"pin": '${userPin}'}));
            print(respo.body);
            print('res success.. ');
            this.setUserToken(result);

            // Map<String, dynamic> data = Map<String, dynamic>();
            // data.addAll({"userPhone": widget.phone});
            // data.addAll({"userPin": userPin});
            // data.addAll({"email": result['data'][0]['Email']});
            // data.addAll({"userName": result['data'][0]['Name']});
            // data.addAll({"groupId": result['data'][0]['Groups'][0]['dialog_id']});
            // data.addAll({"collegeName": result['data'][0]['College']});
            // data.addAll({"hideChatMedia": 10});
            // print('setuser map :$data');
            // await currentUser.saveUser(data);
            currentUser.userId;

            //instag
            CollectionReference ref =
                Firestore.instance.collection('insta_users');
            ref.document(this.userPin).setData({
              "userId": userPin,
              "username": result['data'][0]['Name'],
              "photoUrl": "http://54.200.143.85:4200/profiles/now/" +
                  this.userPin +
                  ".jpg",
              "email": result['data'][0]['Email'],
              "following": {
                "Public": true,
                result['data'][0]['College']: true,
                result['data'][0]['Groups'][0]['dialog_id']: true,
              },
            });

            //#setUser verified phone
            http.Response setphn =
                await http.post("http://54.200.143.85:4200/setNumber",
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode(
                      {"pin": '${userPin}', 'mobile': '${widget.phone}'},
                    ));
            print(setphn.body);

            registerUserSinch(widget.phone).then((onValue) {
              print('reg succes to sinch');
            });

            this.loading = false;
            setState(() {});
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
            );
          } else {
            this.loading = false;
            setState(() {});
            print('res false..');
            final snackBar = SnackBar(
              content: Text('Incorrecr Pin!'),
            );
            _scaffoldKey.currentState.showSnackBar(snackBar);
            this.userPin = null;
          }
        } else {
          this.loading = false;
          setState(() {});
          print('response.statusCode...service res failed');
          final snackBar = SnackBar(
            content: Text('HttpStatus Error.'),
          );
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }
      } catch (e) {
        print('Got Service Error ${e}');
      }
    } else {
      this.loading = false;
      setState(() {});
      print('invalid');
    }
  }

  setUserToken(result
      // userDBPhone, userPin, name
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('UserPhone', widget.phone);
    prefs.setString('userPin', userPin);
    prefs.setString('userName', result['data'][0]['Name']);
    prefs.setString('groupId', result['data'][0]['Groups'][0]['dialog_id']);
    prefs.setString('collegeName', result['data'][0]['College']);
    prefs.setInt('hideChatMedia', 10);
    currentUser.loadUserDetails();
  }

  //#register user to sinch
  Future<String> registerUserSinch(String phone) async {
    print('SINCH PHONE ******${phone}');
    var sendMap = <String, dynamic>{
      'from': phone,
    };
    String result;
    try {
      result = await platform.invokeMethod('initsinch', sendMap);
    } on PlatformException catch (e) {}
    return result;
  }
}
