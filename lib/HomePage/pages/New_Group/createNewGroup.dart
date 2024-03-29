import 'package:flutter/material.dart';
import 'createNewGroupModel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connect_yaar/home.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../ProfilePage/profile.dart';
import 'createNewGroupWithName.dart';

class CreateNewGroup extends StatefulWidget {
  final String appBarName, groupName, groupId;
  CreateNewGroup({@required this.appBarName, this.groupName, this.groupId});

  @override
  _CreateNewGroupState createState() => _CreateNewGroupState();
}

class _CreateNewGroupState extends State<CreateNewGroup> {
  List<dynamic> collegeStudentList = []; // List<dynamic>();

  final globalKey = new GlobalKey<ScaffoldState>();
  TextEditingController _controller = new TextEditingController();
  // TextEditingController _controllerGroupName = new TextEditingController(); //

  bool typing = false;
  List<dynamic> searchresult = List<dynamic>();
  bool showLoading = true;
  String val = "Loading  Student List";
  List<String> addInGroup = [];
  // bool create = false;

  @override
  void initState() {
    super.initState();
    // print('${widget.val}');
    getStudent();
  }

  @override
  void dispose() {
    super.dispose();
  }

  getStudent() async {
    collegeStudentList = await createNewGroup.getStudentList();
    print('collegeStudentList : $collegeStudentList');
    setState(() {
      searchresult = collegeStudentList;
      showLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        title: Text(widget.appBarName),
        backgroundColor: Color(0xffb00bae3),
        actions: <Widget>[
          !showLoading
              ? widget.appBarName == 'New Group'
                  ? FlatButton(
                      child: Text('Create',
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                      onPressed: addInGroup.length != 0
                          ? () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateGroupWithName(
                                        addInGroup: addInGroup),
                                  ));
                            }
                          : null,
                    )
                  : FlatButton(
                      //add new member to created grp direct call addmem service
                      child: Text('Add',
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                      onPressed: () {
                        setState(() {
                          showLoading = true;
                        });
                        createNewGroup
                            .addNewMembers(
                                widget.groupId, widget.groupName, addInGroup)
                            .then((res) {
                          print('added $res');
                          setState(() {
                            showLoading = false;
                          });
                          Fluttertoast.showToast(msg: 'Added in ${widget.groupName}');
                          Navigator.of(context).pop();
                        });
                      })
              : SizedBox(height: 0, width: 0),
        ],
      ),
      body: !showLoading
          ?
          // !create // no need 2 condtion
          //     ?
          Column(children: <Widget>[
              Container(
                margin: EdgeInsets.all(22.0),
                padding: EdgeInsets.fromLTRB(18.0, 0.0, 0.0, 0.0),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: TextField(
                          autofocus: false,
                          controller: _controller,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search by student name..'),
                          onChanged: (input) {
                            searchOperation(input);
                          }),
                    ),
                    this.typing
                        ? IconButton(
                            icon: Icon(Icons.close),
                            tooltip: 'search',
                            onPressed: () {
                              print('close student list');
                              setState(() {
                                this.typing = false;
                                this._controller.text = "";
                                searchresult = collegeStudentList;
                              });
                            },
                          )
                        : SizedBox(
                            height: 0,
                            width: 0,
                          )
                  ],
                ),
                decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: BorderRadius.circular(50.0)),
              ),
              Divider(height: 5.0),
              Flexible(
                child: ListView.builder(
                  itemCount: searchresult.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Column(children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          print('pin : ${searchresult[index]['PinCode']}');
                          if (addInGroup
                              .contains(searchresult[index]['PinCode'])) {
                            setState(() {
                              addInGroup.remove(searchresult[index]['PinCode']);
                            });
                            print("removed : $searchresult[index]['PinCode']");
                          } else {
                            setState(() {
                              addInGroup.add(searchresult[index]['PinCode']);
                            });
                            print("added : $addInGroup");
                          }
                        },
                        child: ListTile(
                            leading: GestureDetector(
                                child: Container(
                                  width: 50.0,
                                  height: 50.0,
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
                                          borderRadius:
                                              BorderRadius.circular(40.0),
                                          child: Image.network(
                                            'http://oyeyaaroapi.plmlogix.com/getAvatarImageNow/${searchresult[index]['PinCode']}',
                                            fit: BoxFit.cover,
                                          )
                                          // CachedNetworkImage(
                                          //   imageUrl:
                                          //   // !searchresult[index]
                                          //   //         ['ImageThen']
                                          //   //         .contains('default')
                                          //   //     ?
                                          //   'http://oyeyaaroapi.plmlogix.com/getAvatarImageNow/${searchresult[index]['PinCode']}',
                                          //       // : "http://oyeyaaroapi.plmlogix.com/profiles${searchresult[index]['ImageNow']}",
                                          //       fit: BoxFit.cover,
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
                                          ),
                                    ),
                                    // child: Container(
                                    //   margin: EdgeInsets.all(2.0),
                                    //   decoration: new BoxDecoration(
                                    //     shape: BoxShape.circle,
                                    //     color: Colors.grey,
                                    //     image: new DecorationImage(
                                    //       fit: BoxFit.cover,
                                    //       image: new NetworkImage(searchresult[
                                    //                   index]['ImageNow']
                                    //               .contains('default')
                                    //           ? "http://oyeyaaroapi.plmlogix.com/profiles${searchresult[index]['ImageThen']}"
                                    //           : "http://oyeyaaroapi.plmlogix.com/profiles${searchresult[index]['ImageNow']}"),
                                    //     ),
                                    //   ),
                                    // ),
                                  ),
                                ),
                                onTap: () {
                                  print("${searchresult[index]['PinCode']}");
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ProfilePage(
                                              userPin: searchresult[index]
                                                  ['PinCode'])));
                                }),
                            title: searchresult[index]['Name'] == null
                                ? Text(
                                    'Name not found',
                                  )
                                : Text(searchresult[index]['Name']),
                            subtitle: searchresult[index]['Groups'][0]
                                        ['group_name'] ==
                                    null
                                ? Text(
                                    'College not found',
                                  )
                                : Text(searchresult[index]['Groups'][0]
                                    ['group_name']),
                            trailing: addInGroup
                                    .contains(searchresult[index]['PinCode'])
                                ? Icon(
                                    Icons.check_circle,
                                    color: Color(0xffb00bae3),
                                    size: 30,
                                  )
                                : Icon(
                                    Icons.radio_button_unchecked,
                                    color: Color(0xffb00bae3),
                                    size: 30,
                                  )),
                      ),
                      Divider(height: 5.0),
                    ]);
                  },
                ),
              ),
            ])
          // :
          // group name  //make second page..making
          // Column(children: <Widget>[
          //     Container(
          //       margin: EdgeInsets.all(22.0),
          //       padding: EdgeInsets.fromLTRB(18.0, 0.0, 0.0, 0.0),
          //       child: Row(
          //         children: <Widget>[
          //           Flexible(
          //             child: TextField(
          //                 autofocus: true,
          //                 controller: _controllerGroupName,
          //                 cursorColor: Color(0xffb00bae3),
          //                 maxLength: 25,
          //                 style: TextStyle(
          //                     color: Colors.black,
          //                     fontWeight: FontWeight.bold,
          //                     fontSize: 18),
          //                 decoration: InputDecoration(
          //                     hintText: 'Type group name here..'),
          //                 onChanged: (input) {
          //                   print(input);
          //                 }),
          //           ),
          //         ],
          //       ),
          //     ),
          //     Divider(height: 5.0),
          //     Flexible(
          //       child: ListView.builder(
          //         itemCount: collegeStudentList.length,
          //         itemBuilder: (BuildContext context, int index) {
          //           return Column(children: <Widget>[
          //             addInGroup.contains(
          //                     collegeStudentList[index]['PinCode'])
          //                 ? ListTile(
          //                     leading: GestureDetector(
          //                       onTap: () {
          //                         print(addInGroup);
          //                       },
          //                       child: Container(
          //                         width: 50.0,
          //                         height: 50.0,
          //                         decoration: new BoxDecoration(
          //                           color: Color(0xffb00bae3),
          //                           shape: BoxShape.circle,
          //                         ),
          //                         child: Container(
          //                           margin: EdgeInsets.all(2.5),
          //                           decoration: new BoxDecoration(
          //                             color: Colors.white,
          //                             shape: BoxShape.circle,
          //                           ),
          //                           child: Container(
          //                             margin: EdgeInsets.all(2.0),
          //                             decoration: new BoxDecoration(
          //                               shape: BoxShape.circle,
          //                               color: Colors.grey[300],
          //                               image: new DecorationImage(
          //                                 fit: BoxFit.cover,
          //                                 image: new NetworkImage(
          //                                   'http://oyeyaaroapi.plmlogix.com/getAvatarImageNow/${collegeStudentList[index]['PinCode']}',
          //                                 ),
          //                               ),
          //                             ),
          //                           ),
          //                         ),
          //                       ),
          //                     ),
          //                     title: collegeStudentList[index]['Name'] ==
          //                             null
          //                         ? Text(
          //                             'Name not found',
          //                           )
          //                         : Text(collegeStudentList[index]['Name']),
          //                     subtitle: collegeStudentList[index]['Groups']
          //                                 [0]['group_name'] ==
          //                             null
          //                         ? Text(
          //                             'College not found',
          //                           )
          //                         : Text(collegeStudentList[index]['Groups']
          //                             [0]['group_name']),
          //                   )
          //                 : SizedBox(
          //                     height: 0,
          //                     width: 0,
          //                   ),
          //           ]);
          //         },
          //       ),
          //     ),
          //   ])
          : Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                    valueColor:
                        new AlwaysStoppedAnimation<Color>(Color(0xffb00bae3))),
                Padding(
                  padding: EdgeInsets.only(top: 10),
                ),
                Text('$val')
              ],
            )),
      // floatingActionButton: !create
      //     ? SizedBox(
      //         height: 0,
      //         width: 0,
      //       )
      //     : new FloatingActionButton(
      //         backgroundColor: Color(0xffb00bae3),
      //         child: Icon(
      //           Icons.check,
      //           color: Colors.white,
      //           size: 35,
      //         ),
      //         onPressed: () {
      //           print(_controllerGroupName.text);
      //           if (_controllerGroupName.text == "") {
      //             Fluttertoast.showToast(msg: 'Add a group name');
      //           } else
      //             createNewGroup
      //                 .createGroup(_controllerGroupName.text, addInGroup)
      //                 .then((res) {
      //               print('then res $res');
      //               if (res) {
      //                 Fluttertoast.showToast(
      //                     msg: "Group ${_controllerGroupName.text} Created");
      //                 Navigator.of(context).pop();
      //                 // Navigator.of(context).pop();
      //                 // Navigator.pushReplacement(
      //                 //   context,
      //                 //   MaterialPageRoute(
      //                 //     builder: (context) => HomePage(),
      //                 //   ),
      //                 // );
      //               } else
      //                 Fluttertoast.showToast(msg: "something went wrong");
      //             });
      //         },
      //       ),
    );
  }

  void searchOperation(String searchText) {
    setState(() {
      this.typing = true;
      searchresult = [];
    });

    //now iterate for student list
    print(searchresult.length);
    print(collegeStudentList.length);

    for (int i = 0; i < this.collegeStudentList.length; i++) {
      String data = this.collegeStudentList[i]['Name'];
      print('$data');

      if (data.toLowerCase().contains(searchText.toLowerCase())) {
        searchresult.add(this.collegeStudentList[i]);
      }
    }
    print('added..');
  }
}
