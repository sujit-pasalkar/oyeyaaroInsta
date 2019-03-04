import 'package:flutter/material.dart';
import 'viewPolicy.dart';
import 'dart:ui' as ui;

class PrivacyPolicyPage extends StatefulWidget {
  @override
  _PrivacyPolicyPageState createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage>
    with SingleTickerProviderStateMixin {
  //#Animation
  AnimationController _logoAnimationCtrl;
  Animation<double> _iconAnimationBounce;
  CurvedAnimation _iconAnimation; //

  bool _value1 = false;
  void _value1Changed() => setState(() => _value1 = !_value1);
  @override
  void initState() {
    super.initState();
    //#iconAnimation
    _logoAnimationCtrl = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this);
    _iconAnimation = CurvedAnimation(
        parent: _logoAnimationCtrl, curve: Curves.easeIn /* bounceOut */);
    _iconAnimationBounce =
        CurvedAnimation(parent: _logoAnimationCtrl, curve: Curves.bounceOut);
    _iconAnimation.addListener(() => this.setState(() {}));
    _iconAnimationBounce.addListener(() => this.setState(() {}));

    _logoAnimationCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
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
                  Padding(padding: EdgeInsets.all(20.0)),
                  Text(
                    "Welcome",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 30.0,
                    ),
                  ),
                  Text(
                    "to",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 30.0,
                    ),
                  ),
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
                  Padding(padding: EdgeInsets.all(10.0)),
                  FadeTransition(
                    opacity: _iconAnimation,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 50.0,
                      // child: ShaderMask(
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
                      child: Icon(
                        Icons.group,
                        color: Colors.indigo[900],
                        size: _iconAnimationBounce.value * 70.0,
                      ),
                      // )
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(30.0)),
                  Row(
                    children: <Widget>[
                      IconButton(
                        icon: _value1
                            ? Icon(
                                Icons.check_box,
                                color: Colors.white,
                              )
                            : Icon(Icons.check_box_outline_blank,
                                color: Colors.white),
                        onPressed: () {
                          _value1Changed();
                        },
                      ),
                      Text("Please press 'Accept' to accept the Oye Yaaro",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15.0,
                          ),),
                    ],
                  ),
                  // new CheckboxListTile(
                  //   value: _value1,
                  //   onChanged: _value1Changed,
                  //   title: new Text(
                  //       "Please press 'Accept' to accept the Oye Yaaro",
                  //       style: TextStyle(
                  //         fontWeight: FontWeight.bold,
                  //         color: Colors.white,
                  //         fontSize: 15.0,
                  //       )),
                  //   controlAffinity: ListTileControlAffinity.leading,
                  //   activeColor: Colors.grey,
                  // ),

                  GestureDetector(
                      onTap: () {
                        print("onTap called.");
                        Navigator.of(context).push(new MaterialPageRoute<Null>(
                            builder: (BuildContext context) {
                              return new ViewPolicy();
                            },
                            fullscreenDialog: true));
                      },
                      child: Text(
                        "Terms of Usage and Privacy Policy.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.indigo[900],
                          fontSize: 15.0,
                        ),
                      )),
                  Padding(padding: EdgeInsets.all(10.0)),
                  RaisedButton(
                      child: Text(
                        "Accept",
                        style: TextStyle(
                            color:
                                (this._value1) ? Colors.white : Colors.white),
                      ),
                      onPressed: _value1
                          ? () {
                              Navigator.of(context)
                                  .pushReplacementNamed('/loginpage');
                            }
                          : null,
                      color: Colors.indigo[900]),
                ],),),),
      ],)
    ],),);
  }
}
