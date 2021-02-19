import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/usecases/navigation/get_navigation_data.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

void main() {
  DistanceHelper distanceHelper;
  GetNavigationData usecase;

  const double degreeDistance = 111319.49079327357;
  const WayPoint tFirstWayPoint = WayPoint(
      direction: '',
      distanceFromStart: 0,
      elevation: 0,
      latLng: LatLng(0, 0),
      location: '',
      name: '',
      surface: '',
      turnSymboldId: '');
  const TrackPoint tFirstTrackPoint = TrackPoint(
      latLng: LatLng(0, 0),
      distanceFromStart: 0,
      elevation: 0,
      isWayPoint: true,
      surface: '',
      wayPoint: tFirstWayPoint);

  const WayPoint tSecondWayPoint = WayPoint(
      direction: '',
      distanceFromStart: 1 * degreeDistance,
      elevation: 2,
      latLng: LatLng(1, 0),
      location: '',
      name: '',
      surface: '',
      turnSymboldId: '');
  const TrackPoint tSecondTrackPoint = TrackPoint(
      latLng: LatLng(1, 0),
      distanceFromStart: 1 * degreeDistance,
      elevation: 2,
      isWayPoint: true,
      surface: '',
      wayPoint: tSecondWayPoint);

  const WayPoint tThirdWayPoint = WayPoint(
      direction: '',
      distanceFromStart: 2 * degreeDistance,
      elevation: 0,
      latLng: LatLng(2, 0),
      location: '',
      name: '',
      surface: '',
      turnSymboldId: '');
  const TrackPoint tThirdTrackPoint = TrackPoint(
      latLng: LatLng(2, 0),
      distanceFromStart: 2 * degreeDistance,
      elevation: 0,
      isWayPoint: true,
      surface: '',
      wayPoint: tThirdWayPoint);

  final Tour tTour = Tour(
      trackPoints: const [
        tFirstTrackPoint,
        tSecondTrackPoint,
        tThirdTrackPoint
      ],
      ascent: 2,
      bounds: LatLngBounds(
          northeast: const LatLng(2, 0), southwest: const LatLng(0, 0)),
      descent: 2,
      filePath: '',
      name: '',
      tourLength: 2 * degreeDistance,
      wayPoints: const [tFirstWayPoint, tSecondWayPoint, tThirdWayPoint]);

  setUp(() {
    distanceHelper = DistanceHelper();
    usecase = GetNavigationData(distanceHelper: distanceHelper);
  });

  test('should get navigation data', () async {
    // arrange
    const LatLng userLocation = LatLng(0, 0);
    const NavigationData tNavigationData = NavigationData(
        currentWayPoint: tFirstWayPoint,
        nextWayPoint: tSecondWayPoint,
        currentWayPointDistance: 0,
        distanceToTourEnd: 3 * degreeDistance);
    // act
    final result =
        await usecase(Params(tour: tTour, userLocation: userLocation));
    // assert
    expect(result, const Right(tNavigationData));
  });

  group('currentWayPoint', () {
    test('should get first way point as current way point when on it',
        () async {
      // arrange
      const LatLng userLocation = LatLng(0, 0);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.currentWayPoint, tFirstWayPoint);
    });

    test('should get first way point as current way point when in front of it',
        () async {
      // arrange
      const LatLng userLocation = LatLng(-1, 0);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.currentWayPoint, tFirstWayPoint);
    });

    test('should get second way point as current way point when on it',
        () async {
      // arrange
      const LatLng userLocation = LatLng(1, 0);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.currentWayPoint, tSecondWayPoint);
    });

    test(
        'should get second way point as current way point when closer to second than first',
        () async {
      // arrange
      const LatLng userLocation = LatLng(0.6, 0);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.currentWayPoint, tSecondWayPoint);
    });

    test(
        'should get second way point as current way point when the first has been passed',
        () async {
      // arrange
      const LatLng userLocation = LatLng(0.1, 0);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.currentWayPoint, tSecondWayPoint);
    });

    test(
        'should get third way point as current way point when the second has been passed',
        () async {
      // arrange
      const LatLng userLocation = LatLng(1.1, 0);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.currentWayPoint, tThirdWayPoint);
    });
  });

  group('currentWayPointDistance', () {
    test('should get correct distance to current way point', () async {
      // arrange
      const LatLng userLocation = LatLng(0, 0);
      final double tCurrentWayPointDistance = distanceHelper
          .distanceBetweenLatLngs(userLocation, tFirstWayPoint.latLng);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.currentWayPointDistance, tCurrentWayPointDistance);
    });
  });

  group('nextWayPoint', () {
    test('should get correct next way point', () async {
      // arrange
      const LatLng userLocation = LatLng(0, 0);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.nextWayPoint, tSecondWayPoint);
    });
  });

  group('distanceToTourEnd', () {
    test('should get correct distance to tour end from first way point',
        () async {
      // arrange
      const LatLng userLocation = LatLng(0, 0);
      final double tDistanceToTourEnd = tTour.tourLength;
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.distanceToTourEnd, tDistanceToTourEnd);
    });

    test(
        'should get correct distance to tour end from between the first two way points',
        () async {
      // arrange
      const LatLng userLocation = LatLng(0.6, 0);
      final double tDistanceToTourEnd = distanceHelper.distanceBetweenLatLngs(
              userLocation, tSecondWayPoint.latLng) +
          (tThirdWayPoint.distanceFromStart -
              tSecondWayPoint.distanceFromStart);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.distanceToTourEnd, tDistanceToTourEnd);
    });
  });
}
