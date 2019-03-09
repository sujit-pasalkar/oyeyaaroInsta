import 'package:http/http.dart' as http;
import 'user.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:async/async.dart';

final _DataService dataService = _DataService();

class _DataService {
  List<dynamic> allAvailableTags;
  Map<String, String> headers;

  _DataService() {
    allAvailableTags = List<dynamic>();
    headers = Map<String, String>();
  }

  initialize() async {
    headers.addAll({"Content-Type": "application/json"});
    await currentUser.loadUserDetails();
    getAllTags();
  }

  Future<List<dynamic>> getAllTags() async {
    if (allAvailableTags.length > 0) {
      _getAllTags();
      return allAvailableTags;
    } else {
      try {
        await _getAllTags();
      } catch (e) {
        print(e);
        rethrow;
      }
    }
    return allAvailableTags;
  }

  _getAllTags() async {
    try {
      print('in _getAllTags()');
      http.Response response = await http.get(
        "http://54.200.143.85:4200/getTags",
        headers: headers,
      );
      if (response.statusCode == 200) {
        allAvailableTags = jsonDecode(response.body);
      } else {
        throw 'Error getting a tags:\nHttp status ${response.statusCode}';
      }
    } catch (exception) {
      throw 'Failed invoking the getAllTags function. Exception: $exception';
    }
    return;
  }

  Future<String> uploadFileToNode(
      File file, String uuid, String extension) async {
    http.ByteStream stream =
        new http.ByteStream(DelegatingStream.typed(file.openRead()));

    int length = await file.length();

    Uri uri = Uri.parse("http://54.200.143.85:4200/postFeedMedia");

    http.MultipartRequest request = new http.MultipartRequest("POST", uri);
    request.headers["filename"] = "post_$uuid$extension";
    http.MultipartFile multipartFile =
        new http.MultipartFile('file', stream, length, filename: "file");

    request.files.add(multipartFile);

    http.StreamedResponse response = await request.send();

    response.stream.listen((data) {}, onDone: () {
      print("uploaded");
    });

    return "http://54.200.143.85:4200/feeds/post_$uuid$extension";
  }

  Future<String> uploadFileToS3(File file, String uuid, String extension) async {
    MethodChannel _channel = MethodChannel('plmlogix.recordvideo/info');
    Map<String, dynamic> params = <String, dynamic>{
      'filePath': file.path,
      'bucket': "oyeyaaro",
      'identity': "us-east-1:5d1e290b-0111-4187-9350-f7cd3905f24d",
      'filename': uuid == null ? file.path.split("/").last : uuid+extension
    };
    await _channel.invokeMethod('uploadToAmazon', params);
    String uploadedPath =
        "https://s3.amazonaws.com/oyeyaaro/" + (uuid == null ? file.path.split("/").last : uuid+extension);
    print("uploadedPath: " + uploadedPath);
    return uploadedPath;
  }

  Future<File> downloadFileFromS3(String filename) async {
    filename = filename.split("/").last;

    MethodChannel _channel = MethodChannel('plmlogix.recordvideo/info');
    Map<String, dynamic> params = <String, dynamic>{
      'bucket': "oyeyaaro",
      'identity': "us-east-1:5d1e290b-0111-4187-9350-f7cd3905f24d",
      'filename': filename
    };
    String downloadPath =
        await _channel.invokeMethod('downloadFromAmazon', params);
    return File(downloadPath);
  }

 
}