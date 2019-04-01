import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import '../models/user.dart';
import '../models/data-service.dart';
import 'package:flutter_native_image/flutter_native_image.dart';

class UploadImage extends StatefulWidget {
  final String tag;

  UploadImage({@optionalTypeArgs this.tag});

  _UploadImage createState() => _UploadImage();
}

class _UploadImage extends State<UploadImage> {
  File file;
  TextEditingController captionController = TextEditingController();

  bool uploading = false;

  Privacy privacy = Privacy();

  @override
  initState() {
    super.initState();
    privacy.changePrivacy('Public');
    captionController.text = widget.tag;
    _load();
  }

  _load() async {
    await Future.delayed(Duration(milliseconds: 50));
    _selectImage();
  }

  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          appBar: AppBar(
            title: Text("Post Feed"),
            backgroundColor: Color(0xffb00bae3),
          ),
          // backgroundColor: Colors.grey.shade400,
          bottomNavigationBar: FlatButton(
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
            color: Colors.deepPurple,
            disabledColor: Colors.grey,
            child: Text(
              "POST",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: (file == null || uploading) ? null : _postFeed,
          ),
          body: Column(
            children: <Widget>[
              Container(
                color: Colors.white,
                padding: EdgeInsets.only(bottom: 5.0),
                child: ListTile(
                  leading: ClipOval(
                    child: Container(
                    height: 60.0,
                    width: 60.0,
                    child: Image(
                      image: NetworkImage(currentUser.photoURL,),fit: BoxFit.cover,
                    ),
                  ),
                  ),
                  title: Text(
                    currentUser.username,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      InkWell(
                        child: Container(
                          padding: EdgeInsets.only(
                            top: 0.5,
                            bottom: 0.5,
                            left: 10.0,
                            right: 5.0,
                          ),
                          margin: EdgeInsets.only(top: 4.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Row(
                            children: <Widget>[
                              Text(privacy.visibility),
                              SizedBox(
                                width: 2.5,
                              ),
                              Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        onTap: _changePrivacy,
                      ),
                    ],
                  ),
                ),
              ),
              file != null
                  ? Container(
                      padding: EdgeInsets.only(
                          top: 3.0, bottom: 3.0, left: 8.0, right: 8.0),
                      color: Colors.white,
                      child: TextFormField(
                        controller: captionController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: "Write a caption...",
                          hintStyle: TextStyle(
                            color: Colors.grey.shade800,
                          ),
                          border: InputBorder.none,
                        ),
                        enabled: file != null,
                        autovalidate: true,
                        validator: _validateCaption,
                      ),
                    )
                  : SizedBox(
                      height: 0.0,
                      width: 0.0,
                    ),
              Expanded(
                child: file == null
                    ? Container(
                        alignment: Alignment.center,
                        // height: 200.0,
                        color: Colors.white,
                        child: RaisedButton.icon(
                          color: Colors.green,
                          icon: Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                          ),
                          label: Text(
                            "Select Image",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onPressed: _selectImage,
                        ),
                      )
                    : Stack(
                        children: <Widget>[
                          Image.file(
                            file,
                            width: double.infinity,
                            // height: 300.0,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 0.0,
                            right: 0.0,
                            child: Container(
                              color: Colors.black.withOpacity(0.50),
                              child: IconButton(
                                icon: Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white,
                                ),
                                tooltip: "Change Image",
                                onPressed: _selectImage,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        uploading
            ? Container(
                alignment: Alignment.center,
                color: Colors.black.withOpacity(0.50),
                child: CircularProgressIndicator(),
              )
            : SizedBox(
                width: 0.0,
                height: 0.0,
              ),
      ],
    );
  }

  String _validateCaption(String value) {
    if (value.length > 0) {
      return null;
    } else {
      return '';
    }
  }

  Future _selectImage() {
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
                  "Select source...",
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
                    Text("Camera"),
                    Spacer(),
                    Icon(Icons.camera_alt),
                  ],
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  File imageFile =
                      await ImagePicker.pickImage(source: ImageSource.camera);
                  setState(() {
                    file = imageFile;
                  });
                },
              ),
              Divider(),
              FlatButton(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: <Widget>[
                    Text("Gallery"),
                    Spacer(),
                    Icon(Icons.photo_library),
                  ],
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  File imageFile =
                      await ImagePicker.pickImage(source: ImageSource.gallery);
                  setState(() {
                    file = imageFile;
                  });
                },
              ),
              Divider(),
              file != null
                  ? FlatButton(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: <Widget>[
                          Text("Remove"),
                          Spacer(),
                          Icon(Icons.delete_forever),
                        ],
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteImage();
                      },
                    )
                  : FlatButton(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: <Widget>[
                          Text("Cancel"),
                          Spacer(),
                          Icon(Icons.close),
                        ],
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  void _deleteImage() {
    setState(() {
      file = null;
    });
  }

  Future _changePrivacy() {
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
                  "Share with...",
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
                    Text("Class"),
                    Spacer(),
                    Icon(Icons.group),
                  ],
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  privacy.changePrivacy('Class');
                  setState(() {});
                },
              ),
              Divider(),
              FlatButton(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: <Widget>[
                    Text("College"),
                    Spacer(),
                    Icon(Icons.location_city),
                  ],
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  privacy.changePrivacy('College');
                  setState(() {});
                },
              ),
              Divider(),
              FlatButton(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: <Widget>[
                    Text("Public"),
                    Spacer(),
                    Icon(Icons.public),
                  ],
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  privacy.changePrivacy('Public');
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  _postFeed() async {
    try {
      setState(() {
        uploading = true;
      });

      File compressedImage;
      int fileSize = await file.length();
      print("Original file size: " + (fileSize / 1024).toString() + " KB");

      if ((fileSize / 1024) > 500) {
        compressedImage = await FlutterNativeImage.compressImage(file.path,
            percentage: 75, quality: 75);
      } else {
        compressedImage = file;
      }

      fileSize = await compressedImage.length();

      print("Compressed file size: " + (fileSize / 1024).toString() + " KB");

      String uuid = Uuid().v1();

      String mediaUrl =
          await dataService.uploadFileToS3(compressedImage, uuid, ".png");

      print("mediaUrl: " + mediaUrl);

      await saveToFireStore(
        mediaUrl: mediaUrl,
        description: captionController.text,
      );
      setState(() {
        file = null;
        uploading = false;
      });
      Navigator.pop(context);
    } catch (e) {
      print(e);
      setState(() {
        uploading = false;
      });
    }
  }

  Future<bool> saveToFireStore({String mediaUrl, String description}) async {
    var reference = Firestore.instance.collection('insta_posts');

    DocumentReference tagReference =
        Firestore.instance.collection('insta_tags').document("tags");

    http.Response response = await http.get('http://oyeyaaroapi.plmlogix.com/time');
    int timestamp = int.parse(jsonDecode(response.body)['timestamp']);

    List<String> hashtags = List<String>();
    description
        .replaceAll("\\n", " ")
        .split(" ")
        .where((value) {
          value.replaceAll(" ", "");
          return value.startsWith("#");
        })
        .toList()
        .forEach((value) {
          hashtags.add(value.replaceAll("#", "").toLowerCase());
        });

    reference.add({
      "username": currentUser.username,
      "likes": {},
      "mediaUrl": mediaUrl,
      "description": description,
      "ownerId": currentUser.userId,
      "visibility": privacy.visibleTo,
      "timestamp": timestamp,
      "tags": hashtags,
    }).then((DocumentReference doc) {
      String docId = doc.documentID;
      reference.document(docId).updateData({"postId": docId});
    });

    Map<String, bool> tags = Map<String, bool>();
    hashtags.forEach((tag) {
      tags.putIfAbsent(tag, () => true);
    });

    await tagReference.setData(tags, merge: true);
    return true;
  }
}

class Privacy {
  String visibleTo;
  IconData icon;
  String visibility;

  Privacy();

  changePrivacy(String visibleTo) {
    switch (visibleTo) {
      case 'Class':
        this.visibleTo = currentUser.groupId;
        this.icon = Icons.group;
        this.visibility = 'Class';
        break;
      case 'College':
        this.visibleTo = currentUser.collegeName;
        this.icon = Icons.location_city;
        this.visibility = 'College';
        break;
      case 'Public':
        this.visibleTo = "Public";
        this.icon = Icons.public;
        this.visibility = 'Public';
        break;
    }
  }
}
