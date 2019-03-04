import 'package:flutter/material.dart';
import '../mdels/config.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path/path.dart' as path;
import 'package:thumbnails/thumbnails.dart';

class CommonFunctions {
  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();
  static void showSnackbar(BuildContext _context, String _message) {
    final snackBar = SnackBar(
      content: Text(_message),
    );
    Scaffold.of(_context).showSnackBar(snackBar);
  }

  static void createdirectories() async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    List<String> allDirs = [];
    print("reached here");
    allDirs.add(Config.musicDownloadFolderPath);
    allDirs.add(Config.videoRecordEdit);
    allDirs.add(Config.videoRecordFolderPath);
    allDirs.add(Config.videoRecordFrames);
    allDirs.add(Config.videoRecordTempPath);

    for (int i = 0; i < allDirs.length; i++) {
      final String dirPath = '${extDir.path}${allDirs[i]}';
      if (!Directory(dirPath).existsSync()) {
        Directory(dirPath).createSync(recursive: true);
        print(dirPath);
      }
    }
  }

  Future<String> mergeAudio(String videoFilename, String audioFilename) async {
    File a = new File(videoFilename);
    String basename = path.basename(a.path);
    String dir = (await getApplicationDocumentsDirectory()).path;
    String processedfilename = '$dir${Config.videoRecordEdit}/$basename';
    print('$processedfilename--Hi');
    if (audioFilename == null || audioFilename == '') {
      print('copied without mergeing');
      File f = new File(videoFilename);
      f.copySync(processedfilename);
      return processedfilename;
    }
    await _flutterFFmpeg
        .execute(
            '-y -i $videoFilename -i $audioFilename -c copy -shortest $processedfilename')
        .then((rc) => print("FFmpeg process exited with rc $rc"));
    return processedfilename;
  } //-qscale 0

  Future<String> moveProcessedFile(String videoFilename) async {
    File f = new File(videoFilename);
    String dir = (await getExternalStorageDirectory()).path;
    String fname = path.basename(f.path);
    String fnamewoext = path.basenameWithoutExtension(f.path);
    String finaldir = '$dir/OyeYaaro/Videos/';
    String finalfilepath = '$dir/OyeYaaro/Videos/$fname';
    File ss = new File(finalfilepath);
    if (!Directory(finaldir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
    f.copySync(finalfilepath);
    await createThimbnail(finalfilepath, fnamewoext);
    return finalfilepath;
  }

  Future<String> createThimbnail(String videoFile, String filename) async {
    String dir = (await getExternalStorageDirectory()).path;
    String thumbs = '$dir/OyeYaaro/Thumbnails/';
    String finalfilepath = '$thumbs$filename.png';

    print('reached create Thumbnails $finalfilepath');
    if (!Directory(thumbs).existsSync()) {
      Directory(thumbs).createSync(recursive: true);
    }
    /* _flutterFFmpeg
        .execute('-y -i $videoFile -ss 00:00:2 -vframes 1  $finalfilepath')
        .then((rc) => print("FFmpeg process exited with rc $rc")); */

    String thumb = await Thumbnails.getThumbnail(
        thumbnailFolder:
            thumbs, // creates the specified path if it doesnt exist
        videoFile: videoFile,
        imageType: ThumbFormat.PNG,
        quality: 30);

    return finalfilepath;
  }
}
