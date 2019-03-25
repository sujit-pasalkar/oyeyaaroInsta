import 'package:flutter/material.dart';
import '../../../models/group_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
// import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroupChatInfoPage extends StatefulWidget {
  final String name;
  final List<GroupModel> groupInfo;
  final String dialogId;

  GroupChatInfoPage({Key key, this.name, this.groupInfo, this.dialogId})
      : super(key: key);

  @override
  _GroupChatInfoStatePage createState() => new _GroupChatInfoStatePage();
}

class _GroupChatInfoStatePage extends State<GroupChatInfoPage> {
  int myId;
  String QBToken;
  String addUserId = null;
  List<dynamic> occupantsId;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> getShared() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    myId = prefs.getInt('UserId');
    this.QBToken = prefs.getString('UserToken');

    var body = jsonEncode(
        {"dialog_id": "${widget.dialogId}", "user_id": "${this.myId}"});

    var result = await http.post("http://oyeyaaroapi.plmlogix.com/isAdmin",
        headers: {"Content-Type": "application/json"}, body: body);
    //     .then((response) {
    var res = jsonDecode(result.body);
    print('******ADMIN IS :${res["admin"]}');
    occupantsId = res["data"][0]["occupants_ids"];
    print('*************OCCUPANT IDS: ${this.occupantsId}');
    return res["admin"];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            centerTitle: false,
            expandedHeight: 250.0,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                'http://lorempixel.com/output/city-q-c-640-480-9.jpg',
                fit: BoxFit.cover,
              ),
              title: Text(widget.name),
              centerTitle: false,
            ),
            actions: <Widget>[
              FutureBuilder(
                future: getShared(),
                builder: (context, snapshot) {
                  print("***IS ADMIN Snapshot...${snapshot.data}");
                  if (snapshot.hasError) print("Error....${snapshot.error}");
                  return snapshot.data == true
                      ? IconButton(
                          icon: const Icon(Icons.group_add),
                          onPressed: () {
                            openDailog();
                          },
                        )
                      : Center();
                },
              )
            ],
            backgroundColor: Color(0xffb00bae3),
          ),
          // SliverList(),
          // SliverGrid(
          //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //     crossAxisCount: 3,
          //     mainAxisSpacing: 10.0,
          //     crossAxisSpacing: 10.0,
          //     childAspectRatio: 5.0,
          //   ),
          //   delegate:
          //       SliverChildBuilderDelegate((BuildContext context, int index) {
          //     return Container(
          //       alignment: Alignment.center,
          //       color: Colors.purple[100 * (index % 9)],
          //       child: Text('Grid Item: $index'),
          //     );
          //   }, childCount: 102),
          // ),

//           SliverFillViewport(
//             delegate:
//                 SliverChildBuilderDelegate((BuildContext context, int index) {
//               return Container(
//                   color: Colors.lightBlue[200],
//                   child: Column(
//                     children: <Widget>[
//                       // Text('---${occupantsId[0]}'),
//                       // Text(data),

// //                       ListView.builder(
// //                           itemCount: this.occupantsId.length,
// //                           itemBuilder: (context, index) {
// //                             return ListTile(
// //                               title: new Text('---${occupantsId[index]}'),
// // //                      onTap: openChat,
// //                             );
// //                           })
//                     ],
//                   ));
//             }, childCount: 1),
//           ),
          // SilverList(),

          SliverFixedExtentList(
            itemExtent: 60.0,
            delegate: SliverChildListDelegate(
              [
                Container(color: Colors.red),
                Container(color: Colors.purple),
                Container(color: Colors.green),
                Container(color: Colors.orange),
                Container(color: Colors.yellow),
                Container(color: Colors.pink),
              ],
            ),
            //     SliverChildBuilderDelegate((BuildContext context, int index) {
            //   return Container(
            //     alignment: Alignment.center,
            //     color: Colors.indigo[100 ],
            //     child: Text('List Item: $index'),
            //   );
            // }),
          )
        ],
      ),
    );
  }

  openDailog() {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('Enter User Id to add User in this Group'),
            content: TextField(
              decoration: InputDecoration(
                labelText: "Enter User Id",
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (value) {
                this.addUserId = value;
              },
            ),
            contentPadding: EdgeInsets.all(10.0),
            actions: <Widget>[
              new FlatButton(
                child: Text('Add User'),
                onPressed: () {
                  // Navigator.of(context).pop();
                  AddUserService();
                },
              ),
              // new FlatButton(
              //   child: Text('Done'),
              //   onPressed: () {},
              // )
            ],
          );
        });
  }

  AddUserService() {
    print(
        'USER ID :${this.addUserId}, widget Id :${widget.name},  dailogID :${widget.dialogId},  Qb :${this.QBToken}');
    if (this.addUserId != null) {
      var bodyNew = jsonEncode({
        "name": "${widget.name}",
        "push_all": {
          "occupants_ids": [this.addUserId]
        }
      });
      http
          .put(
              "https://api.quickblox.com/chat/Dialog/${widget.dialogId}.json", //QuikBlox service
              headers: {
                "Content-Type": "application/json",
                "QB-Token": '${this.QBToken}'
              },
              body: bodyNew)
          .then((response) {
        var addRes = json.decode(response.body);
        print('ADD USER RES**** ${addRes}');
        if (addRes.containsKey("errors")) {
          print('got err');
        } else {
          print("success.now adding in mongo..");
          var bodyNew =
              jsonEncode({"name": "${widget.name}", "id": "${this.addUserId}"});
          http
              .post("http://54.200.143.85:4000/addMember", //mongo service
                  headers: {
                    "Content-Type": "application/json",
                  },
                  body: bodyNew)
              .then((response) {
            print("MongoDB res : ${response}");
          });
        }
      });
    } else {
      return showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return new AlertDialog(
              title: Text('Incorrect User Id'),
              content: Text('Please Enter correct User Id'),
              contentPadding: EdgeInsets.all(10.0),
              actions: <Widget>[
                new FlatButton(
                  child: Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    }
  }
}
