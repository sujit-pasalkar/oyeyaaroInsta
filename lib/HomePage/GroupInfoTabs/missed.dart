import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';
import '../../ProfilePage/profile.dart';
import 'package:cached_network_image/cached_network_image.dart';

Future<List<MissedUsers>> fetchUsers(peerId, http.Client client) async {
  var bodyData = jsonEncode({"dialog_id": "${peerId}"});
  final response = await client.post('http://oyeyaaroapi.plmlogix.com/getMissed',
      headers: {"Content-Type": "application/json"}, body: bodyData);
  // Use the compute function to run parsePhotos in a separate isolate
  var res = jsonDecode(response.body);
  return compute(parseUsers, jsonEncode(res["users"]));
}

// A function that will convert a response body into a List<Photo>
List<MissedUsers> parseUsers(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<MissedUsers>((json) => MissedUsers.fromJson(json)).toList();
}

class MissedUsers {
  final String Name;
  final String Stream;
  final String url;
  final String thumbnail;
  final String Mobile;
  final String UserPin;
  MissedUsers(
      {this.Name,
      this.thumbnail,
      this.Stream,
      this.url,
      this.Mobile,
      this.UserPin});
  factory MissedUsers.fromJson(Map<dynamic, dynamic> json) {
    return MissedUsers(
        Name: json['Name'] as String,
        thumbnail: json['ImageThen'] as String,
        Stream: json['Stream'] as String,
        url: json['College'] as String,
        Mobile: json['Mobile'] as String,
        UserPin: json['PinCode'] as String);
  }
}

class MissedPage extends StatelessWidget {
  final String peerId;
  MissedPage({Key key, this.peerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<MissedUsers>>(
        future: fetchUsers(this.peerId, http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);
          return snapshot.hasData
              ? PhotosList(users: snapshot.data)
              : Center(
                  child: CircularProgressIndicator(
                      valueColor: new AlwaysStoppedAnimation<Color>(
                          Color(0xffb00bae3))));
        },
      ),
    );
  }
}

class PhotosList extends StatelessWidget {
  final List<MissedUsers> users;

  PhotosList({Key key, this.users}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.builder(
          itemCount: users.length,
          padding: const EdgeInsets.all(5.0),
          itemBuilder: (context, position) {
            return Column(
              children: <Widget>[
                ListTile(
                  leading: GestureDetector(
                    child: Container(
                      width: 60.0,
                      height: 60.0,
                      decoration: new BoxDecoration(
                        color: Color(0xffb00bae3),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: EdgeInsets.all(2.5),
                        decoration: new BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                            margin: EdgeInsets.all(2.0),
                            decoration: new BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40.0),
                              child:
                              Image.network('http://oyeyaaroapi.plmlogix.com/getAvatarImageNow/${users[position].UserPin}',fit: BoxFit.cover,)
                              //  CachedNetworkImage(
                              //   imageUrl:
                              //       'http://oyeyaaroapi.plmlogix.com/getAvatarImageNow/${users[position].UserPin}',
                              //   // 'http://oyeyaaroapi.plmlogix.com/profiles${users[position].thumbnail}',
                              //   fit: BoxFit.cover,
                              //   placeholder: Padding(
                              //     padding: EdgeInsets.all(15),
                              //     child: SizedBox(
                              //       child: CircularProgressIndicator(
                              //           valueColor:
                              //               new AlwaysStoppedAnimation<Color>(
                              //                   Color(0xffb00bae3)),
                              //           strokeWidth: 1.0),
                              //     ),
                              //   ),
                              //   errorWidget: new Icon(
                              //     Icons.error,
                              //     color: Colors.black,
                              //   ),
                              // ),
                            )),

                        //

                        //
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                  userPin: users[position].UserPin)));
                    },
                  ),
                  title: new Text(
                    '${users[position].Name}',
                    style: new TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // subtitle: Text(
                  //   '${users[position].Mobile}',
                  //   style: new TextStyle(
                  //     fontSize: 18.0,
                  //     fontStyle: FontStyle.italic,
                  //   ),
                  // ),
                  trailing: Column(
                    children: <Widget>[
                      FlatButton(
                        child: Text(
                          'Invite',
                          style: TextStyle(color: Colors.white),
                        ),
                        splashColor: Colors.green,
                        color: Color(0xffb00bae3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0)),
                        onPressed: () {
                          invite(users[position].UserPin);
                        },
                      ),
                    ],
                  ),
                ),
                Divider(height: 5.0),
              ],
            );
          }),
    );
  }

  invite(pin) {
    //make clickablelink
    Share.share(
        'You are invited to join your classmates @OyeYaaro. Download this App using http://oyeyaaro.plmlogix.com/download use PIN #$pin to login.See you in the room chat!');
  }
}
