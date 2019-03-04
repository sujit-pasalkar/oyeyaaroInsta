import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'feedBuilder.dart';
import 'upload_image.dart';
import 'upload_video.dart';
import '../ProfilePage/profile.dart';
import 'searchFeedByTag.dart';

class Feeds extends StatefulWidget {
  final ScrollController hideButtonController;

  Feeds({@required this.hideButtonController, Key key}) : super(key: key);
  @override
  _FeedsState createState() => new _FeedsState();
}

class _FeedsState extends State<Feeds> with SingleTickerProviderStateMixin {
  List<FeedBuilder> feedData;
  List<Map<String, dynamic>> originalData;

  bool showMenu = false;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    this._loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Oye Yaaro"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _onMenuItemSelect('Search'),
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _onMenuItemSelect('Filters'),
          ),
          _menuBuilder(),
        ],
        backgroundColor: Color(0xffb00bae3),
      ),
      backgroundColor: Colors.grey.shade300,
      body: Stack(
        children: <Widget>[
          buildFeedBody(),
          loading ? Center(child: CircularProgressIndicator()) : SizedBox(),
        ],
      ),
    );
  }

  Widget buildFeedBody() {
    return RefreshIndicator(
      onRefresh: refresh,
      child: Stack(
        children: <Widget>[
          buildFeed(),
          Positioned(
            right: 0.0,
            bottom: 0.0,
            child: Container(
              padding: EdgeInsets.only(left: 15.0, top: 5.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomRight,
                  end: Alignment.bottomLeft,
                  colors: [Colors.black38, Colors.black.withOpacity(0)],
                ),
              ),
              child: showMenu
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.image,
                            color: Colors.white,
                          ),
                          iconSize: 35.0,
                          onPressed: () async {
                            setState(() {
                              showMenu = false;
                            });
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UploadImage(),
                              ),
                            );
                            refresh();
                          },
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.video_call,
                            color: Colors.white,
                          ),
                          iconSize: 35.0,
                          onPressed: () async {
                            setState(() {
                              showMenu = false;
                            });
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UploadVideo(),
                              ),
                            );
                            refresh();
                          },
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          iconSize: 35.0,
                          onPressed: () {
                            setState(() {
                              showMenu = false;
                            });
                          },
                        ),
                      ],
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.add_circle,
                        color: Colors.white,
                      ),
                      iconSize: 35.0,
                      onPressed: () {
                        setState(() {
                          showMenu = true;
                        });
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  buildFeed() {
    if (feedData == null || feedData.isEmpty) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Image(
                image: AssetImage("assets/no-activity.png"),
              ),
            ),
            Text(
              "No Feeds Yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30.0,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.75),
              ),
            ),
            SizedBox(height: 10.0),
            Text(
              "Your friend's feeds are visible here\nJoin your college group now",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black.withOpacity(0.50),
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView(
        controller: widget.hideButtonController,
        children: feedData,
      );
    }
  }

  Future<Null> refresh() async {
    await _getFeed(silent: true);
    setState(() {});
  }

  _loadFeed() async {
    setState(() {
      loading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String json = prefs.getString("feed");

    if (json != null) {
      originalData = jsonDecode(json).cast<Map<String, dynamic>>();
      _generateFeed(silent: true);
      _getFeed(silent: true);
    } else {
      _getFeed(silent: false);
    }
    setState(() {
      loading = false;
    });
  }

  _getFeed({@required bool silent}) async {
    if (!silent) {
      setState(() {
        loading = true;
      });
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = currentUser.userId;
    String url = 'http://54.200.143.85:4200/getFeeds?userId=' + userId;
    HttpClient httpClient = new HttpClient();

    try {
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      HttpClientResponse response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        String json = await response.transform(utf8.decoder).join();
        prefs.setString("feed", json);
        originalData = jsonDecode(json).cast<Map<String, dynamic>>();
        _generateFeed(silent: false);
      } else {
        print('Error getting a feed:\nHttp status ${response.statusCode}');
      }
    } catch (exception) {
      print('Failed invoking the getFeed function. Exception: $exception');
    }
    setState(() {
      loading = false;
    });
  }

  _generateFeed({@required bool silent}) async {
    if (!silent) {
      setState(() {
        loading = true;
        feedData = [];
      });
    }
    List<FeedBuilder> listOfPosts = [];

    for (Map<String, dynamic> postData in originalData) {
      if (postData['visibility'] == currentUser.filterActive ||
          currentUser.filterActive == "All") {
        listOfPosts.add(FeedBuilder.fromJSON(postData));
      }
    }

    setState(() {
      feedData = listOfPosts;
      loading = false;
    });
  }

  Future _filterPost() {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(bottom: 10.0),
                child: Text(
                  "See post of...",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FlatButton(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: <Widget>[
                    Text("All Posts"),
                    currentUser.filterActive == "All"
                        ? Text('  (active)')
                        : SizedBox(),
                    Spacer(),
                    Icon(Icons.filter_none),
                  ],
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await currentUser.changeFilter('All');
                  _generateFeed(silent: false);
                },
              ),
              Divider(),
              FlatButton(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: <Widget>[
                    Text("Class"),
                    currentUser.filterActive == currentUser.groupId
                        ? Text('  (active)')
                        : SizedBox(),
                    Spacer(),
                    Icon(Icons.group),
                  ],
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await currentUser.changeFilter(currentUser.groupId);
                  _generateFeed(silent: false);
                },
              ),
              Divider(),
              FlatButton(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: <Widget>[
                    Text("College"),
                    currentUser.filterActive == currentUser.collegeName
                        ? Text('  (active)')
                        : SizedBox(),
                    Spacer(),
                    Icon(Icons.location_city),
                  ],
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await currentUser.changeFilter(currentUser.collegeName);
                  _generateFeed(silent: false);
                },
              ),
              Divider(),
              FlatButton(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: <Widget>[
                    Text("Public"),
                    currentUser.filterActive == 'Public'
                        ? Text('  (active)')
                        : SizedBox(),
                    Spacer(),
                    Icon(Icons.public),
                  ],
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await currentUser.changeFilter('Public');
                  _generateFeed(silent: false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuBuilder() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.white,
      ),
      tooltip: "Menu",
      onSelected: _onMenuItemSelect,
      itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'Profile',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0),
                child: Row(
                  children: <Widget>[
                    Text("Profile"),
                    Spacer(),
                    Icon(Icons.person),
                  ],
                ),
              ),
            ),
          ],
    );
  }

  _onMenuItemSelect(String option) {
    switch (option) {
      case 'Profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
                  userPin: currentUser.userId,
                ),
          ),
        );
        break;
      case 'Filters':
        _filterPost();
        break;
      case 'Search':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchFeedByTag(),
          ),
        );
        break;
    }
  }
}
