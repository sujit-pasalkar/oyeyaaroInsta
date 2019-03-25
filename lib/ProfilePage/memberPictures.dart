import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'profile.dart';

//join
class JoinedUsers {
  final String Name;
  final String Stream;
  final String College;
  final String thumbnail;
  final String Mobile;
  final String UserPin;
  JoinedUsers(
      {this.Name,
      this.thumbnail,
      this.Stream,
      this.College,
      this.Mobile,
      this.UserPin});

  factory JoinedUsers.fromJson(Map<String, dynamic> json) {
    return JoinedUsers(
        Name: json['Name'] as String,
        thumbnail: json['ImageThen'] as String,
        Stream: json['Stream'] as String,
        College: json['College'] as String,
        Mobile: json['Mobile'] as String,
        UserPin: json['PinCode'] as String);
  }
}

removeSelf(pin, arrs) {
  var arr = [];
  for (var i = 0; i < arrs.length; i++) {
    if (arrs[i]['PinCode'] != pin) {
      arr.add(arrs[i]);
    }
  }
  return arr;
}

Future<List<JoinedUsers>> fetchJoinUsers(peerId, http.Client client) async {
  var arr = [];
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String userPin = prefs.getString('userPin');

  var bodyData = jsonEncode({"dialog_id": "${peerId}"});
  print('JOINED FETCHED DATA:: ${bodyData}');
  //join
  final responseJ = await client.post('http://oyeyaaroapi.plmlogix.com/getJoined',
      headers: {"Content-Type": "application/json"}, body: bodyData);
  // Use the compute function to run parsePhotos in a separate isolate
  var resJ = jsonDecode(responseJ.body);
  print('RESJ-------->${resJ['users'].length}');
  arr = await removeSelf(userPin, resJ["users"]);

  //missed
  final responseM = await client.post('http://oyeyaaroapi.plmlogix.com/getMissed',
      headers: {"Content-Type": "application/json"}, body: bodyData);
  // Use the compute function to run parsePhotos in a separate isolate
  var resM = jsonDecode(responseM.body);
  print('RESm-------->${resM['users']}');
  arr = new List.from(resJ['users'])..addAll(resM['users']);
  return compute(parseUsersJ, jsonEncode(arr));
}

List<JoinedUsers> parseUsersJ(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<JoinedUsers>((json) => JoinedUsers.fromJson(json)).toList();
}

//class
class Members extends StatefulWidget {
  final String peerId;
  final String groupName;

  Members({Key key, @required this.peerId, @required this.groupName})
      : super(key: key);

  @override
  _MembersState createState() => _MembersState();
}

class _MembersState extends State<Members> {
//  final ScrollController hideButtonController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("${widget.groupName}"),
        elevation: 0.7,
        backgroundColor: Color(0xffb00bae3),
      ),
      body: FutureBuilder<List<JoinedUsers>>(
        future: fetchJoinUsers(widget.peerId, http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);
          return snapshot.hasData
              ? UsersList(snapshot.data)
              : Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        new AlwaysStoppedAnimation<Color>(Color(0xffb00bae3)),
                  ),
                );
        },
      ),
    );
  }

  Widget UsersList(data) {
    print('${data.length}');
    return GridView.count(
      primary: false,
      padding: EdgeInsets.all(8.0),
      crossAxisSpacing: 8.0,
      crossAxisCount: 3,
//      controller: widget.hideButtonController,
      children: List.generate(data.length, (index) {
        return Center(
            child: Column(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                print('open this user profile');
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(userPin: data[index].UserPin)));
              },
              child: Stack(
                children: <Widget>[
                  Container(
                    width: 150.0,
                    height: 100.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Color(0xffb00bae3), // Colors.indigo[900],
                    ),
                    child: Container(
                      margin: EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(5),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(
                              "http://oyeyaaroapi.plmlogix.com/profiles${data[index].thumbnail}"),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: Container(
                        padding: EdgeInsets.all(3),
                        margin: EdgeInsets.fromLTRB(3, 0, 3, 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(5.0),
                            bottomRight: Radius.circular(5.0),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: <Color>[
                              Colors.black.withOpacity(0.60),
                              Colors.black.withOpacity(0.35),
                            ],
                          ),
                        ),
                        child: Text(
                          '${data[index].Name}',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            decorationStyle: TextDecorationStyle.solid,
                            decoration: TextDecoration.none,
                            fontSize: 12.0,
                          ),
                        )),
                  )
                ],
              ),
            ),
          ],
        )

//          Container(
//            child:
////            Text('${data[index].Name}'),
//            Text('${data[index].thumbnail}'),
//          ),
            );
      }),
    );
  }
}
