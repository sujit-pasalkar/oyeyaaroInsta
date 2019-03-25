import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'userFeedBuilder.dart';

class UserFeeds extends StatefulWidget {
  @override
  _UserFeedsState createState() => new _UserFeedsState();
}

class _UserFeedsState extends State<UserFeeds>
    with SingleTickerProviderStateMixin {
  List<UserFeedBuilder> feedData;
  List<Map<String, dynamic>> originalData;

  bool showMenu = false;

  dynamic ref;

  @override
  void initState() {
    super.initState();
    this._loadFeed();
    ref = () async {
      await getFeed();
      setState(() {});
      return;
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: SafeArea(
        child: buildFeedBody(),
      ),
    );
  }

  Widget buildFeedBody() {
    return RefreshIndicator(
      onRefresh: refresh,
      child: buildFeed(),
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
              "Start uploading feeds!!",
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
        children: feedData,
      );
    }
  }

  Future<Null> refresh() async {
    await getFeed();
    setState(() {});
    return;
  }

  _loadFeed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String json = prefs.getString("userFeed");

    if (json != null) {
      List<Map<String, dynamic>> data =
          jsonDecode(json).cast<Map<String, dynamic>>();
      List<UserFeedBuilder> listOfPosts = _generateFeed(data);
      setState(() {
        feedData = listOfPosts;
      });
      getFeed();
    } else {
      getFeed();
    }
  }

  getFeed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = currentUser.userId;
    String url = 'http://oyeyaaroapi.plmlogix.com/getUserFeeds?userId=' + userId;
    HttpClient httpClient = new HttpClient();

    List<UserFeedBuilder> listOfPosts;
    String result;
    try {
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      HttpClientResponse response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        String json = await response.transform(utf8.decoder).join();
        prefs.setString("userFeed", json);
        originalData = jsonDecode(json).cast<Map<String, dynamic>>();
        listOfPosts = _generateFeed(originalData);
      } else {
        result = 'Error getting a feed:\nHttp status ${response.statusCode}';
      }
    } catch (exception) {
      result = 'Failed invoking the getFeed function. Exception: $exception';
    }
    print(result);

    setState(() {
      feedData = listOfPosts;
    });
  }

  List<UserFeedBuilder> _generateFeed(List<Map<String, dynamic>> feedData) {
    List<UserFeedBuilder> listOfPosts = [];

    for (Map<String, dynamic> postData in feedData) {
      postData['refresh'] = ref;
      listOfPosts.add(UserFeedBuilder.fromJSON(postData));
    }

    return listOfPosts;
  }
}
