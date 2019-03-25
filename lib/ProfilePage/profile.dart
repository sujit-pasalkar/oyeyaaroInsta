import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/user.dart';
import 'package:image_picker/image_picker.dart';
import 'package:async/async.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../feed/userFeeds.dart';
import '../HomePage/ChatPage/PrivateChatPage/privateChatePage.dart';
import '../feed/image_view.dart';
import 'package:flutter_native_image/flutter_native_image.dart';

class ProfilePage extends StatefulWidget {
  final String userPin;

  ProfilePage({@required this.userPin});

  @override
  ProfilePageState createState() {
    return new ProfilePageState();
  }
}

class ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController _collegeController = TextEditingController();
  TextEditingController _yearController = TextEditingController();
  TextEditingController _streamController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _companyController = TextEditingController();
  TextEditingController _designationController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

  bool _enabled = false;
  bool _joined = false;
  bool _loggedInUser = false;
  bool _loading = false;

  String _imageThen;
  String _imageNow;
  File imageFile;

  TabController _tabController;
  int tabControllerIndex = 0;

  @override
  void initState() {
    if (currentUser.userId == widget.userPin) {
      _loggedInUser = true;
    }
    _imageNow = "";
    _imageThen = "";
    _getUser();
    _tabController = new TabController(initialIndex: 0, length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    print("_handleTabSelection :index: ${_tabController.index}");
    setState(() {
      tabControllerIndex = _tabController.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text("Profile"),
        actions: tabControllerIndex == 0
            ? <Widget>[
                _joined && !_loggedInUser
                    ? IconButton(
                        icon: Icon(Icons.chat),
                        onPressed: _onTapChatUser,
                      )
                    : SizedBox(
                        height: 0.0,
                        width: 0.0,
                      ),
                _loggedInUser
                    ? _enabled
                        ? IconButton(
                            icon: Icon(
                              Icons.save,
                            ),
                            onPressed: () {
                              _saveUser();
                            },
                          )
                        : _menuBuilder()
                    : SizedBox(
                        height: 0.0,
                        width: 0.0,
                      )
              ]
            : <Widget>[],
        bottom: _loggedInUser
            ? _tabs()
            : PreferredSize(
                preferredSize: Size(double.infinity, 225.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Stack(
                        children: <Widget>[
                          GestureDetector(
                            child: Container(
                              height: 225.0,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: //CachedNetworkImageProvider
                                      NetworkImage(
                                    _imageThen,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () => _showImage(_imageThen),
                          ),
                          Positioned(
                            bottom: 0.0,
                            left: 0.0,
                            right: 0.0,
                            child: Container(
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
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
                                "Then",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  decorationStyle: TextDecorationStyle.solid,
                                  decoration: TextDecoration.none,
                                  fontSize: 20.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Stack(
                        children: <Widget>[
                          GestureDetector(
                            child: Container(
                              height: 225.0,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(
                                    _imageNow,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () => _showImage(_imageNow),
                          ),
                          Positioned(
                            bottom: 0.0,
                            left: 0.0,
                            right: 0.0,
                            child: Container(
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
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
                                "Now",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  decorationStyle: TextDecorationStyle.solid,
                                  decoration: TextDecoration.none,
                                  fontSize: 20.0,
                                ),
                              ),
                            ),
                          ),
                          _enabled
                              ? Positioned(
                                  bottom: 0.0,
                                  right: 0.0,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.add_a_photo,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _getImage();
                                    },
                                  ),
                                )
                              : SizedBox(
                                  width: 0.0,
                                  height: 0.0,
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        backgroundColor: Color(0xffb00bae3),
      ),
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: <Widget>[
          Container(
            child: _loggedInUser
                ? TabBarView(
                    controller: this._tabController,
                    children: <Widget>[
                      Form(
                        key: _formKey,
                        child: ListView(
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Expanded(
                                  flex: 1,
                                  child: Stack(
                                    children: <Widget>[
                                      GestureDetector(
                                        child: Container(
                                          height: 225.0,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: NetworkImage(
                                                // 'http://192.168.31.38:4005/getProfileImageNow/12345',
                                                _imageThen,
                                              ),
                                            ),
                                          ),
                                        ),
                                        onTap: () => _showImage(_imageThen),
                                      ),
                                      Positioned(
                                        bottom: 0.0,
                                        left: 0.0,
                                        right: 0.0,
                                        child: Container(
                                          padding: EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
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
                                            "Then",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              decorationStyle:
                                                  TextDecorationStyle.solid,
                                              decoration: TextDecoration.none,
                                              fontSize: 20.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Stack(
                                    children: <Widget>[
                                      GestureDetector(
                                        child: Container(
                                          height: 225.0,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: NetworkImage(
                                                  'http://oyeyaaroapi.plmlogix.com/getProfileImageNow/${widget.userPin}'),
                                            ),
                                          ),
                                        ),
                                        onTap: () => _showImage(_imageNow),
                                      ),
                                      Positioned(
                                        bottom: 0.0,
                                        left: 0.0,
                                        right: 0.0,
                                        child: Container(
                                          padding: EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
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
                                            "Now",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              decorationStyle:
                                                  TextDecorationStyle.solid,
                                              decoration: TextDecoration.none,
                                              fontSize: 20.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      _enabled
                                          ? Positioned(
                                              bottom: 0.0,
                                              right: 0.0,
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.add_a_photo,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () {
                                                  // _getImage();
                                                  bottomSheet();
                                                },
                                              ),
                                            )
                                          : SizedBox(
                                              width: 0.0,
                                              height: 0.0,
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 5.0),
                              child: TextFormField(
                                enabled: false,
                                controller: _nameController,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hasFloatingPlaceholder: true,
                                  labelText: "Name",
                                  labelStyle: TextStyle(
                                    color: Colors.blue[500],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            Container(
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 5.0),
                              child: TextFormField(
                                enabled: false,
                                controller: _collegeController,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hasFloatingPlaceholder: true,
                                  labelText: "College",
                                  labelStyle: TextStyle(
                                    color: Colors.blue[500],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            Container(
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 5.0),
                              child: TextFormField(
                                enabled: false,
                                controller: _yearController,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hasFloatingPlaceholder: true,
                                  labelText: "Year",
                                  labelStyle: TextStyle(
                                    color: Colors.blue[500],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            Container(
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 5.0),
                              child: TextFormField(
                                enabled: false,
                                controller: _streamController,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hasFloatingPlaceholder: true,
                                  labelText: "Stream",
                                  labelStyle: TextStyle(
                                    color: Colors.blue[500],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            Container(
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 5.0),
                              child: TextFormField(
                                enabled: _enabled,
                                controller: _emailController,
                                validator: _validateEmail,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: _enabled ? null : InputBorder.none,
                                  hasFloatingPlaceholder: true,
                                  labelText: "Email",
                                  labelStyle: TextStyle(
                                    color: Colors.blue[500],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            Container(
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 5.0),
                              child: TextFormField(
                                enabled: _enabled,
                                controller: _companyController,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: _enabled ? null : InputBorder.none,
                                  hasFloatingPlaceholder: true,
                                  labelText: "Company",
                                  labelStyle: TextStyle(
                                    color: Colors.blue[500],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            Container(
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 5.0),
                              child: TextFormField(
                                enabled: _enabled,
                                controller: _designationController,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: _enabled ? null : InputBorder.none,
                                  hasFloatingPlaceholder: true,
                                  labelText: "Designation",
                                  labelStyle: TextStyle(
                                    color: Colors.blue[500],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            Container(
                              color: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 5.0),
                              child: TextFormField(
                                enabled: _enabled,
                                controller: _locationController,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: _enabled ? null : InputBorder.none,
                                  hasFloatingPlaceholder: true,
                                  labelText: "Location",
                                  labelStyle: TextStyle(
                                    color: Colors.blue[500],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      UserFeeds(),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      children: <Widget>[
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 5.0),
                          child: TextFormField(
                            enabled: false,
                            controller: _nameController,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hasFloatingPlaceholder: true,
                              labelText: "Name",
                              labelStyle: TextStyle(
                                color: Colors.blue[500],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 5.0),
                          child: TextFormField(
                            enabled: false,
                            controller: _collegeController,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hasFloatingPlaceholder: true,
                              labelText: "College",
                              labelStyle: TextStyle(
                                color: Colors.blue[500],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 5.0),
                          child: TextFormField(
                            enabled: false,
                            controller: _yearController,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hasFloatingPlaceholder: true,
                              labelText: "Year",
                              labelStyle: TextStyle(
                                color: Colors.blue[500],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 5.0),
                          child: TextFormField(
                            enabled: false,
                            controller: _streamController,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hasFloatingPlaceholder: true,
                              labelText: "Stream",
                              labelStyle: TextStyle(
                                color: Colors.blue[500],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 5.0),
                          child: TextFormField(
                            enabled: _enabled,
                            controller: _emailController,
                            validator: _validateEmail,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              border: _enabled ? null : InputBorder.none,
                              hasFloatingPlaceholder: true,
                              labelText: "Email",
                              labelStyle: TextStyle(
                                color: Colors.blue[500],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 5.0),
                          child: TextFormField(
                            enabled: _enabled,
                            controller: _companyController,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              border: _enabled ? null : InputBorder.none,
                              hasFloatingPlaceholder: true,
                              labelText: "Company",
                              labelStyle: TextStyle(
                                color: Colors.blue[500],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 5.0),
                          child: TextFormField(
                            enabled: _enabled,
                            controller: _designationController,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              border: _enabled ? null : InputBorder.none,
                              hasFloatingPlaceholder: true,
                              labelText: "Designation",
                              labelStyle: TextStyle(
                                color: Colors.blue[500],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 5.0),
                          child: TextFormField(
                            enabled: _enabled,
                            controller: _locationController,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              border: _enabled ? null : InputBorder.none,
                              hasFloatingPlaceholder: true,
                              labelText: "Location",
                              labelStyle: TextStyle(
                                color: Colors.blue[500],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          _loading
              ? Container(
                  alignment: Alignment.center,
                  color: Colors.black.withOpacity(0.50),
                  child: CircularProgressIndicator(
                    valueColor:
                        new AlwaysStoppedAnimation<Color>(Color(0xffb00bae3)),
                  ),
                )
              : SizedBox(
                  width: 0.0,
                  height: 0.0,
                ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.white,
      tabs: <Widget>[
        Tab(
          text: 'Profile',
        ),
        Tab(
          text: 'Posts',
        ),
      ],
    );
  }

  String _validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value))
      return 'Enter Valid Email';
    else
      return null;
  }

  Widget _menuBuilder() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.white,
      ),
      tooltip: "Menu",
      onSelected: _onMenuItemSelect,
      itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'Profile',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0),
                child: Row(
                  children: <Widget>[
                    Text("Edit Profile"),
                    Spacer(),
                    Icon(Icons.edit),
                  ],
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: 'Logout',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0),
                child: Row(
                  children: <Widget>[
                    Text("Logout"),
                    Spacer(),
                    Icon(Icons.power_settings_new),
                  ],
                ),
              ),
            ),
          ],
    );
  }

  _onMenuItemSelect(String option) {
    switch (option) {
      case 'Profile':
        setState(() {
          _enabled = true;
        });
        break;
      case 'Logout':
        _logout();
        break;
    }
  }

  _getUser() async {
    try {
      setState(() {
        _loading = true;
      });
      http.Response response = await http.post(
          "http://oyeyaaroapi.plmlogix.com/getProfile",
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"pin": widget.userPin}));

      if (response.statusCode == HttpStatus.ok) {
        var result = jsonDecode(response.body);
        var res = result['data'][0];

        setState(() {
          _joined = res['joined'];

          _collegeController.text = res['College'];
          _yearController.text = res['Year'];
          _streamController.text = res['Stream'];
          _nameController.text = res['Name'];
          _emailController.text = res['Email'];
          _companyController.text = res['Company'];
          _designationController.text = res['Designation'];
          _locationController.text = res['Location'];
          _phoneController.text = res['Mobile'];

          _imageThen =
              "http://oyeyaaroapi.plmlogix.com/profiles" + res['ImageThen'];
          _imageNow =
              "http://oyeyaaroapi.plmlogix.com/profiles" + res['ImageNow'];
        });
      }
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _key.currentState.showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Container(
          child: Text(
            "Something went wrong",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        duration: Duration(seconds: 3),
      ));
    }
  }

  _saveUser() async {
    if (_formKey.currentState.validate()) {
      setState(() {
        _loading = true;
      });
      _formKey.currentState.save();
      try {
        String body = jsonEncode({
          'Year': _yearController.text,
          'Stream': _streamController.text,
          'Name': _nameController.text,
          'PinCode': widget.userPin,
          'Email': _emailController.text,
          'Company': _companyController.text,
          'Designation': _designationController.text,
          'Location': _locationController.text,
          'College': _collegeController.text
        });

        await http.post("http://oyeyaaroapi.plmlogix.com/updateProfile",
            headers: {"Content-Type": "application/json"}, body: body);
        setState(() {
          _loading = false;
          _enabled = false;
        });
        _key.currentState.showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content: Container(
            child: Text(
              "Profile updated successfully",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          duration: Duration(seconds: 3),
        ));
      } catch (e) {
        setState(() {
          _loading = false;
        });
        _key.currentState.showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Container(
            child: Text(
              "Something went wrong",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          duration: Duration(seconds: 3),
        ));
      }
    } else {
      _key.currentState.showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Container(
          child: Text(
            "Invalid information entered",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        duration: Duration(seconds: 3),
      ));
    }
  }

  _getImage() async {
    setState(() {
      _loading = true;
    });
    try {
      File image = await ImagePicker.pickImage(source: ImageSource.gallery);
      int fileSize = await image.length();
      print('original img: $image || size : $fileSize');

      //
      if (image != null) {
        if ((fileSize / 1024) > 500) {
          print('compressing image');
          imageFile = await FlutterNativeImage.compressImage(image.path,
              percentage: 75, quality: 75);
          int fileSize = await imageFile.length();

          print('cpmpress img path: $imageFile ||size :$fileSize');
        } else {
          print('not compressing image');
          imageFile = image;
        }

        _uploadImageFile(imageFile).then((onValue) {
          imageCache.clear();
          setState(() {});
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _key.currentState.showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Container(
          child: Text(
            "Something went wrong",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        duration: Duration(seconds: 3),
      ));
    }
  }

  _getCamera() async {
    setState(() {
      _loading = true;
    });
    try {
      File image = await ImagePicker.pickImage(source: ImageSource.camera);
      int fileSize = await image.length();
      print('original img: $image || size : $fileSize');

      //
      if (image != null) {
        if ((fileSize / 1024) > 500) {
          print('compressing image');
          imageFile = await FlutterNativeImage.compressImage(image.path,
              percentage: 75, quality: 75);
          int fileSize = await imageFile.length();

          print('cpmpress img path: $imageFile ||size :$fileSize');
        } else {
          print('not compressing image');
          imageFile = image;
        }

        _uploadImageFile(imageFile).then((onValue) {
          imageCache.clear();
          setState(() {});
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _key.currentState.showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Container(
          child: Text(
            "Something went wrong",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        duration: Duration(seconds: 3),
      ));
    }
  }


  _uploadImageFile(image) async {
    http.ByteStream stream =
        new http.ByteStream(DelegatingStream.typed(image.openRead()));

    var length = await image.length();

    Uri uri = Uri.parse("http://oyeyaaroapi.plmlogix.com/uploadProfileImage");

    http.MultipartRequest request = new http.MultipartRequest("POST", uri);
    request.headers["pin"] = widget.userPin;
    http.MultipartFile multipartFile =
        new http.MultipartFile('file', stream, length, filename: "Heloo");

    request.files.add(multipartFile);

    http.StreamedResponse response = await request.send();

    response.stream.transform(utf8.decoder).listen((value) {
      setState(() {
        _loading = false;
      });
      _key.currentState.showSnackBar(SnackBar(
        backgroundColor: Colors.green,
        content: Container(
          child: Text(
            "Profile updated successfully",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        duration: Duration(seconds: 3),
      ));
    });
  }

  _onTapChatUser() {
    setState(() {
      _loading = true;
    });

    String bodyPMsg = jsonEncode({
      "senderPin": currentUser.userId,
      "senderName": currentUser.username,
      "senderNumber": currentUser.phone,
      "receiverPin": widget.userPin,
      "receiverName": _nameController.text,
      "receiverNumber": _phoneController.text
    });
    http
        .post("http://oyeyaaroapi.plmlogix.com/startChat",
            headers: {"Content-Type": "application/json"}, body: bodyPMsg)
        .then((response) {
      var res = jsonDecode(response.body)["data"][0];
      var chatId = res["chat_id"];
      print("chatId:" + chatId);
      setState(() {
        _loading = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPrivate(
                chatId: chatId,
                chatType: 'private',
                name: _nameController.text,
                receiverPin: widget.userPin,
                mobile: _phoneController.text,
              ),
        ),
      );
    });
  }

  _showImage(String imageUrl) {
    print(imageUrl);
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return ImageViewer(imageUrl: imageUrl);
        },
      ),
    );
  }

  // _logout() {
  //   FirebaseAuth.instance.signOut().then((action) {
  //     _clearSharedPref();
  //     Navigator.of(context).pushNamedAndRemoveUntil(
  //         '/loginpage', (Route<dynamic> route) => false);
  //   });
  // }

  _clearSharedPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  //confirm logout
  _logout() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: Color(0xffb00bae3),
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 80.0,
                child: Column(
                  children: <Widget>[
                    Text(
                      'Logout',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                    ),
                    Text(
                      'Are you sure to logout from app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              Container(
                height: 50,
                child: Row(
                  children: <Widget>[
                    SimpleDialogOption(
                      onPressed: () {
                        print('pressed cancel');
                        Navigator.pop(context, 0);
                      },
                      child: Row(
                        children: <Widget>[
                          Container(
                            child: Icon(
                              Icons.cancel,
                              color: Color(0xffb00bae3),
                            ),
                            margin: EdgeInsets.only(right: 10.0),
                          ),
                          Text(
                            'CANCEL',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        print('pressed yes');
                        FirebaseAuth.instance.signOut().then((action) {
                          _clearSharedPref();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/loginpage', (Route<dynamic> route) => false);
                        });
                      },
                      child: Row(
                        children: <Widget>[
                          Container(
                            child: Icon(
                              Icons.check_circle,
                              color: Color(0xffb00bae3),
                            ),
                            margin: EdgeInsets.only(right: 10.0),
                          ),
                          Text(
                            'YES',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        });
  }

  bottomSheet() {
    print('calleed shareVideo()');
    showModalBottomSheet(
        context: context,
        builder: (builder) {
          return new Container(
              height: 150.0, child: Column(children: <Widget>[
                Padding(padding: EdgeInsets.all(23),
                child: Text('Profile photo',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      icon:Icon(Icons.photo,size: 50,color:Color(0xffb00bae3)),
                      onPressed: (){
                        _getImage();
                        Navigator.pop(context, 0);
                      },
                    ),
                     IconButton(
                      icon:Icon(Icons.camera,size: 50,color:Color(0xffb00bae3)),
                      onPressed: (){
                        _getCamera();
                        Navigator.pop(context, 0);
                      },
                    )
                ],)
              ]));
        });
  }
}
