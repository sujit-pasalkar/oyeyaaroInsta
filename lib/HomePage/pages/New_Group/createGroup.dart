import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../groupInfoTabsPage.dart';
import '../../ChatPage/PrivateChatPage/privateChatePage.dart';
import 'package:share/share.dart';
import '../../../ProfilePage/profile.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreateGroup extends StatefulWidget {
  @override
  CreateGroupState createState() => new CreateGroupState();
}

class CreateGroupState extends State<CreateGroup> {
  final formKey = GlobalKey<FormState>();
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  var downloadedSongPath;

  //service res
  String val = '';
  List<dynamic> year = [];
  List<dynamic> branch = [];

// search related vars
  final globalKey = new GlobalKey<ScaffoldState>();
  TextEditingController _controller = new TextEditingController();
  TextEditingController _controllerCollege = new TextEditingController();

  List<dynamic> collegelist;
  bool typing = false;
  List<dynamic> searchresult = List<dynamic>();
  List<dynamic> searchresultforClg = List<dynamic>();

  List<dynamic> collegeStudentList = List<dynamic>();
  bool showStudentSearch = false;
  bool showSearchGroupDropdown = false;

  List<DropdownMenuItem<String>> _years = [];
  List<DropdownMenuItem<String>> _branches = [];
  double opacity = 1.0;
  bool showLoading = false;
  SharedPreferences prefs;
  String _year = null;
  String _branch = null;
  bool openGrpButton;

  String _check, token, groupName;
  int _count = 0;

  @override
  void initState() {
    this.val = "";
    this.year = [];
    this.branch = [];
    values();
  }

  /* Future<List<StudentData>> */ getStudentList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPin = prefs.getString('userPin');

    http.Response response = await http.post(
        "http://54.200.143.85:4200/studentList",
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"college": '${this.val}', "userPin": userPin}));
    var res = jsonDecode(response.body);
    // print("Student list res:********* ${res['data'].runtimeType}");
    this.collegeStudentList = res['data'];
    // print("collegeStudentList:********* ${this.collegeStudentList}");

    setState(() {
      showLoading = false;
    });
  }

  void values() {
    //now  colleges added manually when multiple colleged added in db use new service
    collegelist = List();
    collegelist.addAll([
      "PEC",
    ]); //"MIT", "Pune", "PICTE", "Pune", "COEP", "Pune", "PEC,punjab"

    for (int i = 0; i < collegelist.length; i++) {
      String data = collegelist[i];
      // if (data.toLowerCase().contains(searchText.toLowerCase())) {
      searchresultforClg.add(data);
      // }
    }
  }

  Future<void> _checkGroup() async {
    if (this._branch == null) {
      Fluttertoast.showToast(
        msg: "Please Select branch",
      );
    } else if (this._year == null) {
      Fluttertoast.showToast(
        msg: "Please Select Year",
      );
    } else if (formKey.currentState.validate()) {
      formKey.currentState.save();
      setState(() {
        showLoading = true;
        _count = 0;
      });

      _check = this.val + " " + _branch + " " + _year;

      var body3 = jsonEncode({
        "clg": "${this.val}",
        "branch": "${_branch}",
        "year": "${_year}",
      });

      http
          .post("http://54.200.143.85:4200/checkGroup",
              headers: {"Content-Type": "application/json"}, body: body3)
          .then((response) {
        var res = jsonDecode(response.body);
        setState(() {
          showLoading = false;
        });

        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GrpInfoTabsHome(
                  peerId: res['data']['dialog_id'],
                  chatType: 'group',
                  groupName: res['data']['name']),
            ));
      });
    }
  }

  void loadData() {
    _years = [];
    _branches = [];

    for (var i = 0; i < this.year.length; i++) {
      _years.add(DropdownMenuItem(
          child: Text(this.year[i].toString()),
          value: this.year[i].toString()));
    }

    for (var i = 0; i < this.branch.length; i++) {
      _branches.add(DropdownMenuItem(
          child: Text(this.branch[i].toString()),
          value: this.branch[i].toString()));
    }
  }

  Widget appBarTitle(String val) {
    return Text(
      val,
      style: new TextStyle(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    loadData();
    return Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomPadding: true,
        appBar: AppBar(
          centerTitle: true,
          title: this.val == ''
              ? appBarTitle('Search College')
              : appBarTitle(this.val),
          backgroundColor: Color(0xffb00bae3),
        ),
        body: !showLoading
            ? Column(
                children: <Widget>[
                  !showStudentSearch
                      ? Container(
                          margin: EdgeInsets.all(22.0),
                          padding: EdgeInsets.fromLTRB(18.0, 0.0, 0.0, 0.0),
                          child: TextField(
                              autofocus: true,
                              controller: _controllerCollege,
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter College Name here..'),
                              onChanged: (input) {
                                searchOperationForCollege(
                                    input); //new search op
                              }),
                          decoration: BoxDecoration(
                              color: Colors.grey[350],
                              borderRadius: BorderRadius.circular(50.0)),
                        )
                      : Container(
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
                              this.typing && showStudentSearch
                                  ? IconButton(
                                      icon: Icon(Icons.close),
                                      tooltip: 'Increase volume by 10%',
                                      onPressed: () {
                                        print('close student list');
                                        setState(() {
                                          this.typing = false;
                                          this.showSearchGroupDropdown = true;
                                          this._controller.text = "";
                                        });
                                      },
                                    )
                                  : Text('')
                            ],
                          ),
                          decoration: BoxDecoration(
                              color: Colors.grey[350],
                              borderRadius: BorderRadius.circular(50.0)),
                        ),

                  Divider(height: 5.0),

                  this.typing && showStudentSearch
                      ? Flexible(
                          child: ListView.builder(
                            itemCount: searchresult.length,
                            itemBuilder: (BuildContext context, int index) {
                              bool isActive = searchresult[index]['joined'];
                              return Column(children: <Widget>[
                                ListTile(
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
                                                color: Colors.grey,
                                                image: new DecorationImage(
                                                  fit: BoxFit.cover,
                                                  image: new NetworkImage(
                                                      searchresult[index]['ImageNow'].contains('default')
                                                          ? "http://54.200.143.85:4200/profiles${searchresult[index]['ImageThen']}"
                                                          : 
                                                          "http://54.200.143.85:4200/profiles${searchresult[index]['ImageNow']}"

                                                      // "http://54.200.143.85:4200/profiles${searchresult[index]['ImageThen']}"
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProfilePage(
                                                          userPin: searchresult[
                                                                  index]
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
                                    trailing: isActive
                                        ? FlatButton(
                                            child: Text(
                                              'Chat',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            splashColor: Colors.green,
                                            color: Color(0xffb00bae3),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        30.0)),
                                            onPressed: () {
                                              chat(
                                                  context,
                                                  searchresult[index]
                                                      ['PinCode'],
                                                  searchresult[index]['Name'],
                                                  searchresult[index]
                                                      ['Mobile']);
                                            })
                                        : FlatButton(
                                            child: Text(
                                              'Invite',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            splashColor: Colors.green,
                                            color: Color(0xffb00bae3),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        30.0)),
                                            onPressed: () {
                                              invite(searchresult[index]
                                                  ['PinCode']);
                                            })),
                                Divider(height: 5.0),
                              ]);
                            },
                          ),
                        )
                      : this.typing || !showStudentSearch
                          ? Flexible(
                              child: ListView.builder(
                                // shrinkWrap: true,
                                itemCount: searchresultforClg.length,
                                itemBuilder: (BuildContext context, int index) {
                                  String listData = searchresultforClg[index];
                                  return Column(
                                    children: <Widget>[
                                      GestureDetector(
                                          child: ListTile(
                                              title: Text(listData.toString())),
                                          onTap: () {
                                            tapOnCollege(listData.toString());
                                          }),
                                      Divider(height: 5.0),
                                    ],
                                  );
                                },
                              ),
                              // ],
                              // )
                            )
                          : Container(),

                  //dropdowns
                  showSearchGroupDropdown
                      ? Flexible(
                          fit: FlexFit.tight,
                          child: ListView(
                            children: <Widget>[
                              Container(
                                padding:
                                    EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                                child: Form(
                                  key: formKey,
                                  autovalidate: true,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      FormField(
                                        builder: (FormFieldState state) {
                                          return InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Branch',
                                            ),
                                            child:
                                                new DropdownButtonHideUnderline(
                                              child: new DropdownButton(
                                                value: _branch,
                                                items: _branches,
                                                hint: new Text('Select branch'),
                                                onChanged: (value) {
                                                  _branch = value;
                                                  setState(() {
                                                    _count = 0;
                                                    _branch = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      new FormField(
                                        builder: (FormFieldState state) {
                                          return InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Year',
                                            ),
                                            child:
                                                new DropdownButtonHideUnderline(
                                              child: new DropdownButton(
                                                value: _year,
                                                items: _years,
                                                hint: new Text('Select year'),
                                                onChanged: (value) {
                                                  _year = value;
                                                  setState(() {
                                                    _count = 0;
                                                    _year = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      new Padding(
                                        padding:
                                            const EdgeInsets.only(top: 60.0),
                                      ),
                                      SizedBox(
                                        width: 210.0, // double.infinity / 2,
                                        height: 50.0,
                                        child: FlatButton(
                                          child: Text(
                                            'Search Group', //'Find Group',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18),
                                          ),

                                          splashColor: Colors.green,
                                          color: Color(0xffb00bae3),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30.0)),
                                          onPressed:
                                              _checkGroup, //openGrpButton? _checkGroup :null,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(),
                  // Text("drop else")
                ],
              )
            : Center(child: CircularProgressIndicator()));
  }

  invite(userPin) {
    Share.share(
        'You are invited to join your classmates @OyeYaaro. Download  this App by www.webworldindia.com/connectyaar/app use PIN #${userPin} to login.See you in the room chat! ');
  }

  Future<void> chat(context, id, name, Mobile) async {
    // print(id);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userpin = prefs.getString('userPin');
    String userName = prefs.getString('userName');
    String userNumber = prefs.getString('userPhone');
    var bodyPMsg = jsonEncode({
      "senderPin": userpin,
      "receiverPin": id,
      "senderName": userName,
      "receiverName": name,
      "senderNumber": userNumber,
      "receiverNumber": Mobile
    });
    http
        .post("http://54.200.143.85:4200/startChat",
            headers: {"Content-Type": "application/json"}, body: bodyPMsg)
        .then((response) {
      var res = jsonDecode(response.body);
      print(res);
      var chatId = res["data"][0]["chat_id"];
      print(chatId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPrivate(
              chatId: chatId,
              chatType: 'private',
              name: name,
              receiverPin: id,
              mobile: Mobile),
        ),
      );
    });
  }

  void searchOperationForCollege(String searchText) {
    print('typing..for college');
    setState(() {
      this.typing = true;
    });
    searchresultforClg.clear();
    for (int i = 0; i < collegelist.length; i++) {
      String data = collegelist[i];
      if (data.toLowerCase().contains(searchText.toLowerCase())) {
        //contains
        searchresultforClg.add(data);
      }
    }
    // print('searchR: ${searchresult}');
  }

  void searchOperation(String searchText) {
    setState(() {
      this.typing = true;
      showSearchGroupDropdown = false;
    });

    searchresult.clear();
    var inviteUsersList = [];
    //now iterate for student list
    for (int i = 0; i < this.collegeStudentList.length; i++) {
      String data = this.collegeStudentList[i]['Name'];
      if (data.toLowerCase().contains(
              searchText.toLowerCase()) // contains(searchText.toLowerCase())
          ) {
        if (this.collegeStudentList[i]['joined']) {
          searchresult.add(this.collegeStudentList[i]);
        } else {
          // inviteUsersList.add(this.collegeStudentList[i]);
          inviteUsersList.add(this.collegeStudentList[i]);
        }
        // searchresult.add(this.collegeStudentList[i]);
      }
    }
    searchresult.addAll(inviteUsersList);
    print('added..');
  }

  tapOnCollege(value) async {
    setState(() {
      this.val = value;
      showLoading = true;
      this.typing = false;
      this._controllerCollege.text = value;
      this.showStudentSearch = true;
      showSearchGroupDropdown = true;
    });
    var body = jsonEncode({
      "College": "${value}",
    });
    http
        .post("http://54.200.143.85:4200/yearAndBatch",
            headers: {"Content-Type": "application/json"}, body: body)
        .then((response) {
      setState(() {
        // showLoading = false;
        // this.openGrpButton = true;
      });
      var res = jsonDecode(response.body);
      // print('res: ${res}');
      // print('PEC Colleges : ${res['data']['Years']}');
      // print('PEC Streams : ${res['data']['Streams']}');
      setState(() {
        this.year = res['data']['Years'];
        this.branch = res['data']['Streams'];
      });

      //studentListView service
      getStudentList();
    });
  }
}