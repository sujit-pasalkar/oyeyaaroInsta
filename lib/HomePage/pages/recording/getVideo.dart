import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:thumbnails/thumbnails.dart';

class GetVideo extends StatefulWidget {
  @override
  _GetVideoState createState() => _GetVideoState();
}

class _GetVideoState extends State<GetVideo> {

  Directory directory;
  Directory thumbailDirectory;
  File videoFile;
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool loading;


   @override
  void initState() {
    super.initState();
    loading = false;
    directory = new Directory('/storage/emulated/0/OyeYaaro/Videos');
  }

  Future<List<String>> listDir() async {
    // print('inlistDir() : ${showShareVideoCheckBox.length}');
    print('1.DIR *** $directory');
    List<String> videos = <String>[];
    var exists = await directory.exists();
    print('2.exist: $exists');

    if (exists) {
      // print('showShareVideoCheckBox::${showShareVideoCheckBox.length}');
      print('videos::${videos.length}');

      directory.listSync(recursive: true, followLinks: true).forEach((f) {
        print("3.PATH*****:" + f.path);
        if (f.path.toString().endsWith('.mp4')) {
          print("***adding : ${f.path}");
          videos.add(f.path);
          // showShareVideoCheckBox.add(false);
        }
      });
      // print('ShowvisL:${showShareVideoCheckBox.length}');
      print('videos:${videos.length}');

      return videos;
    } else {
      videos.add('empty');
      // print('ShowvisL:${showShareVideoCheckBox.length}');
      return videos;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text('send recorded video'),backgroundColor:  Color(0xffb00bae3)),
      body: !loading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: new FutureBuilder<List<String>>(
                    future: listDir(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.hasError)
                        return Text("Error => ${snapshot.error}");
                      return snapshot.hasData
                          ? body(snapshot.data)
                          : Center(
                              child: CircularProgressIndicator(
                              valueColor: new AlwaysStoppedAnimation<Color>(
                                  Color(0xffb00bae3)),
                            ));
                    },
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                  valueColor:
                      new AlwaysStoppedAnimation<Color>(Color(0xffb00bae3)),
                ),
                // SizedBox(height: 10,),
                // Text('Sending..',style: TextStyle(fontSize: 20 ,color:Color(0xffb00bae3)),)
              ],
            )),
    );
  }

  Widget body(dataList) {
    print('dataList  : $dataList');
    if (dataList.length != 0) {
      if (dataList[0] == 'empty') {
        return Center(
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.folder,
                  size: 80.0,
                  color: Color(0xffb00bae3),
                ),
                Text(
                  'Folder Not Found',
                  style: TextStyle(color: Color(0xffb00bae3)),
                ),
              ],
            ),
          ),
        );
      } else {
        return GridView.count(
          primary: false,
          padding: EdgeInsets.all(8.0),
          crossAxisSpacing: 8.0,
          crossAxisCount: 2,
          // controller: widget.hideButtonController,
          children: videoGrid(dataList),
        );
      }
    } else {
      return Center(
          child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.folder,
              size: 80.0,
              color: Color(0xffb00bae3),
            ),
            Text(
              'Folder is Empty',
              style: TextStyle(color: Color(0xffb00bae3)),
            ),
          ],
        ),
      ));
    }
  }

   List<Widget> videoGrid(dataList) {
    List<Widget> btnlist = List<Widget>();
    for (var i = 0; i < dataList.length; i++) {
      print('dataList : ${dataList[i]}');
      btnlist.add(
        GestureDetector(
          // onLongPress: this.showShareVideoCheckBox[i] != true
          //     ? () {
          //         print('adding : $i, ${dataList[i]}');
          //         setState(() {
          //           allVideos = dataList;
          //         });
          //         print('allVideosCount : ${allVideos.length}');
          //         print('datalist : $dataList');
          //         addToSelectedIndexes(dataList[i], i);
          //       }
          //     : () {
          //         print('removing : $i');
          //         this.removeFromSelectedIndexes(dataList[i], i);
          //       },
          onTap:
          //  this.selectedIndexes.length == 0
              // ? 
              () {
                  print('videoName::${dataList[i]}');
                   Navigator.pop(context, dataList[i]);
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => PlayScreen(url: dataList[i]),
                  //   ),
                  // );
                // },
              // : this.showShareVideoCheckBox[i] != true
              //     ? () {
              //         print('adding : $i, ${dataList[i]}');
              //         addToSelectedIndexes(dataList[i], i);
              //       }
              //     : () {
              //         print('removing : $i');
              //         this.removeFromSelectedIndexes(dataList[i], i);
                    },
          child: Container(
            margin: EdgeInsets.only(bottom: 8.0),
            child: GestureDetector(
              child: Stack(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                        border: new Border.all(
                          color: Colors.indigo[50],
                          // width: showShareVideoCheckBox[i] == true ? 10 : 0,
                        ),
                        image: DecorationImage(
                          image: FileImage(
                            File('/storage/emulated/0/OyeYaaro/Thumbnails/' +
                                (dataList[i].toString().split("/").last)
                                    .replaceAll('mp4', 'png')),
                          ),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(10.0)),
                  ),
                  // Positioned(
                  //   left: 0.0,
                  //   right: 0.0,
                  //   top: 0.0,
                  //   bottom: 0.0,
                  //   child: Icon(
                  //     Icons.play_circle_outline,
                  //     size: 60,
                  //     color: Colors.white,
                  //   ),
                  // ),
                  // Positioned(
                  //   right: 0.0,
                  //   top: 0.0,
                  //   child: showShareVideoCheckBox[i] == true
                  //       ? Icon(Icons.check_circle, color: Color(0xffb00bae3))
                  //       : SizedBox(
                  //           height: 0,
                  //           width: 0,
                  //         ),
                  // )
                ],
              ),
            ),
          ),
        ),
      );
    }
    return btnlist;
  }

}