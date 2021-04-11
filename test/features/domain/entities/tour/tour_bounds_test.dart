import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

void main() {
  TourBounds tTourBounds;
  TourBounds tOther;

  setUp(() {
    tTourBounds = TourBounds(
        bounds: LatLngBounds(
            northeast: const LatLng(5, 5), southwest: const LatLng(1, 1)),
        name: 'test');
    tOther = TourBounds(
        bounds: LatLngBounds(
            northeast: const LatLng(7, 7), southwest: const LatLng(3, 3)),
        name: 'test');
  });

  test('should get the correct area', () async {
    //arrange
    //act
    final result = tTourBounds.area;
    //assert
    expect(result, 16);
  });

  test('should get the correct overlap', () async {
    //arrange
    //act
    final result = tTourBounds.getOverlap(tOther);
    //assert
    expect(result, 4 / 28);
  });
}
