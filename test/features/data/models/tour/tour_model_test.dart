import 'package:bike_gps/features/data/models/tour/models.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

void main() {
  final tTourModel = TourModel(
      ascent: 1,
      bounds: LatLngBounds(
          northeast: const LatLng(1, 1), southwest: const LatLng(0, 0)),
      descent: 1,
      filePath: "testPath",
      name: "testName",
      tourLength: 3,
      trackPoints: const [],
      wayPoints: const []);

  test('should be a subclass of Tour entity', () async {
    // assert
    expect(tTourModel, isA<Tour>());
  });
}
