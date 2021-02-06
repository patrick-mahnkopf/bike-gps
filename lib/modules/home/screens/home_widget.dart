import 'dart:io';

import 'package:bike_gps/modules/home/home.dart';
import 'package:bike_gps/modules/map/map.dart';
import 'package:bike_gps/modules/route_manager/route_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  final RouteManager routeManager;
  final List<AdditionalWidget> additionalWidgetList;

  Home({this.routeManager, List<AdditionalWidget> additionalWidgetList})
      : this.additionalWidgetList = additionalWidgetList ?? [];

  @override
  State<StatefulWidget> createState() =>
      _HomeState(routeManager, additionalWidgetList: additionalWidgetList);
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  List<Widget> _children;
  MapResources mapResources;
  final List<String> _fileDirectories = ['routes'];
  final RouteManager routeManager;
  final List<AdditionalWidget> additionalWidgetList;

  _HomeState(this.routeManager, {this.additionalWidgetList}) {
    initFileSystem();
    _getPermissions();
  }

  initFileSystem() async {
    String basePath = (await getApplicationDocumentsDirectory()).path;
    for (String directory in _fileDirectories) {
      if (!await Directory(p.join(basePath, directory)).exists()) {
        await Directory(p.join(basePath, directory)).create(recursive: true);
      }
    }
  }

  void _getPermissions() async {
    final location = Location();
    final hasPermissions = await location.hasPermission();
    if (hasPermissions != PermissionStatus.granted) {
      await location.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: MapResources().getMapResources(),
      builder: (context, AsyncSnapshot<MapResources> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Theme.of(context).platform == TargetPlatform.android
                ? CircularProgressIndicator()
                : CupertinoActivityIndicator();
          default:
            if (snapshot.hasError) {
              return ErrorWidget(snapshot.error);
            } else {
              mapResources = snapshot.data;
              initChildWidgets(mapResources);
              return Scaffold(
                resizeToAvoidBottomInset: false,
                body: _children[_currentIndex],
                bottomNavigationBar: BottomNavigationBar(
                  onTap: onTabTapped,
                  currentIndex: _currentIndex,
                  items: getBottomNavigationBarItems(),
                  type: BottomNavigationBarType.fixed,
                ),
              );
            }
        }
      },
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void initChildWidgets(MapResources mapResources) {
    _children = [
      MapWidget(
        routeManager: routeManager,
        mapResources: mapResources,
      ),
    ];
    additionalWidgetList.forEach(
      (additionalWidget) {
        _children.insert(
          additionalWidget.insertionIndex,
          additionalWidget.widget,
        );
      },
    );
  }

  List<BottomNavigationBarItem> getBottomNavigationBarItems() {
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: new Icon(Icons.map),
        label: 'Map',
      ),
      BottomNavigationBarItem(
        icon: new Icon(Icons.more_horiz),
        label: 'More',
      ),
    ];
    additionalWidgetList.forEach(
      (additionalWidget) {
        items.insert(
          additionalWidget.insertionIndex,
          additionalWidget.bottomNavigationBarItem,
        );
      },
    );
    return items;
  }
}
