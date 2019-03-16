import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../showImage.dart';
import '../../../feed/image_view.dart';
import './filter.dart';

class ImagesData {
  final String imageUrl;
  final String senderName;
  final String timestamp;
  ImagesData({
    this.imageUrl,
    this.senderName,
    this.timestamp,
  });

  factory ImagesData.fromJson(Map<String, dynamic> json) {
    return ImagesData(
      imageUrl: json['url'] as String,
      senderName: json['senderName'] as String,
      timestamp: json['timestamp'] as String,
    );
  }
}

List<ImagesData> parseUsers(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<ImagesData>((json) => ImagesData.fromJson(json)).toList();
}

class ImagesPage extends StatefulWidget {
  final ScrollController hideButtonController;
  final String dialogId; 

  ImagesPage({@required this.hideButtonController,@required this.dialogId});
  @override
  _ImagesPageState createState() => _ImagesPageState();
}

class _ImagesPageState extends State<ImagesPage> {
  List<ImagesData> data;
  bool showFilter = false;
  bool isLoading = false;
  // int _currentIndex = 0;
  var res;
  Set<String> resultFromFilter = new Set<String>();

  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    fetchImgForFilter();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: !isLoading
          ? FutureBuilder<List<ImagesData>>(
              future: fetchImages(http.Client(),widget.dialogId),
              builder: (context, snapshot) {
                if (snapshot.hasError) print(snapshot.error);
                return snapshot.hasData
                    ? bodyMd(snapshot.data, context)
                    : Center(child: CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(
                        Color(0xffb00bae3))));
              },
            )
          : Center(child: CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(
                        Color(0xffb00bae3)))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xffb00bae3),
        child: Icon(
          Icons.filter_list,
          color: Colors.white,
          size: 25.0,
        ),
        // Text('Filters'),
        onPressed: showFilter ? () {
          onTabTapped() ;
        }:
        null
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
    // }

    // setState(() {
    //   _currentIndex = index;
    // });
  }
  
  fetchImgForFilter()async{
    http.Response response = await http.post("http://54.200.143.85:4200/getImages",
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"dialog_id": '${widget.dialogId}'}));
        res = jsonDecode(response.body);
        print('in fetch photo res for filter: $res');
        setState(() {
         showFilter = true; 
        });
  }

  Future<List<ImagesData>> fetchImages(http.Client client,dialogId) async {
    final result = await client.post("http://54.200.143.85:4200/getImages",
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"dialog_id": '$dialogId'}));

    res = jsonDecode(result.body);
    print('in fetch photo res: $res');
  showFilter = true;
    if (resultFromFilter.length == 0) {
      print('resultFromFilter.type==> : ${resultFromFilter.runtimeType}');
      return compute(parseUsers, jsonEncode(res));
    } else {
      //filter res
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

  Widget bodyMd(snapshot, context) {
    showFilter = true;
    data = snapshot;
    print('data.....$data');
    return
    data.length == 0 ?
    Center(
      child:Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
           Icon(
          Icons.image,
          color: Color(0xffb00bae3),
          size: 95.0,
        ),
          Text('Empty Album',style: TextStyle(color: Color(0xffb00bae3),fontSize: 18),)
        ],
      )
    )
    :
    GridView.count(
      padding: EdgeInsets.all(10.0),
      crossAxisSpacing: 8.0,
      crossAxisCount: 2,
      controller: widget.hideButtonController,
      children: imagesGrid(data, context),
    );
  }

  List<Widget> imagesGrid(imagesData, context) {
    print('----------------------${imagesData.length}');
    List<Widget> btnlist = List<Widget>();
    for (var i = 0; i < imagesData.length; i++) {
      print('dataList : ${imagesData[i].imageUrl}');
      btnlist.add(
        GestureDetector(
          onTap: () {
            print('image url : ${imagesData[i].imageUrl}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => //ShowImage
                ImageViewer(
                      imageUrl: imagesData[i].imageUrl,
                    ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(imagesData[i].imageUrl),
              ),
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: EdgeInsets.only(bottom: 8.0),
            child: Stack(
              children: <Widget>[
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
                        imagesData[i].senderName.toString(),
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
