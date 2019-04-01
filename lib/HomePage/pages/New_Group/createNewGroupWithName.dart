import 'package:flutter/material.dart';
import 'createNewGroupModel.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreateGroupWithName extends StatefulWidget {
  final List<String> addInGroup;
  CreateGroupWithName({@required this.addInGroup});

  @override
  _CreateGroupWithNameState createState() => _CreateGroupWithNameState();
}

class _CreateGroupWithNameState extends State<CreateGroupWithName> {
  List<dynamic> collegeStudentList = []; // List<dynamic>();

  final globalKey = new GlobalKey<ScaffoldState>();
  TextEditingController _controllerGroupName = new TextEditingController();
  bool showLoading = true;

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
      showLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
          title: Text('New Group'), //change dynamic
          backgroundColor: Color(0xffb00bae3),
          actions: <Widget>[
            FlatButton(
                //add  member to  grp... pop back with pass data(list of participants)
                child: Text('Add Members',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                onPressed: () {
                  print('add');
                  // setState(() {
                  // });
                })
          ]),
      body: !showLoading
          ? Column(children: <Widget>[
              Container(
                margin: EdgeInsets.all(22.0),
                padding: EdgeInsets.fromLTRB(18.0, 0.0, 0.0, 0.0),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: TextField(
                          autofocus: true,
                          controller: _controllerGroupName,
                          cursorColor: Color(0xffb00bae3),
                          maxLength: 25,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                          decoration: InputDecoration(
                              hintText: 'Type group name here..'),
                          onChanged: (input) {
                            print(input);
                          }),
                    ),
                  ],
                ),
              ),
              Divider(height: 5.0),
              Flexible(
                child: ListView.builder(
                  itemCount: collegeStudentList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Column(children: <Widget>[
                      widget.addInGroup
                              .contains(collegeStudentList[index]['PinCode'])
                          ? //Text('ll')
                          ListTile(
                              leading: GestureDetector(
                                onTap: () {
                                  print(widget.addInGroup);
                                },
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
                                        image: new DecorationImage(
                                          fit: BoxFit.cover,
                                          image: new NetworkImage(
                                            'http://oyeyaaroapi.plmlogix.com/getAvatarImageNow/${collegeStudentList[index]['PinCode']}',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              title: collegeStudentList[index]['Name'] == null
                                  ? Text(
                                      'Name not found',
                                    )
                                  : Text(collegeStudentList[index]['Name']),
                              subtitle: collegeStudentList[index]['Groups'][0]
                                          ['group_name'] ==
                                      null
                                  ? Text(
                                      'College not found',
                                    )
                                  : Text(collegeStudentList[index]['Groups'][0]
                                      ['group_name']),
                            )
                          : SizedBox(
                              height: 0,
                              width: 0,
                            ),
                    ]);
                  },
                ),
              ),
            ])
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
                // Text('$val')
              ],
            )),
      floatingActionButton: !showLoading
          ? new FloatingActionButton(
              backgroundColor: Color(0xffb00bae3),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 35,
              ),
              onPressed: () {
                print(_controllerGroupName.text);
                if (_controllerGroupName.text == "") {
                  Fluttertoast.showToast(msg: 'Add a group name');
                } else
                  createNewGroup
                      .createGroup(_controllerGroupName.text, widget.addInGroup)
                      .then((res) {
                    print('then res $res');
                    if (res) {
                      Fluttertoast.showToast(
                          msg: "Group ${_controllerGroupName.text} Created");
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();

                    } else
                      Fluttertoast.showToast(msg: "something went wrong");
                  });
              },
            )
          : SizedBox(height: 0, width: 0),
    );
  }
}
