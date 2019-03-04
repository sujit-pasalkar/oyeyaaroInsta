import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './createGroup.dart';

class SearchGroup2 extends StatefulWidget {
  @override
  _SearchGroup2State createState() => _SearchGroup2State();
}

class _SearchGroup2State extends State<SearchGroup2> {
  final globalKey = new GlobalKey<ScaffoldState>();
  TextEditingController _controller = new TextEditingController();
  List<dynamic> collegelist;

  bool typing = false;
  // String _searchText = "";
  List searchresult = List();

  bool showLoading = false;
  SharedPreferences prefs;

  @override
  void initState() {
    // super.initState();
    values();
  }

  void values() {
    //now  colleges added manually when multiple colleged added in db use new service
    collegelist = List();
    collegelist
        .addAll(["PEC"]); //MIT, Pune", "PICTE, Pune", "COEP, Pune", "PEC,punjab
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Search Group',
          style: new TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xffb00bae3),
      ),
      body: !showLoading
          ? ListView(
              children: <Widget>[
                Container(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.fromLTRB(22.0, 42.0, 22.0, 0.0),
                      padding: EdgeInsets.fromLTRB(18.0, 0.0, 0.0, 0.0),
                      child: TextField(
                          autofocus: true,
                          controller: _controller,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Please enter a group name here..'),
                          onChanged: (input) {
                            searchOperation(input);
                          }),
                      decoration: BoxDecoration(
                          color: Colors.grey[350],
                          borderRadius: BorderRadius.circular(50.0)),
                    ),
                  ],
                )),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchresult.length,
                  itemBuilder: (BuildContext context, int index) {
                    String listData = searchresult[index];
                    return GestureDetector(
                        child: ListTile(title: Text(listData.toString())),
                        onTap: () {
                          tapOnCollege(listData.toString());
                        });
                  },
                )
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }

  void searchOperation(String searchText) {
    print('typing..');
    setState(() {
      this.typing = true;
    });

    searchresult.clear();
    // if (_isSearching != null) {
    for (int i = 0; i < collegelist.length; i++) {
      String data = collegelist[i];
      if (data.toLowerCase().contains(searchText.toLowerCase())) {
        searchresult.add(data);
      }
    }
    print('searchR: ${searchresult}');
    // }
  }

  tapOnCollege(value) async {
    setState(() {
      // this.val = value;
      showLoading = true;
      this.typing = false;
      this._controller.text = value;

      // searchresult.clear();
    });
    print("in navigate: ${value}");

    var body = jsonEncode({
      "College": "${value}",
    });
    http
        .post("http://54.200.143.85:4200/yearAndBatch",
            headers: {"Content-Type": "application/json"}, body: body)
        .then((response) {
      setState(() {
        showLoading = false;
        // this.openGrpButton = true;
      });
      var res = jsonDecode(response.body);
      print('res: ${res}');
      print('PEC Colleges : ${res['data']['Years']}');
      print('PEC Streams : ${res['data']['Streams']}');
      // setState(() {
      //   this.year = res['data']['Years'];
      //   this.branch = res['data']['Streams'];
      // });

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => CreateGroup(
      //         val: value,
      //         year: res['data']['Years'],
      //         branch: res['data']['Streams']),
      //   ),
      // );
    });
  }
}
