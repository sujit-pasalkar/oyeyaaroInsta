import 'package:flutter/material.dart';
import '../models/config.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path/path.dart' as path;

class CommonFunctions {
  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();
  static void showSnackbar(BuildContext _context, String _message) {
    final snackBar = SnackBar(
      content: Text(_message),
    );
    Scaffold.of(_context).showSnackBar(snackBar);
  }

  CommonFunctions() {
    createdirectories();
  }

  static void createdirectories() async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    List<String> allDirs = [];
    allDirs.add(Config.musicDownloadFolderPath);
    allDirs.add(Config.audioRecordEdit);
    allDirs.add(Config.audioRecordFolderPath);
    allDirs.add(Config.audioRecordFrames);
    allDirs.add(Config.audioRecordTempPath);

    for (int i = 0; i < allDirs.length; i++) {
      final String dirPath = '${extDir.path}${allDirs[i]}';
      if (!Directory(dirPath).existsSync()) {
        Directory(dirPath).createSync(recursive: true);
      }
    }
  }

  Future<String> mergeAudio(
      String recordedTrackPath, String backgroundTrackPath) async {
    File recordedTrack = new File(recordedTrackPath);
    String basename =
        path.basename(recordedTrack.path).replaceAll('m4a', 'mp3');
    String dir = (await getApplicationDocumentsDirectory()).path;
    String processedfilename = '$dir${Config.audioRecordEdit}/$basename';
    if (backgroundTrackPath.isEmpty) {
      File f = new File(recordedTrackPath);
      f.copySync(processedfilename);
      return processedfilename;
    }
    await _flutterFFmpeg
        .execute(
            "-i $recordedTrackPath -i $backgroundTrackPath -filter_complex amix=inputs=2:duration=shortest:dropout_transition=0 -codec:a libmp3lame -q:a 0 $processedfilename")
        // await _flutterFFmpeg
        //     .execute(
        //         '-y -i $recordedTrackPath -i $backgroundTrackPath -c copy -shortest $processedfilename')
        .then((rc) => print("FFmpeg process exited with rc $rc"));
    return processedfilename;
  }

  Future<String> moveProcessedFile(String processedFilePath) async {
    File f = new File(processedFilePath);
    String dir = (await getExternalStorageDirectory()).path;
    String fname = path.basename(f.path);
    fname = fname.replaceAll('m4a', 'mp3');
    String finaldir = '$dir/OyeYaaro/Audios/';
    String finalfilepath = '$dir/OyeYaaro/Audios/$fname';
    File(finalfilepath);
    if (!Directory(finaldir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
    f.copySync(finalfilepath);
    return finalfilepath;
  }
}
