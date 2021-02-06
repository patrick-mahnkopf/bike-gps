import 'package:bike_gps/modules/home/home.dart';
import 'package:bike_gps/modules/route_manager/route_manager.dart';
import 'package:bike_gps/modules/route_parser/route_parser.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final RouteManager routeManager = new RouteManager(new GpxParser());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bike GPS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(routeManager: routeManager),
    );
  }
}
