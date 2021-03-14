import 'dart:convert';
import 'dart:developer';

import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/features/data/data_sources/tour_parser/tour_parser.dart';
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
}

@Injectable(as: TourRemoteDataSource)
class TourRemoteDataSourceImpl implements TourRemoteDataSource {
  final Client client;
  final TourParser tourParser;
  final ConstantsHelper constantsHelper;

  TourRemoteDataSourceImpl(
      {@required this.tourParser,
      @required this.client,
      @required this.constantsHelper});

  /// Calls the route service endpoint found in 'assets/token/route_service_url.txt'.
  ///
  /// Throws a [ServerException] for all error codes.
  @override
  Future<TourModel> getPathToTour(
      {@required LatLng userLocation, @required LatLng tourStart}) async {
    try {
      if (await _checkRouteServiceReady()) {
        final String tourFileContent =
            await _getTourFileContentFromRouteService(
                userLocation: userLocation, tourStart: tourStart);
        return tourParser.getTourFromFileContent(
            tourFileContent: tourFileContent,
            tourName: 'ORS',
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
      }
    } on Exception {
      return false;
    }
    return false;
  }

  Future<String> _getTourFileContentFromRouteService(
      {@required LatLng userLocation, @required LatLng tourStart}) async {
    final String baseUrl =
        await rootBundle.loadString('assets/tokens/route_service_url.txt');
    final String postBody = jsonEncode(<String, dynamic>{
      'coordinates': [
        [userLocation.longitude, userLocation.latitude],
        [tourStart.longitude, tourStart.latitude]
      ],
      'elevation': 'true',
      // 'extra_info': [
      //   'surface',
      //   'waycategory',
      //   'waytype',
      //   'traildifficulty',
      // ],
      'instructions': 'true',
      'instructions_format': 'text',
      // 'roundabout_exits': 'true',
      'language': constantsHelper.language,
      'units': 'm',
    });
    log("Sending body to ORS: $postBody",
        name: 'TourRemoteDataSource getPathToTour PostBody',
        time: DateTime.now());
    final Response response = await client.post(
      baseUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept':
            'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
      },
      body: jsonEncode(<String, dynamic>{
        'coordinates': [
          [userLocation.longitude, userLocation.latitude],
          [tourStart.longitude, tourStart.latitude]
        ],
        'extra_info': [
          'surface',
          'waycategory',
          'waytype',
          'traildifficulty',
        ],
        'instructions': 'true',
        'instructions_format': 'text',
      }),
    );
    if (response.statusCode == 200) {
      final String responseBody = _prepareResponseGpxForParser(response.body);
      // TODO remove when everything ORS related works
      // log("Code: ${response.statusCode}, Body: $responseBody",
      //     name: 'TourRemoteDataSource getPathToTour Response',
      //     time: DateTime.now());
      return responseBody;
    } else {
      log("Code: ${response.statusCode}, Body: ${response.body}",
          name: 'TourRemoteDataSource getPathToTour Error',
          time: DateTime.now());
      throw ServerException();
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
}
