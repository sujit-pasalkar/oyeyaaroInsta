import 'package:shared_preferences/shared_preferences.dart';

final CurrentUser currentUser = CurrentUser();

class CurrentUser {
  String username;
  String userId;
  String photoURL;
  String groupId;
  String collegeName;
  String phone;
  String email;
  String filterActive;

  CurrentUser() {
    //  loadUserDetails();
  }

  loadUserDetails() async {
    try {
    print("in main userLoaded: $userId , ${username} , ${groupId} , ${collegeName} , ${phone} , ${email} , ${filterActive} ,");

      SharedPreferences _prefs = await SharedPreferences.getInstance();
      this.userId = _prefs.getString('userPin');
      
      this.username = _prefs.getString('userName');
      this.photoURL =
          "http://oyeyaaroapi.plmlogix.com/profiles/now/" + this.userId + ".jpg";
      this.groupId = _prefs.getString('groupId');
      this.collegeName = _prefs.getString('collegeName');
      this.phone = _prefs.getString('userPhone');
      this.email = _prefs.getString('email');
      this.filterActive = _prefs.getString('filterActive');
    } catch (e) {
      return;
    }
  }

  changeFilter(String filter) async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    _prefs.setString('filterActive', filter);
    this.filterActive = filter;
    return;
  }

  saveUser(Map<String, dynamic> user) async {
    print('saveUser : $user');
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    if (user['userPin'] != null && user['userPin'] != "")
      _prefs.setString('userPin', user['userPin']);
    if (user['userName'] != null && user['userName'] != "")
      _prefs.setString('userName', user['userName']);
    if (user['email'] != null && user['email'] != "")
      _prefs.setString('email', user['email']);
    if (user['groupId'] != null && user['groupId'] != "")
      _prefs.setString('groupId', user['groupId']);
    if (user['collegeName'] != null && user['collegeName'] != "")
      _prefs.setString('collegeName', user['collegeName']);
    if (user['userPhone'] != null && user['userPhone'] != "")
      _prefs.setString('userPhone', user['userPhone']);
    if (user['hideChatMedia'] != null && user['hideChatMedia'] != "")
      _prefs.setInt('hideChatMedia', user['hideChatMedia']);
    _prefs.setString('filterActive', "All");
    this.photoURL =
        "http://oyeyaaroapi.plmlogix.com/profiles/now/" + this.userId + ".jpg";

    await loadUserDetails();
  }

  clearUser() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    await _prefs.clear();
  }
}
