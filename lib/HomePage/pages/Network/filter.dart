import 'package:flutter/material.dart';

class FilterPage extends StatefulWidget {
  List<dynamic> data;
  Set<String> resultToFilter = new Set<String>();

  FilterPage({Key key, this.data, this.resultToFilter}) : super(key: key);

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  final formKey = GlobalKey<FormState>();
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  // List userNames = [];
  Set<String> userNames = new Set<String>();
  Set<String> userNameSet = new Set<String>();
  Set<String> resultToFilterSet = new Set<String>();

  @override
  void initState() {
    // super.initState();
    print('filter data: ${widget.data}');
    print('filter resultToFilter: ${widget.resultToFilter}');
    resultToFilterSet = widget.resultToFilter;

    for (int i = 0; i < widget.data.length; i++) {
      userNames.add(widget.data[i]['senderName']);
    }
    // print('---------------${userNames}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filter By Name'),
        actions: <Widget>[
          FlatButton(
            child: Text(
              'Apply',
              style: TextStyle(fontSize: 18.0, color: Colors.white),
            ),
            onPressed: () {
              Navigator.pop(context, userNameSet);
            },
          )
        ],
        backgroundColor: Color(0xffb00bae3),
      ),
      body: ListView.builder(
        itemCount: userNames.length,
        itemBuilder: (context, position) {
          return Column(
            children: <Widget>[
              _buildRow(userNames.elementAt(position)),
              Divider()
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(user) {
    // bool alreadySaved;
    // if (resultToFilterSet.contains(user)) {
    //   setState(() {
    //     alreadySaved = true;
    //   });
    // } else if (this.userNameSet.contains(user)) {
    //   setState(() {
    //     alreadySaved = true;
    //   });
    // }

    // final bool alreadySaved = resultToFilterSet.contains(user) ? true : this.userNameSet.contains(user) ? true : false;
    this.userNameSet =resultToFilterSet ;
    final bool alreadySaved = this.userNameSet.contains(user);

    return ListTile(
      title: Text(user),
      trailing: Icon(
        alreadySaved ? Icons.check_box : Icons.check_box_outline_blank,
        color: alreadySaved ? Colors.blue : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            // if (resultToFilterSet.contains(user)) {
              resultToFilterSet.remove(user);
            // }
            // if (this.userNameSet.contains(user)) {
              userNameSet.remove(user);
            // }
          } else {
            // if (!resultToFilterSet.contains(user)) {
            //   resultToFilterSet.add(user);
            // }
            // if (!this.userNameSet.contains(user)) {
            //   userNameSet.add(user);
            // }


            userNameSet.add(user);
            resultToFilterSet.add(user);
          }
        });
      },
    );
  }
}
