import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:io';
import 'package:image/image.dart' as Im;
import 'package:path_provider/path_provider.dart';
import 'dart:math' as Math;
import '../models/user.dart';

class Uploader extends StatefulWidget {
  _Uploader createState() => new _Uploader();
}

class _Uploader extends State<Uploader> {
  File file;
  TextEditingController captionController = new TextEditingController();

  bool uploading = false;

  Privacy privacy = Privacy();

  @override
  initState() {
    privacy.changePrivacy('Public');
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Post Feed"),
      ),
      backgroundColor: Colors.grey.shade400,
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
        onPressed: (file == null || uploading) ? null : postImage,
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            children: <Widget>[
              Container(
                child: file == null
                    ? Container(
                        alignment: Alignment.center,
                        height: 200.0,
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
                          Positioned(
                            bottom: 0.0,
                            right: 0.0,
                            child: Container(
                              color: Colors.black.withOpacity(0.50),
                              child: IconButton(
                                icon: Icon(
                                  privacy.icon,
                                  color: Colors.white,
                                ),
                                tooltip: "Privacy",
                                onPressed: _changePrivacy,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              SizedBox(
                height: 5.0,
              ),
              Container(
                padding: EdgeInsets.all(8.0),
                color: Colors.white,
                child: TextFormField(
                  controller: captionController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: "Write a caption...",
                    border: InputBorder.none,
                  ),
                  enabled: file != null,
                  autovalidate: true,
                  validator: _validateCaption,
                ),
              ),
            ],
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
      ),
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

  void compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    int rand = new Math.Random().nextInt(10000);
    Im.Image image = Im.decodeImage(file.readAsBytesSync());
    Im.copyResize(image, 500);
    var newim2 = new File('$path/img_$rand.jpg')
      ..writeAsBytesSync(Im.encodeJpg(image, quality: 85));
    setState(() {
      file = newim2;
    });
  }

  void postImage() async {
    try {
      setState(() {
        uploading = true;
      });
      compressImage();
      String uploadingTask = await uploadImage(file);
      postToFireStore(
        mediaUrl: uploadingTask,
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

  Future<String> uploadImage(File imageFile) async {
    var uuid = new Uuid().v1();
    StorageReference ref =
        FirebaseStorage.instance.ref().child("post_$uuid.jpg");
    StorageUploadTask uploadTask = ref.putFile(imageFile);

    String downloadUrl =
        await (await uploadTask.onComplete).ref.getDownloadURL();
    return downloadUrl;
  }

  void postToFireStore({String mediaUrl, String description}) async {
    var reference = Firestore.instance.collection('insta_posts');

    reference.add({
      "username": currentUser.username,
      "likes": {},
      "mediaUrl": mediaUrl,
      "description": description,
      "ownerId": currentUser.userId,
      "visibility": privacy.visibleTo,
      "timestamp": new DateTime.now().toString(),
    }).then((DocumentReference doc) {
      String docId = doc.documentID;
      reference.document(docId).updateData({"postId": docId});
    });
  }
}

class Privacy {
  String visibleTo;
  IconData icon;

  Privacy();

  changePrivacy(String visibleTo) {
    switch (visibleTo) {
      case 'Class':
        this.visibleTo = currentUser.groupId;
        this.icon = Icons.group;
        break;
      case 'College':
        this.visibleTo = currentUser.collegeName;
        this.icon = Icons.location_city;
        break;
      case 'Public':
        this.visibleTo = "Public";
        this.icon = Icons.public;
        break;
    }
  }
}