import 'package:flutter/material.dart';
import '../models/data-service.dart';
import 'feedByTag.dart';

class SearchFeedByTag extends StatefulWidget {
  SearchFeedByTag();

  @override
  _SearchFeedByTag createState() => _SearchFeedByTag();
}

class _SearchFeedByTag extends State<SearchFeedByTag> {
  bool _loading;

  Widget appBarTitle = Text(
    "Search by HashTags",
    style: TextStyle(color: Colors.white),
  );
  Icon actionIcon = Icon(
    Icons.search,
    color: Colors.white,
  );
  final key = GlobalKey<ScaffoldState>();
  final TextEditingController _searchQuery = TextEditingController();
  List<dynamic> _list = List<dynamic>();
  bool _isSearching;
  String _searchText = "";

  _SearchFeedByTag() {
    _searchQuery.addListener(() {
      if (_searchQuery.text.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchText = "";
        });
      } else {
        setState(() {
          _isSearching = true;
          _searchText = _searchQuery.text;
        });
      }
    });
  }

  @override
  void initState() {
    _loading = false;
    _isSearching = false;
    dataService.getAllTags().then((list) {
      if (list.length > 0) {
        setState(() {
          _list = list;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          key: key,
          appBar: buildBar(context),
          body: _buildBody(),
        ),
        _showLoading(),
      ],
    );
  }

  Widget _showLoading() {
    return _loading
        ? Container(
            color: Colors.black.withOpacity(0.50),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : SizedBox(
            height: 0.0,
            width: 0.0,
          );
  }

  Widget _buildBody() {
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      children: _isSearching ? _buildSearchList() : _buildList(),
    );
  }

  _buildList() {
    if (_list != null && _list.length > 0)
      return _list.map((contact) => ChildItem(contact)).toList();
    else
      return [
        ListTile(
          title: Text("Loading...."),
        ),
      ];
  }

  List<ChildItem> _buildSearchList() {
    if (_searchText.isEmpty) {
      return _list.map((contact) => ChildItem(contact)).toList();
    } else {
      List<dynamic> _searchList = List();
      for (int i = 0; i < _list.length; i++) {
        Map<String, dynamic> name = _list.elementAt(i);
        if (name['tag']
            .toLowerCase()
            .contains(_searchText.replaceAll("#", "").toLowerCase())) {
          _searchList.add(name);
        }
      }
      return _searchList.map((contact) => ChildItem(contact)).toList();
    }
  }

  Widget buildBar(BuildContext context) {
    return AppBar(
        centerTitle: false,
        title: appBarTitle,
        backgroundColor: Color(0xffb00bae3),
        actions: <Widget>[
          IconButton(
            icon: actionIcon,
            onPressed: () {
              setState(() {
                if (this.actionIcon.icon == Icons.search) {
                  this.actionIcon = Icon(
                    Icons.close,
                    color: Colors.white,
                  );
                  this.appBarTitle = TextField(
                    controller: _searchQuery,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.white),
                        hintText: "Search...",
                        hintStyle: TextStyle(color: Colors.white)),
                  );
                  _handleSearchStart();
                } else {
                  _handleSearchEnd();
                }
              });
            },
          ),
        ]);
  }

  void _handleSearchStart() {
    setState(() {
      _isSearching = true;
    });
  }

  void _handleSearchEnd() {
    setState(() {
      this.actionIcon = Icon(
        Icons.search,
        color: Colors.white,
      );
      this.appBarTitle = Text(
        "Search by HashTags",
        style: TextStyle(color: Colors.white),
      );
      _isSearching = false;
      _searchQuery.clear();
    });
  }
}

class ChildItem extends StatelessWidget {
  final Map<String, dynamic> tag;
  ChildItem(this.tag);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text("#" + tag['tag']),
      trailing: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          color: Color(0xffb00bae3),
          shape: BoxShape.circle,
        ),
        alignment: Alignment(0.0, 0.0),
        child: Text(
          tag['count'].toString(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      onTap: () => _showResult(context),
    );
  }

  _showResult(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedByTag(tag: tag['tag']),
      ),
    );
  }
}