import 'package:flutter/material.dart';
import 'createGroup.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchGroupList extends StatefulWidget {
  @override
  _SearchListState createState() => new _SearchListState();
}

class _SearchListState extends State<SearchGroupList> {
  Widget appBarTitle = new Text(
    "Search Groups",
    style: new TextStyle(color: Colors.white),
  );

  Icon icon = new Icon(
    Icons.search,
    color: Colors.white,
  );

  final globalKey = new GlobalKey<ScaffoldState>();
  final TextEditingController _controller = new TextEditingController();
  List<dynamic> _list;
  bool _isSearching;
  String _searchText = "";
  List searchresult = new List();
  bool showLoading = false;

  _SearchListState() {
    _controller.addListener(() {
      if (_controller.text.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchText = "";
        });
      } else {
        setState(() {
          _isSearching = true;
          _searchText = _controller.text;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _isSearching = false;
    values();
  }

  navigate(value) async {
    setState(() {
      showLoading = true;
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
      });
      var res = jsonDecode(response.body);
      print('PEC Colleges : ${res['data']['Years:']}');
      print('PEC Streams : ${res['data']['Streams']}');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateGroup(
              // val: value,
              // year: res['data']['Years'],
              // branch: res['data']['Streams']
              ),
        ),
      );
    });
  }

  void values() {
    _list = List();
    _list
        .addAll(["PEC"]); //MIT, Pune", "PICTE, Pune", "COEP, Pune", "PEC,punjab
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: globalKey,
        appBar: buildAppBar(context),
        body: !showLoading
            ? Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchresult.length,
                      itemBuilder: (BuildContext context, int index) {
                        String listData = searchresult[index];
                        return GestureDetector(
                          child: new ListTile(
                              title: new Text(listData.toString())),
                          onTap: () => navigate(listData.toString()),
                        );
                      },
                    )
                  ],
                ),
              )
            : Center(
                child: CircularProgressIndicator(),
              ));
  }

  Widget buildAppBar(BuildContext context) {
    return new AppBar(
      centerTitle: true,
      title: appBarTitle,
      actions: <Widget>[
        new IconButton(
          icon: icon,
          onPressed: () {
            setState(() {
              if (this.icon.icon == Icons.search) {
                this.icon = new Icon(
                  Icons.close,
                  color: Colors.white,
                );
                this.appBarTitle = new TextField(
                  controller: _controller,
                  style: new TextStyle(
                    color: Colors.white,
                  ),
                  decoration: new InputDecoration(
                      prefixIcon: new Icon(Icons.search, color: Colors.white),
                      hintText: "Search...",
                      hintStyle: new TextStyle(color: Colors.white)),
                  onChanged: searchOperation,
                );
                _handleSearchStart();
              } else {
                _handleSearchEnd();
              }
            });
          },
        ),
      ],
      backgroundColor: Color(0xffb00bae3),
    );
  }

  void _handleSearchStart() {
    setState(() {
      _isSearching = true;
    });
  }

  void _handleSearchEnd() {
    setState(() {
      this.icon = new Icon(
        Icons.search,
        color: Colors.white,
      );
      this.appBarTitle = new Text(
        "Search College",
        style: new TextStyle(color: Colors.white),
      );
      _isSearching = false;
      _controller.clear();
    });
  }

  void searchOperation(String searchText) {
    searchresult.clear();
    if (_isSearching != null) {
      for (int i = 0; i < _list.length; i++) {
        String data = _list[i];
        if (data.toLowerCase().contains(searchText.toLowerCase())) {
          searchresult.add(data);
        }
      }
    }
  }
}
