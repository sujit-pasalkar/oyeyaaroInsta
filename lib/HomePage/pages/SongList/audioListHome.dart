import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart'; //

class AudioList extends StatefulWidget {
  final ScrollController hideButtonController;

  AudioList({@required this.hideButtonController, Key key}) : super(key: key);

  @override
  _AudioListState createState() => _AudioListState();
}

enum PlayerState { stopped, playing, paused }

class _AudioListState extends State<AudioList> {
  Directory directory;

  TextEditingController _controller = new TextEditingController();
  List<dynamic> searchresult = List<dynamic>();
  List<dynamic> songList = List<dynamic>();
  bool typing = false;
  bool loading = true; //initially true as service not called
  String loadingMsg = "Loading Songs..";
  String sendUrl = '';
  bool playAll = false;
  List checkedSongs = [];
  bool searchSong = false;
  bool onLongpressed = false;
  bool shuffleSongs = false;
  int playListIndex = -1;
  String playingSongName = "";
  bool isSearching = false;

  AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration;
  Duration _position;
  String applicationDir;

  bool isPlaying = false;

  int curr_id = -1;

  @override
  void initState() {
    print('in initState Audiolist home');
    super.initState();
    AudioPlayer.logEnabled = true;
    _initAudioPlayer();
    getSongs();
  }

  @override
  void dispose() {
    super.dispose();
    print('in dispose Audiolist  home');
    _audioPlayer.stop();
  }

  void _initAudioPlayer() {
    _audioPlayer = new AudioPlayer();

    _audioPlayer.durationHandler = (d) => setState(() {
          _duration = d;
        });

    _audioPlayer.positionHandler = (p) => setState(() {
          _position = p;
        });

    _audioPlayer.completionHandler = () {
      onComplete();
      setState(() {
        _position = _duration;
      });
    };

    _audioPlayer.errorHandler = (msg) {
      print('->audioPlayer error : $msg');
      setState(() {
        _playerState = PlayerState.stopped;
        playingSongName = '';
        _duration = Duration(seconds: 0);
        _position = Duration(seconds: 0);
      });
    };
  }

  void onComplete() {
    setState(() {
      _playerState = PlayerState.stopped;
      playingSongName = '';
      isPlaying = false;
    });
    if (playAll) {
      if (checkedSongs.length > 0) {
        if (shuffleSongs) {
          print('$checkedSongs');
          var shuffledSong = (checkedSongs..shuffle()).first;
          print('suffled songs : $shuffledSong');
          _play('http://54.200.143.85:4200/Audio/' + shuffledSong,
              searchresult.indexOf(shuffledSong), shuffledSong);
        } else
          playNextChecked();
      } else {
        if (shuffleSongs) {
          var shuffledSong = (searchresult..shuffle()).first;
          print('suffled songs : $shuffledSong');
          _play('http://54.200.143.85:4200/Audio/' + shuffledSong,
              searchresult.indexOf(shuffledSong), shuffledSong);
        } else
          playNext();
      }
    } else {
      // setState(() {
      // playAll = false;
      // });
    }
  }

  Widget appBarTitle = Text(
    "Search by Song name",
    style: TextStyle(color: Colors.white),
  );

  @override
  Widget build(BuildContext context) {
    // double width = MediaQuery.of(context).size.width;
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
          title: !isSearching
              ? Text('Search By Song Name')
              : TextField(
                  autofocus: false,
                  controller: _controller,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search by Song name...'),
                  cursorColor: Colors.white,
                  onChanged: (input) {
                    searchOperation(input);
                  }),
          backgroundColor: Color(0xffb00bae3),
          actions: <Widget>[
            this.typing
                ? IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        this.typing = false;
                        this._controller.text = "";
                        print('songs : ${this.songList.length}');
                        this.searchresult = this.songList;
                      });
                    },
                  )
                : SizedBox(
                    height: 0,
                    width: 0,
                  ),
            !isSearching
                ? IconButton(
                    icon: Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        isSearching = true;
                      });
                    })
                : SizedBox(height: 0, width: 0),
            onLongpressed
                ? IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      Fluttertoast.showToast(
                        msg: "Songs added in List",
                      );
                      setState(() {
                        onLongpressed = !onLongpressed;
                      });
                    },
                  )
                : SizedBox(
                    height: 0,
                    width: 0,
                  )
          ],
        ),
        body: Stack(
          children: <Widget>[
            Column(children: <Widget>[
              !loading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        FlatButton.icon(
                          icon: !playAll
                              ? Icon(
                                  Icons.repeat,
                                  color: Colors.grey,
                                )
                              : Icon(
                                  Icons.pause_circle_outline,
                                  color: Color(0xffb00bae3),
                                ),
                          label: !playAll
                              ? Text('Play All',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16.0))
                              : Text('Stop',
                                  style: TextStyle(
                                      color: Color(0xffb00bae3),
                                      fontSize: 16.0)),
                          onPressed: () {
                            setState(() {
                              playAll = !playAll;
                            });
                            if (playAll) {
                              if (checkedSongs.length > 0) {
                                if (shuffleSongs) {
                                  print('$checkedSongs');
                                  var shuffledSong =
                                      (checkedSongs..shuffle()).first;
                                  print(
                                      'suffled songs : $shuffledSong and index : ${searchresult.indexOf(shuffledSong)}');
                                  _play(
                                      'http://54.200.143.85:4200/Audio/' +
                                          shuffledSong,
                                      searchresult.indexOf(shuffledSong),
                                      shuffledSong);
                                } else
                                  print('else playList withou shuffle');
                                // playNextChecked();
                                setState(() {
                                  playListIndex = 0;
                                  // = playListIndex + 1;
                                  curr_id = searchresult.indexOf(
                                      this.checkedSongs[playListIndex]); //0
                                });
                                _play(
                                    'http://54.200.143.85:4200/Audio/' +
                                        checkedSongs[playListIndex].toString(),
                                    curr_id,
                                    checkedSongs[playListIndex]);
                              } else
                                // playNext();
                                print('else playAll');
                              if (shuffleSongs) {
                                var shuffledSong =
                                    (searchresult..shuffle()).first;
                                print('suffled songs : $shuffledSong');
                                _play(
                                    'http://54.200.143.85:4200/Audio/' +
                                        shuffledSong,
                                    searchresult.indexOf(shuffledSong),
                                    shuffledSong);
                              } else
                                _play(
                                    'http://54.200.143.85:4200/Audio/' +
                                        searchresult[0],
                                    0,
                                    searchresult[0]);
                            } else {
                              _stop();
                            }
                          },
                        ),
                        FlatButton.icon(
                            icon: Icon(
                              Icons.shuffle,
                              color: !shuffleSongs
                                  ? Colors.grey
                                  : Color(0xffb00bae3),
                            ),
                            label: !shuffleSongs
                                ? Text('Shuffle',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16.0))
                                : Text('Shuffle',
                                    style: TextStyle(
                                        color: Color(0xffb00bae3),
                                        fontSize: 16.0)),
                            onPressed: () {
                              setState(() {
                                shuffleSongs = !shuffleSongs;
                              });
                            })
                      ],
                    )
                  : SizedBox(
                      width: 0,
                      height: 0,
                    ),
              Divider(height: 5.0),
              Flexible(
                child: this.loading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CircularProgressIndicator(
                              valueColor: new AlwaysStoppedAnimation<Color>(
                                  Color(0xffb00bae3)),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 20),
                            ),
                            Text(this.loadingMsg)
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: widget.hideButtonController,
                        itemCount: searchresult.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Column(
                            children: <Widget>[
                              GestureDetector(
                                onLongPress: () {
                                  print('long pressed..');
                                  setState(() {
                                    onLongpressed = true;
                                  });
                                  print('$checkedSongs');
                                },
                                onTap: () {
                                  print('on tapped');
                                  if (onLongpressed) {
                                    if (checkedSongs
                                        .contains(searchresult[index])) {
                                      setState(() {
                                        checkedSongs
                                            .remove(searchresult[index]);
                                      });
                                    } else {
                                      setState(() {
                                        checkedSongs.add(searchresult[index]);
                                      });
                                    }
                                  } else {
                                    print('play song');
                                  }
                                },
                                child: Stack(
                                  children: <Widget>[
                                    ListTile(
                                      leading: isPlaying &&
                                              searchresult[index] ==
                                                  playingSongName
                                          ? _position != null &&
                                                  _duration != null
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons.pause_circle_outline,
                                                    color: Color(0xffb00bae3),
                                                  ),
                                                  iconSize: 45.0,
                                                  color: Colors.black,
                                                  onPressed: () {
                                                    _stop(); //url snapshot.data[index].toString()
                                                  },
                                                )
                                              : CircularProgressIndicator(
                                                  valueColor:
                                                      new AlwaysStoppedAnimation<
                                                              Color>(
                                                          Color(0xffb00bae3)),
                                                )
                                          : IconButton(
                                              icon: Icon(
                                                Icons.play_circle_outline,
                                              ),
                                              iconSize: 45.0,
                                              color: Colors.black,
                                              onPressed: () {
                                                if (_position == null &&
                                                    _duration == null) {
                                                  _stop().then((res) {
                                                    _play(
                                                        'http://54.200.143.85:4200/Audio/' +
                                                            searchresult[index],
                                                        // .toString(),
                                                        index,
                                                        searchresult[index]);
                                                  });
                                                } else {
                                                  _play(
                                                      'http://54.200.143.85:4200/Audio/' +
                                                          searchresult[index],
                                                      // .toString(),
                                                      index,
                                                      searchresult[index]);
                                                }
                                              },
                                            ),
                                      title: Text(
                                        searchresult[index]
                                            .toString()
                                            .replaceAll('.mp3', ''),
                                        style: TextStyle(fontSize: 18.0),
                                      ),
                                      trailing: onLongpressed
                                          ? checkedSongs
                                                  .contains(searchresult[index])
                                              ? Icon(
                                                  Icons.check_circle,
                                                  color: Color(0xffb00bae3),
                                                )
                                              : Icon(
                                                  Icons.radio_button_unchecked,
                                                  color: Color(0xffb00bae3),
                                                )
                                          : SizedBox(
                                              height: 0,
                                              width: 0,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider()
                            ],
                          );
                        }),
              ),
            ])
          ],
        ));
  }

  getSongs() async {
    var response = await http.post(
      "http://54.200.143.85:4200/getAudioList",
      headers: {"Content-Type": "application/json"},
    );
    var res = jsonDecode(response.body);
    print('Song res: $res');
    setState(() {
      this.songList = res;
      this.searchresult = this.songList;
      this.loading = false;
      this.loadingMsg = "";
    });
  }

  // Future<int>
  _play(url, idx, songnm) async {
    print("play url----------------------: ${url} && index : ${idx}");
    final playPosition = (_position != null &&
            _duration != null &&
            _position.inMilliseconds > 0 &&
            _position.inMilliseconds < _duration.inMilliseconds)
        ? _position
        : null;
    print('playPosition : ${playPosition}');

    setState(() {
      _position = null;
      _duration = null;
    });

    final result = await _audioPlayer.play(url);
    print('result: ${result}');
    if (result == 1) {
      setState(() {
        isPlaying = true;
        _playerState = PlayerState.playing;
        curr_id = idx;
        playingSongName = songnm; // searchresult[curr_id];
      });
    } else {
      print('play failed .. result : ${result}');
    }
  }

  Future<int> _stop() async {
    print("stop url----- ");

    final result = await _audioPlayer.stop();
    if (result == 1) {
      setState(() {
        playAll = false;
        isPlaying = false;
        _playerState = PlayerState.stopped;
        _position = new Duration();
        playingSongName = '';
      });
    }
    return result;
  }

  // song search
  void searchOperation(String searchText) {
    this.searchresult = [];

    //now iterate for song list
    for (int i = 0; i < this.songList.length; i++) {
      String data = this.songList[i];
      if (data.toLowerCase().contains(searchText.toLowerCase())) {
        searchresult.add(this.songList[i]);
      }
    }
    setState(() {
      this.typing = true;
    });
  }

  //play next song
  playNext() {
    print('current index : ${this.curr_id}');
    print('searchresult len : ${this.searchresult.length}');
    if (curr_id + 1 < searchresult.length && curr_id + 1 >= 0) {
      print('song name : ${this.searchresult[curr_id + 1]}');
      setState(() {
        curr_id = curr_id + 1;
        playingSongName = searchresult[curr_id];
      });
      _play(
          'http://54.200.143.85:4200/Audio/' +
              searchresult[curr_id], //.toString(),
          curr_id,
          searchresult[curr_id]);
    } else {
      setState(() {
        curr_id = 0;
        playingSongName = searchresult[curr_id];
      });
      print('else song name 1: ${this.searchresult[curr_id]}');
      _play(
          'http://54.200.143.85:4200/Audio/' +
              searchresult[curr_id], //.toString(),
          curr_id,
          searchresult[curr_id]);
    }
  }

  playNextChecked() {
    print('current index : ${this.curr_id}');
    print('checkedSongs len : ${this.checkedSongs.length}');

    if (playListIndex + 1 < checkedSongs.length && playListIndex + 1 >= 0) {
      print('song name : ${this.checkedSongs[playListIndex + 1]}');
      setState(() {
        curr_id = searchresult.indexOf(this.checkedSongs[playListIndex + 1]);
        playListIndex = playListIndex + 1;
        playingSongName = searchresult[curr_id];
        // curr_id + 1;
      });
      _play(
          'http://54.200.143.85:4200/Audio/' +
              checkedSongs[playListIndex], //.toString(),
          curr_id,
          checkedSongs[playListIndex]);
    } else {
      setState(() {
        playListIndex = 0;
        curr_id = searchresult.indexOf(this.checkedSongs[playListIndex]);
        playingSongName = searchresult[curr_id];
      });
      print('else song name 1: ${this.checkedSongs[playListIndex]}');
      _play(
          'http://54.200.143.85:4200/Audio/' +
              checkedSongs[playListIndex], //.toString(),
          curr_id,
          checkedSongs[playListIndex]);
    }
  }

  // List shuffle(List items) {
  //   var random = new Random();
  //   // Go through all elements.
  //   for (var i = items.length - 1; i > 0; i--) {
  //     // Pick a pseudorandom number according to the list length
  //     var n = random.nextInt(i + 1);
  //     var temp = items[i];
  //     items[i] = items[n];
  //     items[n] = temp;
  //   }
  //   return items;
  // }
}
