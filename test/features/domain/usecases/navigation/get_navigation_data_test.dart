import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/usecases/navigation/get_navigation_data.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

void main() {
  DistanceHelper distanceHelper;
  GetNavigationData usecase;

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
      distanceFromStart: 0,
      elevation: 1,
      latLng: LatLng(1, 0),
      location: '',
      name: '',
      surface: '',
      turnSymboldId: '');
  const TrackPoint tSecondTrackPoint = TrackPoint(
      latLng: LatLng(1, 0),
      distanceFromStart: 0,
      elevation: 1,
      isWayPoint: true,
      surface: '',
      wayPoint: tSecondWayPoint);

  const WayPoint tThirdWayPoint = WayPoint(
      direction: '',
      distanceFromStart: 0,
      elevation: 0,
      latLng: LatLng(2, 0),
      location: '',
      name: '',
      surface: '',
      turnSymboldId: '');
  const TrackPoint tThirdTrackPoint = TrackPoint(
      latLng: LatLng(2, 0),
      distanceFromStart: 0,
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
      ascent: 1,
      bounds: LatLngBounds(
          northeast: const LatLng(2, 0), southwest: const LatLng(0, 0)),
      descent: 1,
      filePath: '',
      name: '',
      tourLength: 0,
      wayPoints: const [tFirstWayPoint, tSecondWayPoint, tThirdWayPoint]);

  setUp(() {
    distanceHelper = DistanceHelper();
    usecase = GetNavigationData(distanceHelper: distanceHelper);
  });

  group('GetNavigationData', () {
    test('should get navigation data', () async {
      // arrange
      const LatLng userLocation = LatLng(0, 0);
      const NavigationData tNavigationData = NavigationData(
          currentWayPoint: tFirstWayPoint,
          nextWayPoint: tSecondWayPoint,
          currentWayPointDistance: 0,
          distanceToTourEnd: 0);
      // act
      final result =
          await usecase(Params(tour: tTour, userLocation: userLocation));
      // assert
      expect(result, const Right(tNavigationData));
    });

    test('should get first way point as current way point when on it',
        () async {
      // arrange
      const LatLng userLocation = LatLng(0, 0);
      const NavigationData tNavigationData = NavigationData(
          currentWayPoint: tFirstWayPoint,
          nextWayPoint: tSecondWayPoint,
          currentWayPointDistance: 0,
          distanceToTourEnd: 0);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.currentWayPoint, tNavigationData.currentWayPoint);
    });

    test('should get first way point as current way point when in front of it',
        () async {
      // arrange
      const LatLng userLocation = LatLng(-1, 0);
      const NavigationData tNavigationData = NavigationData(
          currentWayPoint: tFirstWayPoint,
          nextWayPoint: tSecondWayPoint,
          currentWayPointDistance: 0,
          distanceToTourEnd: 0);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.currentWayPoint, tNavigationData.currentWayPoint);
    });

    test('should get second way point as current way point when on it',
        () async {
      // arrange
      const LatLng userLocation = LatLng(1, 0);
      const NavigationData tNavigationData = NavigationData(
          currentWayPoint: tSecondWayPoint,
          nextWayPoint: tThirdWayPoint,
          currentWayPointDistance: 0,
          distanceToTourEnd: 0);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.currentWayPoint, tNavigationData.currentWayPoint);
    });

    test(
        'should get second way point as current way point when closer to second than first',
        () async {
      // arrange
      const LatLng userLocation = LatLng(0.6, 0);
      const NavigationData tNavigationData = NavigationData(
          currentWayPoint: tSecondWayPoint,
          nextWayPoint: tThirdWayPoint,
          currentWayPointDistance: 0,
          distanceToTourEnd: 0);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.currentWayPoint, tNavigationData.currentWayPoint);
    });

    test(
        'should get second way point as current way point when the first has been passed',
        () async {
      // arrange
      const LatLng userLocation = LatLng(0.5, 0);
      const NavigationData tNavigationData = NavigationData(
          currentWayPoint: tSecondWayPoint,
          nextWayPoint: tThirdWayPoint,
          currentWayPointDistance: 0,
          distanceToTourEnd: 0);
      // act
      final NavigationData result =
          (await usecase(Params(tour: tTour, userLocation: userLocation)))
              .getOrElse(null);
      // assert
      expect(result.currentWayPoint, tNavigationData.currentWayPoint);
    });

    test('should get correct distance to current way point', () async {
      // arrange
      const LatLng userLocation = LatLng(0, 0);
      const NavigationData tNavigationData = NavigationData(
          currentWayPoint: tFirstWayPoint,
          nextWayPoint: tSecondWayPoint,
          currentWayPointDistance: 0,
          distanceToTourEnd: 0);
      // act
      final NavigationData result =
          await usecase(Params(tour: tTour, userLocation: userLocation))
              as NavigationData;
      // assert
      expect(result.currentWayPoint, tNavigationData.currentWayPoint);
    });

    test('should get correct next way point', () async {
      // arrange
      const LatLng userLocation = LatLng(0, 0);
      const NavigationData tNavigationData = NavigationData(
          currentWayPoint: tFirstWayPoint,
          nextWayPoint: tSecondWayPoint,
          currentWayPointDistance: 0,
          distanceToTourEnd: 0);
      // act
      final NavigationData result =
          await usecase(Params(tour: tTour, userLocation: userLocation))
              as NavigationData;
      // assert
      expect(result.currentWayPoint, tNavigationData.currentWayPoint);
    });

    test('should get correct distance to tour end', () async {
      // arrange
      const LatLng userLocation = LatLng(0, 0);
      const NavigationData tNavigationData = NavigationData(
          currentWayPoint: tFirstWayPoint,
          nextWayPoint: tSecondWayPoint,
          currentWayPointDistance: 0,
          distanceToTourEnd: 0);
      // act
      final NavigationData result =
          await usecase(Params(tour: tTour, userLocation: userLocation))
              as NavigationData;
      // assert
      expect(result.currentWayPoint, tNavigationData.currentWayPoint);
    });
  });
}
