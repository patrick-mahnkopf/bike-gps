import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bike GPS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FullMap(),
    );
  }
}

class FullMap extends StatefulWidget {
  const FullMap();

  @override
  State createState() => FullMapState();
}

class FullMapState extends State<FullMap> {
  MapboxMapController mapController;
  LocationData _lastLocation;
  bool _useMapbox = true;
  String _mapboxAccessToken;
  final Map _styleStrings = {};

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

  @override
  Widget build(BuildContext context) {
    return new FutureBuilder(
        future: Future.wait([
          _getMapboxAccessToken(),
          _getVectorStyleString(),
          _getRasterStyleString()
        ]),
        builder: (context, AsyncSnapshot<List> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Text('Loading...');
            default:
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                _mapboxAccessToken = snapshot.data[0];
                _styleStrings['vector'] = snapshot.data[1];
                _styleStrings['raster'] = snapshot.data[2];
                return new MapboxMap(
                  accessToken: _mapboxAccessToken,
                  onMapCreated: _onMapCreated,
                  styleString: _getCurrentStyleString(),
                  myLocationEnabled: true,
                  myLocationRenderMode: MyLocationRenderMode.COMPASS,
                  myLocationTrackingMode:
                      MyLocationTrackingMode.TrackingCompass,
                  initialCameraPosition: const CameraPosition(
                      target: LatLng(52.3825, 9.7177), zoom: 14),
                );
              }
          }
        });
  }

  Future<String> _getMapboxAccessToken() async {
    if (_useMapbox) {
      return rootBundle.loadString('assets/mapbox_access_token.txt');
    } else {
      return "random_string";
    }
  }

  Future<String> _getVectorStyleString() async {
    return rootBundle.loadString('assets/vector_style_string.txt');
  }

  Future<String> _getRasterStyleString() async {
    return rootBundle.loadString('assets/raster_style_string.txt');
  }

  String _getCurrentStyleString() {
    return _styleStrings['vector'];
  }

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }
}
