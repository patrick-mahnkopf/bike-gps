import 'package:bike_gps/route_parser/models/rtxData.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class Route {
  String routeName;
  String filePath;
  List<Wpt> trackPoints;
  List<Wpt> wayPoints;
  RoadBook roadBook;
  TourData tourData;
  TourEvaluation tourEvaluation;

  Route({
    this.routeName,
    this.filePath,
    this.trackPoints,
    this.wayPoints,
    this.roadBook,
    this.tourData,
    this.tourEvaluation,
  });

  LatLng get startPoint => LatLng(trackPoints.first.lat, trackPoints.first.lon);

  LatLng get endPoint => LatLng(trackPoints.last.lat, trackPoints.last.lon);

  List<double> get distancesFromStart {
    List<double> distancesFromStart = [];
    double previousDistance = 0;
    distancesFromStart.add(previousDistance);
    for (int i = 1; i < trackPoints.length; i++) {
      Wpt currentPoint = trackPoints[i];
      Wpt previousPoint = trackPoints[i - 1];
      double distance = Geolocator.distanceBetween(previousPoint.lat,
              previousPoint.lon, currentPoint.lat, currentPoint.lon) +
          previousDistance;
      distancesFromStart.add(distance);
      previousDistance = distance;
    }
    return distancesFromStart;
  }

  int get length {
    double totalLength = 0;
    for (int i = 0; i < trackPoints.length - 1; i++) {
      Wpt currentPoint = trackPoints[i];
      Wpt nextPoint = trackPoints[i + 1];
      totalLength += Geolocator.distanceBetween(
          currentPoint.lat, currentPoint.lon, nextPoint.lat, nextPoint.lon);
    }
    return totalLength.toInt();
  }

  List<LatLng> get trackAsList {
    return trackPoints
        .map((trackPoint) => LatLng(trackPoint.lat, trackPoint.lon))
        .toList();
  }

  List<double> get elevationList {
    return trackPoints.map((trackPoint) => trackPoint.ele).toList();
  }

  double get highestPoint {
    return trackPoints
        .reduce((currentPoint, nextPoint) =>
            currentPoint.ele > nextPoint.ele ? currentPoint : nextPoint)
        .ele;
  }

  double get lowestPoint {
    return trackPoints
        .reduce((currentPoint, nextPoint) =>
            currentPoint.ele < nextPoint.ele ? currentPoint : nextPoint)
        .ele;
  }

  int get ascent {
    return (highestPoint - trackPoints.first.ele).toInt();
  }

  int get descent {
    return (trackPoints.first.ele - lowestPoint).toInt();
  }

  LatLngBounds getBounds() {
    Map<String, double> extrema = {
      'west': trackPoints.first.lon,
      'north': trackPoints.first.lat,
      'east': trackPoints.first.lon,
      'south': trackPoints.first.lat,
    };
    double padding = 0.006;
    double offset = 0.006;

    for (Wpt trackPoint in trackPoints) {
      if (trackPoint.lon < extrema['west']) extrema['west'] = trackPoint.lon;
      if (trackPoint.lon > extrema['east']) extrema['east'] = trackPoint.lon;
      if (trackPoint.lat > extrema['north']) extrema['north'] = trackPoint.lat;
      if (trackPoint.lat < extrema['south']) extrema['south'] = trackPoint.lat;
    }

    return LatLngBounds(
      southwest: LatLng(
          extrema['south'] - padding + offset, extrema['west'] - padding),
      northeast: LatLng(
          extrema['north'] + padding + offset, extrema['east'] + padding),
    );
  }
}

class RoadBook {
  List<RoutePoint> routePoints = [];
  List<RoutePoint> wayPoints = [];

  int get length => routePoints.length;

  List<LatLng> get latLngList =>
      routePoints.map((point) => point.latLng).toList();

  List<double> get eleList => routePoints.map((point) => point.ele).toList();

  List<double> get distanceFromStartList =>
      routePoints.map((point) => point.distanceFromStart).toList();

  List<String> get nameList => routePoints.map((point) => point.name).toList();

  List<String> get locationList =>
      routePoints.map((point) => point.location).toList();

  List<String> get directionList =>
      routePoints.map((point) => point.direction).toList();

  List<String> get surfaceList =>
      routePoints.map((point) => point.surface).toList();

  List<String> get turnSymbolIdList =>
      routePoints.map((point) => point.turnSymbolId).toList();

  LatLng getLatLng(int index) => routePoints[index].latLng;

  double getEle(int index) => routePoints[index].ele;

  double getDistanceFromStart(int index) =>
      routePoints[index].distanceFromStart;

  double getDistanceToPrevious(int index) => index > 0
      ? routePoints[index].distanceFromStart -
          routePoints[index - 1].distanceFromStart
      : null;

  double getDistanceToNext(int index) => index < routePoints.length - 1
      ? routePoints[index + 1].distanceFromStart -
          routePoints[index].distanceFromStart
      : null;

  String getName(int index) => routePoints[index].name;

  String getLocation(int index) => routePoints[index].location;

  String getDirection(int index) => routePoints[index].direction;

  String getSurface(int index) => routePoints[index].surface;

  String getTurnSymbolId(int index) => routePoints[index].turnSymbolId;

// double _getDistanceFromStart(LatLng latLng) => routePoints.isNotEmpty
//     ? _getDistanceBetweenPoints(routePoints.last.latLng, latLng) +
//         routePoints.last.distanceFromStart
//     : 0;
// double _getDistanceBetweenPoints(LatLng first, LatLng second) =>
//     Geolocator.distanceBetween(
//       first.latitude,
//       first.longitude,
//       second.latitude,
//       second.longitude,
//     );

// add({
//   @required LatLng latLng,
//   @required double ele,
//   String name,
//   String location,
//   String direction,
//   String surface,
//   String turnSymbolId,
// }) {
//   RoutePoint routePoint = RoutePoint(
//     latLng: latLng,
//     ele: ele,
//     distanceFromStart: _getDistanceFromStart(latLng),
//     name: name ?? '',
//     location: location ?? '',
//     direction: direction ?? '',
//     surface: surface ?? '',
//     turnSymbolId: turnSymbolId ?? '',
//   );
//   routePoints.add(routePoint);
//   if (name != null) {
//     wayPoints.add(routePoint);
//   }
// }
//
// fromList({
//   @required List<LatLng> latLngList,
//   @required List<double> eleList,
//   List<String> nameList = const [],
//   List<String> locationList = const [],
//   List<String> directionList = const [],
//   List<String> surfaceList = const [],
//   List<String> turnSymbolIdList = const [],
// }) {
//   for (int i = 0; i < nameList.length; i++) {
//     add(
//       latLng: latLngList.length > i ? latLngList[i] : null,
//       ele: eleList.length > i ? eleList[i] : null,
//       name: nameList.length > i ? nameList[i] : '',
//       location: locationList.length > i ? locationList[i] : '',
//       direction: directionList.length > i ? directionList[i] : '',
//       surface: surfaceList.length > i ? surfaceList[i] : '',
//       turnSymbolId: turnSymbolIdList.length > i ? turnSymbolIdList[i] : '',
//     );
//   }
// }
}

class RoutePoint {
  LatLng latLng;
  double ele;
  double distanceFromStart;
  String name;
  String location;
  String direction;
  String surface;
  String turnSymbolId;

  RoutePoint({
    this.latLng,
    this.ele,
    this.distanceFromStart,
    this.name,
    this.location,
    this.direction,
    this.surface,
    this.turnSymbolId,
  });
}
