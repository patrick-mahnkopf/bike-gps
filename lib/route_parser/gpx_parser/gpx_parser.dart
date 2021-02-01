library gpx_parser;

import 'dart:io';

import 'package:bike_gps/route_parser/models/route.dart';
import 'package:bike_gps/route_parser/route_parser.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart' as p;

class GpxParser implements RouteParser {
  List<String> supportedFileExtensions = ['.gpx', '.xml'];
  @override
  Map<String, String> turnArrowAssetPaths = {};

  GpxParser() : super();

  @override
  Future<Route> getRoute(File routeFile) async {
    String fileContent = await routeFile.readAsString();
    String fileBaseName = p.basenameWithoutExtension(routeFile.path);
    return parseRoute(fileContent, fileBaseName, routeFile.path);
  }

  Route parseRoute(String fileContent, String fileBaseName, String filePath) {
    Gpx routeGpx = GpxReader().fromString(fileContent);
    // TODO handle cases where file name and route name in gpx do not contain spaces
    List<Wpt> trackPoints = routeGpx.trks[0].trksegs[0].trkpts;
    List<Wpt> wayPoints = routeGpx.wpts;

    return Route(
      routeName: fileBaseName,
      filePath: filePath,
      trackPoints: trackPoints,
      wayPoints: wayPoints,
      roadBook: _getRoadBook(trackPoints, wayPoints, fileBaseName),
    );
  }

  RoadBook _getRoadBook(
      List<Wpt> trackPoints, List<Wpt> wayPoints, String name) {
    RoadBook roadBook = RoadBook();
    //TODO use combinedPoints or remove it
    // List<Wpt> combinedPoints = _getCombinedPoints(trackPoints, wayPoints);

    for (int i = 0; i < trackPoints.length; i++) {
      Wpt point = trackPoints[i];
      double distanceFromStart;
      if (i == 0) {
        distanceFromStart = 0;
      } else {
        distanceFromStart = roadBook.routePoints[i - 1].distanceFromStart +
            _distanceBetween(trackPoints[i - 1], trackPoints[i]);
      }

      roadBook.routePoints.add(RoutePoint(
        latLng: LatLng(point.lat, point.lon),
        ele: point.ele,
        name: point.name,
        distanceFromStart: distanceFromStart,
      ));
      if (point.name != null && point.name != '') {
        roadBook.wayPoints.add(RoutePoint(
          latLng: LatLng(point.lat, point.lon),
          ele: point.ele,
          name: point.name,
          distanceFromStart: distanceFromStart,
        ));
      }
    }
    if (roadBook.wayPoints.isEmpty && wayPoints.isNotEmpty) {
      for (Wpt wayPoints in wayPoints) {
        roadBook.wayPoints.add(RoutePoint(
          latLng: LatLng(wayPoints.lat, wayPoints.lon),
          ele: wayPoints.ele,
          name: wayPoints.name,
        ));
      }
    }
    return roadBook;
  }

  List<Wpt> _getCombinedPoints(List<Wpt> trackPoints, List<Wpt> wayPoints) {
    List<Wpt> combinedPoints = trackPoints;
    for (int i = 0; i < wayPoints.length; i++) {
      Wpt wayPoint = wayPoints[i];
      double lowestDistance = double.infinity;
      int lowestDistanceIndex = -1;
      for (int j = 0; j < trackPoints.length; j++) {
        Wpt trackPoint = trackPoints[i];
        double distance = _distanceBetween(wayPoint, trackPoint);
        if (distance < lowestDistance) {
          lowestDistance = distance;
          lowestDistanceIndex = j;
        }
      }

      if (lowestDistanceIndex == 0) {
        combinedPoints.insert(lowestDistanceIndex, wayPoint);
      } else if (_distanceBetween(
            wayPoint,
            trackPoints[lowestDistanceIndex - 1],
          ) <
          _distanceBetween(
            wayPoint,
            trackPoints[lowestDistanceIndex + 1],
          )) {
        combinedPoints.insert(lowestDistanceIndex, wayPoint);
      } else {
        combinedPoints.insert(lowestDistanceIndex + 1, wayPoint);
      }
    }
    return combinedPoints;
  }

  double _distanceBetween(Wpt first, Wpt second) => Geolocator.distanceBetween(
        first.lat,
        first.lon,
        second.lat,
        second.lon,
      );

  @override
  getSupportedFileExtensions() {
    return supportedFileExtensions;
  }
}
