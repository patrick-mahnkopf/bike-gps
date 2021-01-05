import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/widgets/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:gpx_parser/gpx_parser.dart';

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
