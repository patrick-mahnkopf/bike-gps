import 'dart:io';

import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/widgets/loading_widget.dart';
import 'package:bike_gps/widgets/map_view/map_widget.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tuple/tuple.dart';

class Home extends StatefulWidget {
  final RouteManager routeManager;
  final List<Tuple3<int, Widget, BottomNavigationBarItem>> additionalWidgetList;

  Home(
      {this.routeManager,
      List<Tuple3<int, Widget, BottomNavigationBarItem>> additionalWidgetList})
      : this.additionalWidgetList = additionalWidgetList ?? [];

  @override
  State<StatefulWidget> createState() =>
      _HomeState(routeManager, additionalWidgetList: additionalWidgetList);
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  RouteManager routeManager;
  List<Tuple3<int, Widget, BottomNavigationBarItem>> additionalWidgetList;
  List<Widget> _children;
  List<String> fileDirectories = ['routes'];

  _HomeState(this.routeManager, {this.additionalWidgetList}) {
    _children = [
      MapWidget(routeManager),
      LoadingWidget(),
    ];
    additionalWidgetList.forEach((tuple) {
      _children.insert(tuple.item1, tuple.item2);
    });
    initFileSystem();
  }

  initFileSystem() async {
    String basePath = (await getApplicationDocumentsDirectory()).path;
    for (String directory in fileDirectories) {
      if (!await Directory(p.join(basePath, directory)).exists()) {
        await Directory(p.join(basePath, directory)).create(recursive: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: getBottomNavigationBarItems(),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  getBottomNavigationBarItems() {
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(icon: new Icon(Icons.map), label: 'Map'),
      BottomNavigationBarItem(icon: new Icon(Icons.more_horiz), label: 'More'),
    ];
    for (Tuple3 tuple in additionalWidgetList) {
      items.insert(tuple.item1, tuple.item3);
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _getPermissions();
  }

  void _getPermissions() async {
    final location = Location();
    final hasPermissions = await location.hasPermission();
    if (hasPermissions != PermissionStatus.granted) {
      await location.requestPermission();
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
