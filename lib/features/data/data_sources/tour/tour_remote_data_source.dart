import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/data/data_sources/tour_parser/tour_parser.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../../core/error/exception.dart';
import '../../models/tour/models.dart';

abstract class TourRemoteDataSource {
  Future<TourModel> getPathToTour(
      {@required LatLng userLocation, @required LatLng tourStart});
  Future<Tour> getEnhancedTour({@required Tour tour});
}

@Injectable(as: TourRemoteDataSource)
class TourRemoteDataSourceImpl implements TourRemoteDataSource {
  final Client client;
  final TourParser tourParser;
  final ConstantsHelper constantsHelper;
  final TourListHelper tourListHelper;

  TourRemoteDataSourceImpl(
      {@required this.tourParser,
      @required this.client,
      @required this.constantsHelper,
      @required this.tourListHelper});

  /// Calls the route service endpoint found in 'assets/token/route_service_url.txt'.
  ///
  /// Throws a [ServerException] for all error codes.
  @override
  Future<TourModel> getPathToTour(
      {@required LatLng userLocation,
      @required LatLng tourStart,
      List<LatLng> trackPointCoordinates = const [],
      String tourName = 'ORS'}) async {
    try {
      if (await _checkRouteServiceReady()) {
        final String tourFileContent =
            await _getTourFileContentFromRouteService(
                userLocation: userLocation,
                tourStart: tourStart,
                trackPointCoordinates: trackPointCoordinates);
        return tourParser.getTourFromFileContent(
            tourFileContent: tourFileContent,
            tourName: tourName,
            tourType: TourType.route);
      } else {
        // TODO Show user routing server not available message
        throw ServerException();
      }
    } on ServerException {
      rethrow;
    }
  }

  Future<bool> _checkRouteServiceReady() async {
    try {
      final String statusUrl = await rootBundle
          .loadString('assets/tokens/route_service_status_url.txt');
      final Response response = await client.get(
        statusUrl,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept':
              '	text/html, application/xhtml+xml, application/xml; charset=utf-8',
        },
      );
      if (response.statusCode == 200 && response.body == '{"status":"ready"}') {
        return true;
      } else {
        FLog.error(
            text:
                'Server not ready (${response.statusCode}) body: ${response.body}');
      }
    } on Exception catch (error, stacktrace) {
      FLog.error(
          text: 'Status Check Exception',
          exception: error,
          stacktrace: stacktrace);
      return false;
    }
    return false;
  }

  Future<String> _getTourFileContentFromRouteService(
      {@required LatLng userLocation,
      @required LatLng tourStart,
      List<LatLng> trackPointCoordinates}) async {
    final String baseUrl =
        await rootBundle.loadString('assets/tokens/route_service_url.txt');

    final List<List<double>> coordinateList = _getCoordinateList(
        tourStart: tourStart,
        userLocation: userLocation,
        trackPointCoordinates: trackPointCoordinates);
    final String postBody = jsonEncode(<String, dynamic>{
      'coordinates': coordinateList,
      'elevation': 'true',
      'extra_info': [
        'surface',
        'waycategory',
        'waytype',
        'traildifficulty',
      ],
      'instructions': 'true',
      'instructions_format': 'text',
      'roundabout_exits': 'true',
      'language': constantsHelper.language,
      'units': 'm',
    });
    FLog.logThis(
        text: 'ORS request body: $postBody',
        type: LogLevel.INFO,
        dataLogType: DataLogType.NETWORK.toString());
    // log("Sending body to ORS: $postBody",
    //     name: 'TourRemoteDataSource getPathToTour PostBody',
    //     time: DateTime.now());
    final Response response = await client.post(
      baseUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept':
            'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
      },
      body: postBody,
    );
    if (response.statusCode == 200) {
      FLog.trace(text: 'ORS response success (200)');
      FLog.logThis(
          text: 'ORS response tour: ${response.body}',
          type: LogLevel.INFO,
          dataLogType: DataLogType.NETWORK.toString());
      final String responseBody = _prepareResponseGpxForParser(response.body);
      // TODO remove when everything ORS related works
      // log("Code: ${response.statusCode}, Body: $responseBody",
      //     name: 'TourRemoteDataSource getPathToTour Response',
      //     time: DateTime.now());
      return responseBody;
    } else {
      FLog.error(
          text:
              'ORS response unsuccessful (${response.statusCode}) body: ${response.body}');
      log("Code: ${response.statusCode}, Body: ${response.body}",
          name: 'TourRemoteDataSource getPathToTour Error',
          time: DateTime.now());
      throw ServerException();
    }
  }

  List<List<double>> _getCoordinateList(
      {@required LatLng userLocation,
      @required LatLng tourStart,
      List<LatLng> trackPointCoordinates = const []}) {
    if (trackPointCoordinates.isEmpty) {
      FLog.trace(text: 'trackPointCoordinates empty -> getting path to tour');
      return [
        [userLocation.longitude, userLocation.latitude],
        [tourStart.longitude, tourStart.latitude]
      ];
    } else {
      final List<List<double>> coordinateList = [];
      for (final LatLng trackPoint in trackPointCoordinates) {
        coordinateList.add([trackPoint.longitude, trackPoint.latitude]);
      }
      FLog.trace(
          text:
              'trackPointCoordinates not empty -> getting ORS tour for enhancement');
      return coordinateList;
    }
  }

  String _prepareResponseGpxForParser(String responseGpx) {
    String modifiedResponseGpx = responseGpx;
    modifiedResponseGpx = modifiedResponseGpx.replaceAll('maxLat', 'maxlat');
    modifiedResponseGpx = modifiedResponseGpx.replaceAll('maxLon', 'maxlon');
    modifiedResponseGpx = modifiedResponseGpx.replaceAll('minLat', 'minlat');
    modifiedResponseGpx = modifiedResponseGpx.replaceAll('minLon', 'minlon');
    return modifiedResponseGpx;
  }

  @override
  Future<Tour> getEnhancedTour({Tour tour}) async {
    try {
      final List<LatLng> coordinateList =
          tour.trackPoints.map((trackPoint) => trackPoint.latLng).toList();
      final TourModel tourResponse = await getPathToTour(
          userLocation: null,
          tourStart: null,
          trackPointCoordinates: coordinateList,
          tourName: tour.name);
      for (var i = 0; i < tour.trackPoints.length; i++) {
        for (final WayPoint responseWayPoint in tourResponse.wayPoints) {
          final TrackPoint tourTrackPoint = tour.trackPoints[i];
          final bool pointsHaveSameCoordinates = _haveSameCoordinates(
              tourTrackPoint.latLng, responseWayPoint.latLng);
          final bool responsePointHasDirection =
              responseWayPoint.direction != null &&
                  responseWayPoint.direction != '';
          if (pointsHaveSameCoordinates && responsePointHasDirection) {
            String name;
            String location;
            String direction;
            String turnSymboldId;
            if (tourTrackPoint.isWayPoint) {
              final WayPoint wayPoint = tourTrackPoint.wayPoint;
              if (wayPoint.name != '') {
                name = wayPoint.name;
              } else {
                name = responseWayPoint.name;
              }
              if (wayPoint.location != '') {
                location = wayPoint.location;
              } else {
                location = responseWayPoint.location;
              }
              if (wayPoint.direction != '') {
                direction = wayPoint.direction;
              } else {
                direction = responseWayPoint.direction;
              }
              if (wayPoint.turnSymboldId != '') {
                turnSymboldId = wayPoint.turnSymboldId;
              } else {
                turnSymboldId = responseWayPoint.turnSymboldId;
              }
            } else {
              name = responseWayPoint.name;
              location = responseWayPoint.location;
              direction = responseWayPoint.direction;
              turnSymboldId = responseWayPoint.turnSymboldId;
            }
            final WayPointModel newWayPoint = WayPointModel(
                latLng: tourTrackPoint.latLng,
                distanceFromStart: tourTrackPoint.distanceFromStart,
                name: name,
                elevation: tourTrackPoint.elevation != 0.0
                    ? tourTrackPoint.elevation
                    : responseWayPoint.elevation,
                surface: tourTrackPoint.surface != ''
                    ? tourTrackPoint.surface
                    : responseWayPoint.surface,
                location: location,
                direction: direction,
                turnSymboldId: turnSymboldId);
            if (tourTrackPoint.isWayPoint) {
              final WayPoint currentWayPoint = tourTrackPoint.wayPoint;
              tour.replaceWayPoint(currentWayPoint, newWayPoint);
            } else {
              tour.addWayPointToTrackPoint(tourTrackPoint, newWayPoint, i);
            }
          }
        }
      }

      _overrideTourFileWithEnhancedTour(tour);
      return tour;
    } on Exception {
      rethrow;
    }
  }

  bool _haveSameCoordinates(LatLng first, LatLng second) {
    final double firstLat = _reduceDoublePrecision(first.latitude);
    final double firstLon = _reduceDoublePrecision(first.longitude);
    final double secondLat = _reduceDoublePrecision(second.latitude);
    final double secondLon = _reduceDoublePrecision(second.longitude);
    if (firstLat == secondLat && firstLon == secondLon) {
      return true;
    } else {
      return false;
    }
  }

  double _reduceDoublePrecision(double value) {
    return double.parse(value.toStringAsFixed(3));
  }

  Future<FunctionResult> _overrideTourFileWithEnhancedTour(Tour tour) async {
    final String filePath = tourListHelper.getPath(tour.name);
    final List<TrackPointModel> trackPoints = tour.trackPoints
        .map((trackPoint) => TrackPointModel(
            latLng: trackPoint.latLng,
            elevation: trackPoint.elevation,
            distanceFromStart: trackPoint.distanceFromStart,
            surface: trackPoint.surface,
            isWayPoint: trackPoint.isWayPoint,
            wayPoint: trackPoint.wayPoint))
        .toList();
    final List<WayPointModel> wayPoints = tour.wayPoints
        .map((wayPoint) => WayPointModel(
            name: wayPoint.name,
            latLng: wayPoint.latLng,
            elevation: wayPoint.elevation,
            distanceFromStart: wayPoint.distanceFromStart,
            surface: wayPoint.surface,
            direction: wayPoint.direction,
            location: wayPoint.location,
            turnSymboldId: wayPoint.turnSymboldId))
        .toList();
    await File(filePath).writeAsString(TourModel(
            name: tour.name,
            trackPoints: trackPoints,
            wayPoints: wayPoints,
            ascent: tour.ascent,
            descent: tour.descent,
            tourLength: tour.tourLength,
            bounds: tour.bounds)
        .toGpx());
    return FunctionResultSuccess();
  }
}
