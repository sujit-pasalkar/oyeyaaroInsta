import 'package:flutter/material.dart';
import 'feedBuilder.dart';
import 'dart:convert';
import 'dart:io';
import 'upload_image.dart';
import 'upload_video.dart';

class FeedByTag extends StatefulWidget {
  final String tag;
  FeedByTag({@required this.tag});

  @override
  _FeedByTag createState() => _FeedByTag();
}

class _FeedByTag extends State<FeedByTag> {
  List<FeedBuilder> feedData;
  List<Map<String, dynamic>> originalData;

  bool loading = false;
  bool showMenu = false;

  @override
  void initState() {
    this._loadFeed();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          appBar: AppBar(
            title: Text("#" + widget.tag),
            backgroundColor: Color(0xffb00bae3),
          ),
          backgroundColor: Colors.grey.shade300,
          body: _buildBody(),
        ),
        _showLoading(),
      ],
    );
  }

  Widget _showLoading() {
    return loading
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
                                builder: (context) => UploadImage(
                                      tag: '#'+widget.tag,
                                    ),
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
                                builder: (context) => UploadVideo(
                                      tag: '#'+widget.tag,
                                    ),
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
    await _getFeed(silent: false);
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

    String url = 'http://oyeyaaroapi.plmlogix.com/getFeedsByTag?tag=' + widget.tag;
    HttpClient httpClient = new HttpClient();

    try {
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      HttpClientResponse response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        String json = await response.transform(utf8.decoder).join();
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
      listOfPosts.add(FeedBuilder.fromJSON(postData));
    }

    setState(() {
      feedData = listOfPosts;
      loading = false;
    });
  }
}
