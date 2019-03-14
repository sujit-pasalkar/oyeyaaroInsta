import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connect_yaar/UserPinPage/userPin.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _smsCodeController = TextEditingController(); //

  String phoneNo;
  String smsCode;
  String verificationId;
  bool userVerified = false;
  bool loading = false;
  String loadingMsg = "";
  bool smsCode_Sent = false;
  bool verifybtn;

  final formKey = GlobalKey<FormState>();
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    // this.getSharedInstances();
    super.initState();
    verifybtn = false;
  }

  List<DropdownMenuItem<String>> _country_codes = [];
  String _country_code = null;
  String url;

  void loadData() {
    _country_codes = [];
    _country_codes.add(
      new DropdownMenuItem(child: new Text('India'), value: '+91'),
    );
    _country_codes.add(
        new DropdownMenuItem(child: new Text('United States'), value: '+1'));
  }

  Future<void> verifyPhone(_scaffoldKey) async {
    final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
      this.verificationId = verId;
      print('**in -> 1.AutoRetrivalTimeOut**' + verId);
    };

    final PhoneCodeSent smsCodeSent = (String verId, [int forceCodeResend]) {
      this.verificationId = verId;
      print("2.smsSent_verifyid" + this.verificationId);
      setState(() {
        this.loading = false;
        this.loadingMsg = "";
        this.smsCode_Sent = true;
      });

      smsCodeDialog(_scaffoldKey).then((value) {
        print('** Done clicked **');
      });
    };

    final PhoneVerificationCompleted verifiedSuccess = (FirebaseUser user) {
      print('**4.verified**');
      setState(() {
        this.loading = false;
        this.loadingMsg = "";
      });

      final snackBar = SnackBar(
        content: Text("Phone Number verified Successfully."),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
      register();
    };

    final PhoneVerificationFailed veriFailed = (AuthException exception) {
      print('*5*Err ${exception.message}');
      setState(() {
        this.loading = false;
        this.loadingMsg = "";
      });
      final snackBar = SnackBar(
        content: Text(exception.message),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
    };

    await FirebaseAuth.instance
        .verifyPhoneNumber(
            phoneNumber: this._country_code + this.phoneNo,
            codeAutoRetrievalTimeout: autoRetrieve,
            codeSent: smsCodeSent,
            timeout: const Duration(seconds: 10),
            verificationCompleted: verifiedSuccess,
            verificationFailed: veriFailed)
        .then((value) {
      print('AFTER Verification');
    });
  }

  smsCodeDialog(_scaffoldKey) {
    print('smsCode == :${this.smsCode_Sent}');
    // this.loading = false;
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('Enter 6-digit Code'),
            content: TextField(
              decoration: InputDecoration(
                labelText: 'Enter OTP',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (value) {
                this.smsCode = value;
                //on 6th input auto nav
              },
            ),
            contentPadding: EdgeInsets.all(10.0),
            actions: <Widget>[
              new FlatButton(
                child: Text(
                  'Resend',
                  style: TextStyle(color: Color(0xffb00bae3)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  verifyPhone(_scaffoldKey);
                },
              ),
              new FlatButton(
                child: Text(
                  'Done',
                  style: TextStyle(color: Color(0xffb00bae3)),
                ),
                onPressed: () {
                  setState(() {
                    this.loading = true;
                    // this.loadingMsg = ""
                  });
                  print(this.smsCode.length);
                  if (this.smsCode.length == 6) {
                    FirebaseAuth.instance.currentUser().then((user) {
                      print('user ${user}');
                      if (user != null) {
                        register();
                        print('user:${user}');
                        print("phone" + this.phoneNo);
                      } else {
                        signIn(this.smsCode);
                      }
                    });
                  } else {
                    setState(() {
                      this.loading = false;
                    });
                    print("incorrect otp");
                    final snackBar = SnackBar(
                      content: Text("Enter 6-digit OTP"),
                    );
                    _scaffoldKey.currentState.showSnackBar(snackBar);
                  }
                },
              )
            ],
          );
        });
  }

  Future<void> register() async {
    print('after setting phone..register');
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UserPinPage(
              phone: this.phoneNo,
            ),
      ),
    );
  }

  signIn(smscode) {
    FirebaseAuth.instance
        .signInWithPhoneNumber(verificationId: verificationId, smsCode: smsCode)
        .then((user) {
      print('auth user is ---- > $user');
      this.register();
    }, onError: (e) {
      print('incorrect otp :$e');
      setState(() {
        this.loading = false;
      });

      // if (userVerified == true) {
      //   final snackBar = SnackBar(
      //     content: Text(''),
      //   );
      //   _scaffoldKey.currentState.showSnackBar(snackBar);
      // }

      // if(e== 'PlatformException(exception, The sms code has expired. Please re-send the verification code to try again., null)'){
      //   final snackBar = SnackBar(
      //   content: Text('Got platform Ex'),
      // );
      // _scaffoldKey.currentState.showSnackBar(snackBar);
      // }
      print("incorrect otp");
      final snackBar = SnackBar(
        content: Text("The sms verification code is invalid."),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
      Navigator.of(context).pop();
    });
  }

  phoneConfirmAlert(_scaffoldKey) {
    if (formKey.currentState.validate()) {
      if (this._country_code == null) {
        final snackBar = SnackBar(content: Text("Select country code!"));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      } else {
        setState(() {
          this.loading = true;
          verifybtn = false;
          this.loadingMsg = "Verifying Your Number";
        });
        formKey.currentState.save();
        verifyPhone(_scaffoldKey);
        // signIn(this.smsCode);
      }
    } else
      print("invalid form");
  }

  @override
  Widget build(BuildContext context) {
    loadData();
    return new Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: new Text('Verify Your Phone Number'),
        centerTitle: true,
        backgroundColor: Color(0xffb00bae3),
      ),
      resizeToAvoidBottomPadding: true,
      body: body(),
    );
  }

  Widget body() {
    if (!loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new Expanded(
              child: ListView(
            padding: EdgeInsets.all(15.0),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 25.0),
              ),
              Text(
                "Please Select Your Country and Enter  Phone Number",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
              ),
              Container(
                padding: EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(width: 1.0, color: Colors.black38),
                        bottom: BorderSide(width: 1.0, color: Colors.black38))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                    value: _country_code,
                    items: _country_codes,
                    hint: new Text(
                      'Select Country',
                      style: TextStyle(color: Colors.black38),
                    ),
                    onChanged: (value) {
                      _country_code = value;
                      setState(() {
                        _country_code = value;
                      });
                    },
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(width: 1.0, color: Colors.black38))),
                child: Form(
                    key: formKey,
                    autovalidate: true,
                    child: Column(children: <Widget>[
                      Table(
                        columnWidths: {1: FractionColumnWidth(.8)},
                        children: [
                          TableRow(children: [
                            Container(
                              padding:
                                  EdgeInsets.fromLTRB(10.0, 11.0, 0.0, 0.0),
                              child: Text(
                                (_country_code == null)
                                    ? ('+1')
                                    : _country_code,
                              ),
                            ),
                            TextField(
                                //TextFormField
                                decoration: InputDecoration(
                                  hintText: 'Enter Phone Number',
                                  border: InputBorder.none,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (input) {
                                  print(input);
                                  if (input.length == 10) {
                                    setState(() {
                                      verifybtn = true;
                                      this.phoneNo = input;
                                      // phoneConfirmAlert(
                                      //   _scaffoldKey,
                                      // );
                                    });
                                  } else {
                                    setState(() {
                                      verifybtn = false;
                                    });
                                  }
                                }),
                          ]),
                        ],
                      ),
                    ])),
              ),
              Container(
                padding: EdgeInsets.only(top: 10.0),
                child: Text(
                  'You will receive an OTP on the mobile number you have..',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            ],
          )),
          Container(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: SizedBox(
              height: 50.0,
              child: RaisedButton(
                child: Text(
                  'Verify',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                splashColor: Colors.green,
                color: Color(0xffb00bae3),
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(30.0)),
                onPressed: !verifybtn
                    ? null
                    : () {
                        print('${this._country_code}-${this.phoneNo}');
                        phoneConfirmAlert(
                          _scaffoldKey,
                        );
                      },
              ),
            ),
          ),
        ],
      );
    } else {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation<Color>(Color(0xffb00bae3)),
          ),
          Padding(
            padding: EdgeInsets.all(5),
          ),
          Text(
            loadingMsg,
            style: TextStyle(
                color: Color(0xffb00bae3), fontWeight: FontWeight.bold),
          ),
        ],
      ));
    }
  }

  //bottomSheet (list of clgs to share video)
  shareWith() {
    showModalBottomSheet(
        context: context,
        // barrierDismissible: false,
        builder: (builder) {
          return new Container();
        });
  }
}
