import 'package:bike_gps/model/additional_widget.dart';
import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/widget/home_widget.dart';
import 'package:bike_gps_closed_source/bike_gps_closed_source.dart';
import 'package:flutter/material.dart';

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

  List<AdditionalWidget> getRtxWidgets() {
    List<AdditionalWidget> additionalWidgets = [];

    additionalWidgets.add(AdditionalWidget(
      insertionIndex: 1,
      widget: AccountWidget(),
      bottomNavigationBarItemLabel: 'Account',
      bottomNavigationBarItemIcon: Icon(Icons.account_circle),
    ));

    return additionalWidgets;
  }
}
