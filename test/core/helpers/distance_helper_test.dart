import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpx/gpx.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

void main() {
  DistanceHelper distanceHelper;

  setUp(() {
    distanceHelper = DistanceHelper();
  });

  group('distanceBetweenLatLngs', () {
    const double distance = 111319.49079327357;
    test('should return the correct latitudinal distance between 1° in meters',
        () {
      // arrange
      const LatLng first = LatLng(0.0, 0.0);
      const LatLng second = LatLng(1.0, 0.0);
      // act
      final result = distanceHelper.distanceBetweenLatLngs(first, second);
      // assert
      expect(result, distance);
    });

    test('should return the correct longitudinal distance between 1° in meters',
        () {
      // arrange
      const LatLng first = LatLng(0.0, 0.0);
      const LatLng second = LatLng(0.0, 1.0);
      // act
      final result = distanceHelper.distanceBetweenLatLngs(first, second);
      // assert
      expect(result, distance);
    });

    test(
        'should return the correct latitudinal distance between 1° in meters when points are reversed',
        () {
      // arrange
      const LatLng first = LatLng(0.0, 0.0);
      const LatLng second = LatLng(1.0, 0.0);
      // act
      final result = distanceHelper.distanceBetweenLatLngs(second, first);
      // assert
      expect(result, distance);
    });

    test(
        'should return the correct longitudinal distance between 1° in meters when points are reversed',
        () {
      // arrange
      const LatLng first = LatLng(0.0, 0.0);
      const LatLng second = LatLng(0.0, 1.0);
      // act
      final result = distanceHelper.distanceBetweenLatLngs(second, first);
      // assert
      expect(result, distance);
    });

    test(
        'should clamp latitudes between -90.0 and +90.0 inclusively and thus return a distance of 180° converted to meters within floating point precision margins',
        () {
      // arrange
      const LatLng first = LatLng(99999999.0, 0.0);
      const LatLng second = LatLng(-99999999.0, 0.0);
      // act
      final result = distanceHelper.distanceBetweenLatLngs(first, second);
      // assert
      expect(result, moreOrLessEquals(distance * 180, epsilon: 1e-8));
    });
  });

  group('distanceBetweenWpts', () {
    const LatLng firstLatLng = LatLng(0.0, 0.0);
    const LatLng secondLatLng = LatLng(1.0, 0.0);
    final Wpt firstWayPoint =
        Wpt(lat: firstLatLng.latitude, lon: firstLatLng.longitude);
    final Wpt secondWayPoint =
        Wpt(lat: secondLatLng.latitude, lon: secondLatLng.longitude);
    test('should return the correct distance between two way points in meters',
        () {
      // arrange
      final distance =
          distanceHelper.distanceBetweenLatLngs(firstLatLng, secondLatLng);
      // act
      final result =
          distanceHelper.distanceBetweenWpts(firstWayPoint, secondWayPoint);
      // assert
      expect(result, distance);
    });
  });

  group('distanceToString', () {
    const double meterDistance = 100;
    const double kilometerDistance = 1200;
    test(
        'should return a string containing the distance in meters for distances less than 1km',
        () {
      // arrange
      // act
      final result = distanceHelper.distanceToString(meterDistance);
      // assert
      expect(result, '100 m');
    });

    test(
        'should return a string containing the distance in kilo meters with meters after the decimal point for distances greater than 1km',
        () {
      // arrange
      // act
      final result = distanceHelper.distanceToString(kilometerDistance);
      // assert
      expect(result, '1.2 km');
    });
  });
}
