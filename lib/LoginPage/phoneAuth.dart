import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connect_yaar/UserPinPage/userPin.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PhonePage extends StatefulWidget {
  final String phone;
  final String countryCode;

  PhonePage({ this.phone,this.countryCode});// : super(key: key); Key: key,
  @override
  _phonePageState createState() => _phonePageState();
}

class _phonePageState extends State<PhonePage> {
  TextEditingController otpController = TextEditingController();
  String smsCode;
  String verificationId;
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool otpbtn;
  bool smsCode_Sent = false;
  bool userVerified = false;
  bool loading = false;

  @override
  void initState() {
    otpbtn = false;
    print('${widget.countryCode} : ${widget.phone} ');
    verifyPhone();
     super.initState();
  }

  Future<void> verifyPhone() async {
    print("phone =>"+widget.countryCode + widget.phone);
    final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
      this.verificationId = verId;
      print('**in -> 1.AutoRetrivalTimeOut**' + verId);
    };

    final PhoneCodeSent smsCodeSent = (String verId, [int forceCodeResend]) {
      this.verificationId = verId;
      print("2.smsSent_verifyid" + this.verificationId);
      this.smsCode_Sent = true;
    };

    final PhoneVerificationCompleted verifiedSuccess = (FirebaseUser user) {
      print('**4.verified**');
      userVerified = true;
      register();
    };

    final PhoneVerificationFailed veriFailed = (AuthException exception) {
      print('*5*Err ${exception.message}');
      Fluttertoast.showToast(
          msg: exception.message,
//          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIos: 1);
    };

    await FirebaseAuth.instance
        .verifyPhoneNumber(
        phoneNumber: widget.countryCode + widget.phone,
        codeAutoRetrievalTimeout: autoRetrieve,
        codeSent: smsCodeSent,
        timeout: const Duration(seconds: 10),
        verificationCompleted: verifiedSuccess,
        verificationFailed: veriFailed)
        .then((value) {
      print('**************AFTER VF***********');
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[900],
      resizeToAvoidBottomPadding: true,
      body: ListView(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(25.0, 55.0, 25.0, 25.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    child: Text(
                      'Oye Yaaro',
                      style: TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                  ),
                  Container(
                    child: Text(
                      'Relive nostalgia !',
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 30),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 50.0,
                    child: Icon(
                      Icons.group,
                      color: Colors.indigo[900],
                      size: 60.0,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 10.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      softWrap: true,
                      text: TextSpan(children: <TextSpan>[
                        TextSpan(
                          text: "Sit back and Relax while we verify your mobile number  ",
                          style: TextStyle(fontSize: 18.0, color: Colors.white),
                        ),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 25),
                  ),
                  Container(
                    child: RichText(
                      textAlign: TextAlign.center,
                      softWrap: true,
                      text: TextSpan(children: <TextSpan>[
                        TextSpan(
                          text:
                              "(Enter the OTP below in case we fail to detect the SMS automatically)",
                          style: TextStyle(fontSize: 15.0, color: Colors.white),
                        ),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(60, 0, 60, 0),
                    decoration: BoxDecoration(color: Colors.white),
                    child: TextField(
                      controller: otpController,
//                      maxLength: 6,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0),
                      textInputAction: TextInputAction.go,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Enter OTP',
                      ),
                      onChanged: (value) {

                        if(value.length == 6){
                          setState(() {
                            this.smsCode = value;
                            this.otpbtn = true;
                          });
                        }
                      },
                      onEditingComplete: () {},
                      onSubmitted: (value) {},
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                  ButtonTheme(
                    minWidth: 150.0,
                    height: 45.0,
                    child: RaisedButton(
                      child: Text(
                        'Submit',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      color: Colors.blue,
                      highlightColor: Colors.blue,
                      splashColor: Colors.lightGreen,
                      disabledColor: Colors.grey,
                      onPressed: this.otpbtn? () {
                        print(this.smsCode.length);
                        if (this.smsCode.length == 6) {
                          FirebaseAuth.instance.currentUser().then((user) {
                            print('user ${user}');
                            if (user != null) {
                              register();
                              print('user:${user}');
                            } else {
                              //call signIn
                              signIn(this.smsCode);
                              Fluttertoast.showToast(
                                  msg: 'OTP is Incorrect',
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIos: 1);
                            }
                          });
                        } else {
                          print("incorrect otp");
                          Fluttertoast.showToast(
                              msg: 'OTP is Incorrect',
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIos: 1);
                        }
                      }
                      :
                          null
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        RichText(
                          textAlign: TextAlign.center,
                          softWrap: true,
                          text: TextSpan(children: <TextSpan>[
                            TextSpan(
                                text: widget.countryCode,
                                style: TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                )),
                            TextSpan(
                              text: widget.phone,
                              style: TextStyle(
                                fontSize: 20.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                          tooltip: 'Edit your Number',
                          onPressed: () {
                            print('nav');
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> register() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
//      this.loading = false;
      print('in register setState set...');
      prefs.setString('userPhone', widget.phone);
    });
//    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UserPinPage(
          phone: widget.phone,
        ),
      ),
    );
  }

  signIn(smscode) {
    FirebaseAuth.instance
        .signInWithPhoneNumber(verificationId: verificationId, smsCode: smsCode)
        .then((user) {
      print('auth user is ---- > $user');
//      this.register();
    }, onError: (e) {
      print('....$e');
//      setState(() {
//        this.loading = false;
//      });
    });
  }

}
