import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
// import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Choice {
  const Choice({this.title, this.icon});
  final String title;
  final IconData icon;
}

class UserInfoPage extends StatefulWidget {
  final String name;
  final String pin;
  UserInfoPage({Key key, this.name, this.pin}) : super(key: key);

  @override
  _UserInfoStatePage createState() => new _UserInfoStatePage();
}

const kExpandedHeight = 300.0;

class _UserInfoStatePage extends State<UserInfoPage> {
  @override
  void initState() {
    super.initState();
    print('PIN::::${widget.pin}');
  }

  List<Choice> choices = const <Choice>[
    // const Choice(title: 'Profile', icon: Icons.person),
  ];

  Future getProfile() async {
    var body = jsonEncode({"pin": "${widget.pin}"});

    var result = await http.post("http://54.200.143.85:4200/getProfile",
        headers: {"Content-Type": "application/json"}, body: body);
    var res = jsonDecode(result.body);
    print('******profle data IS :${res}');
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
      future: getProfile(),
      builder: (context, snapshot) {
        print("***profile Snapshot...${snapshot.data}");
        if (snapshot.hasError) print("Error....${snapshot.error}");
        if (snapshot.hasData) {
          print('------>${snapshot.data['data'][0]['ImageThen']}');
          return CustomScrollView(slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              // leading: IconButton(icon: Icon(Icons.menu), onPressed: () {},),
              expandedHeight: kExpandedHeight, // TODO: check out later
              flexibleSpace: FlexibleSpaceBar(
                title: Text(widget.name),
                background: Image.network(
                  'http://54.200.143.85:4200/profiles${snapshot.data['data'][0]['ImageThen']}',
                  fit: BoxFit.cover,
                ),
              ),
        backgroundColor: Color(0xffb00bae3),
            ),
            new SliverList(
                delegate: SliverChildListDelegate([
              Card(
                child: Column(
                  children: <Widget>[
                    // Text('$snapshot'),
                    ListTile(
                        // leading: new CircleAvatar(
                        //   foregroundColor: Theme.of(context).primaryColor,
                        //   backgroundColor: Colors.grey,
                        //   backgroundImage: new NetworkImage(
                        //       "http://54.200.143.85:4200/profiles/then/${posts[position].receiverPin}.jpg"),
                        // ),
                        title: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Text(
                              'College',
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${snapshot.data['data'][0]['College']}', //
                          style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onTap: () => {}),
                    Divider(height: 5.0),
                    ListTile(
                        title: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Text(
                              'Year',
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${snapshot.data['data'][0]['Year']}', //
                          style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onTap: () => {}),
                    Divider(height: 5.0),
                    ListTile(
                        title: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Text(
                              'Stream',
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${snapshot.data['data'][0]['Stream']}', //
                          style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onTap: () => {}),
                  ],
                ),
              ),
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                        title: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Text(
                              'Mobile',
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${snapshot.data['data'][0]['Mobile']}',
                          style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onTap: () => {}),
                    Divider(height: 5.0),
                    ListTile(
                        title: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Text(
                              'Email',
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${snapshot.data['data'][0]['Email']}',
                          style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onTap: () => {}),
                    Divider(height: 5.0),
                    ListTile(
                        title: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Text(
                              'DOB',
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${snapshot.data['data'][0]['DOB']}',
                          style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onTap: () => {}),
                    Divider(height: 5.0),
                    ListTile(
                        title: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Text(
                              'NikName',
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${snapshot.data['data'][0]['NikName']}',
                          style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onTap: () => {}),
                    Divider(height: 5.0),
                    ListTile(
                        title: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Text(
                              'PinCode',
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${snapshot.data['data'][0]['PinCode']}',
                          style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onTap: () => {}),
                    Divider(height: 5.0),
                    ListTile(
                        title: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Text(
                              'Company',
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${snapshot.data['data'][0]['Company']}',
                          style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onTap: () => {}),
                    Divider(height: 5.0),
                    ListTile(
                        title: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Text(
                              'Designation',
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${snapshot.data['data'][0]['Designation']}',
                          style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onTap: () => {}),
                    Divider(height: 5.0),
                    ListTile(
                        title: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Text(
                              'Loaction',
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${snapshot.data['data'][0]['Loaction']}',
                          style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onTap: () => {}),
                    Divider(height: 5.0),
                    ListTile(
                        //iterate group list here.. (button and open list)
                        leading: new CircleAvatar(
                          foregroundColor: Theme.of(context).primaryColor,
                          backgroundColor: Colors.grey,
                          backgroundImage: new NetworkImage(""),
                        ),
                        title: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Text(
                              'Group_Name',
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'list_of_contacts',
                          style: new TextStyle(
                            fontSize: 18.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onTap: () => {}),
                  ],
                ),
              ),
              // Text('fsdfs')
            ])),
          ]);
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    ));
  }

  // profile(snapshot) {
  //   print('SNAP::: $snapshot');
  //   return Container(
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: <Widget>[
  //         Card(
  //           child: Column(
  //             children: <Widget>[
  //               Text('$snapshot'),
  //               ListTile(
  //                   title: new Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: <Widget>[
  //                       new Text(
  //                         'College',
  //                         style: new TextStyle(fontWeight: FontWeight.bold),
  //                       ),
  //                     ],
  //                   ),
  //                   subtitle: Text(
  //                     '',
  //                     style: new TextStyle(
  //                       fontSize: 18.0,
  //                       fontStyle: FontStyle.italic,
  //                     ),
  //                   ),
  //                   onTap: () => {}),
  //               Divider(height: 5.0),
  //             ],
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }

  void onItemMenuPress(Choice choice) {
    // if (choice.title == 'Log out') {
    // }
  }
}
