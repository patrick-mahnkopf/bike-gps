import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/widgets/home_widget.dart';
import 'package:bike_gps_closed_source/bike_gps_closed_source.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final RouteManager routeManager = new RouteManager(new RtxParser());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bike GPS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: buildHomeWidget(),
    );
  }

  Home buildHomeWidget() {
    return Home(
        routeManager: routeManager, additionalWidgetList: getRtxWidgets());
  }

  List<Tuple3<int, Widget, BottomNavigationBarItem>> getRtxWidgets() {
    List<Tuple3<int, Widget, BottomNavigationBarItem>> widgetList = [];
    widgetList.add(Tuple3<int, Widget, BottomNavigationBarItem>(
        1,
        AccountWidget(),
        BottomNavigationBarItem(
            label: 'Account', icon: Icon(Icons.account_circle))));
    return widgetList;
  }
}
