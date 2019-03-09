import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../ChatPage/playVideo.dart';
import './filter.dart';

class VideosData {
  final String videoUrl;
  final String sendername;
  final String timestamp;
  final String frameUrl;

  VideosData({this.videoUrl, this.sendername, this.timestamp, this.frameUrl});

  factory VideosData.fromJson(Map<String, dynamic> json) {
    return VideosData(
      videoUrl: json['url'] as String,
      sendername: json['senderName'] as String,
      timestamp: json['timestamp'] as String,
      frameUrl: json['frameUrl'] as String,
    );
  }
}

List<VideosData> parseUsers(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<VideosData>((json) => VideosData.fromJson(json)).toList();
}

class VideosPage extends StatefulWidget {
  final ScrollController hideButtonController;

  VideosPage({@required this.hideButtonController});
  @override
  _VideosPageState createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  List<VideosData> data;

  // int _currentIndex = 0;
  var res;
  Set<String> resultFromFilter = new Set<String>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    print('videos*************${this.data}');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !isLoading
          ? FutureBuilder<List<VideosData>>(
              future: fetchVideos(http.Client()),
              builder: (context, snapshot) {
                if (snapshot.hasError) print(snapshot.error);
                return snapshot.hasData
                    ? bodyMd(snapshot.data)
                    : Center(child: CircularProgressIndicator());
              },
            )
          : Center(child: CircularProgressIndicator()),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xffb00bae3),
        child: Icon(
          Icons.filter_list,
          color: Colors.white,
          size: 25.0,
        ),
        onPressed: () {
          onTabTapped();
        },
      ),
    );
  }

  void onTabTapped() async {
    // print('${index}');
    // if (index == 0) {
    print('RES :: ${res}');
    resultFromFilter = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                FilterPage(data: res, resultToFilter: resultFromFilter)));
    print('pop Result : $resultFromFilter');
    setState(() {
      // this.isLoading = true;
    });
    if (resultFromFilter == null) {
      print('pop res is null');
      resultFromFilter = new Set<String>();
    }
  }

  Future<List<VideosData>> fetchVideos(http.Client client) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userPin = (prefs.getString('userPin'));

    final result = await client.post("http://54.200.143.85:4200/getVideos",
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"PinCode": '$userPin'}));

    res = jsonDecode(result.body);
    print('******Videos data.body :$res');

    if (resultFromFilter.length == 0) {
      print('resultFromFilter.type==> : ${resultFromFilter.runtimeType}');
      return compute(parseUsers, jsonEncode(res));
    } else {
      print('resultFromFilter.type== : ${resultFromFilter.runtimeType}');
      var arr = await filterResult(res, resultFromFilter);
      return compute(parseUsers, jsonEncode(arr));
    }
  }

  filterResult(res, resultFromFilter) {
    var newList = [];
    for (var i = 0; i < res.length; i++) {
      if (resultFromFilter.contains(res[i]['senderName'])) {
        newList.add(res[i]);
      }
    }
    return newList;
  }

  Widget bodyMd(snapshot) {
    data = snapshot;
    print('data.....${data}');
    return GridView.count(
      primary: false,
      padding: EdgeInsets.all(10.0),
      crossAxisSpacing: 8.0,
      crossAxisCount: 2,
      controller: widget.hideButtonController,
      children: videosGrid(snapshot),
    );
  }

  List<Widget> videosGrid(videoData) {
    print('${videoData.runtimeType}');
    List<Widget> btnlist = List<Widget>();
    for (var i = 0; i < videoData.length; i++) {
      print('dataList : ${videoData[i].frameUrl}');
      btnlist.add(
        Container(
          margin: EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
              color: Colors.black,
              image: DecorationImage(
                image: NetworkImage(videoData[i].frameUrl),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(10.0)),
          child: GestureDetector(
            onTapUp: (TapUpDetails details) {
              print('imageUrl::${videoData[i].frameUrl}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlayScreen(url: videoData[i].videoUrl, type: 'network'),
                ),
              );
            },
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 0.0,
                  right: 0.0,
                  top: 0.0,
                  bottom: 0.0,
                  child: Icon(
                    Icons.play_circle_filled,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10.0),
                          bottomRight: Radius.circular(10.0),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: <Color>[
                            Colors.black.withOpacity(0.60),
                            Colors.black.withOpacity(0.35),
                          ],
                        ),
                      ),
                      child: Text(
                        videoData[i].sendername,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          decorationStyle: TextDecorationStyle.solid,
                          decoration: TextDecoration.none,
                          fontSize: 14.0,
                        ),
                      )),
                )
              ],
            ),
          ),
        ),
      );
    }
    return btnlist;
  }
}
