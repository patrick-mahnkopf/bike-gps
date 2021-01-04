import 'package:bike_gps/widgets/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:gpx_parser/gpx_parser.dart';
import 'package:route_parser/route_parser.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final RouteParser routeParser = new GpxParser();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bike GPS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(routeParser: routeParser),
    );
  }
}
