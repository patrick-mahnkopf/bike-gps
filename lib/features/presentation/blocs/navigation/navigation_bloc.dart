import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bike_gps/core/controllers/controllers.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:bike_gps/core/helpers/settings_helper.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_path_to_tour.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../../core/error/failure.dart';
import '../../../../injection_container.dart';
import '../../../domain/entities/tour/entities.dart';
import '../../../domain/usecases/navigation/get_navigation_data.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

@injectable
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final GetNavigationData getNavigationData;
  final GetPathToTour getPathToTour;
  final DistanceHelper distanceHelper;
  final SettingsHelper settingsHelper;

  NavigationBloc(
      {@required this.getNavigationData,
      @required this.getPathToTour,
      @required this.distanceHelper,
      @required this.settingsHelper})
      : assert(getNavigationData != null),
        assert(getPathToTour != null),
        super(NavigationInitial());

  @override
  Stream<NavigationState> mapEventToState(
    NavigationEvent event,
  ) async* {
    if (event is NavigationLoaded) {
      yield* _mapNavigationLoadedToState(event);
    } else if (event is NavigationStopped) {
      yield* _mapNavigationStoppedToState(event);
    }
  }

  Stream<NavigationState> _mapNavigationLoadedToState(
      NavigationLoaded event) async* {
    try {
      final LatLng userLocation = await _getUserLocationFromEvent(event);
      final Either<Failure, NavigationData> navigationDataEither =
          await getNavigationData(NavigationDataParams(
              tour: event.tour, userLocation: userLocation));
      yield* _handleNavigationOrFailureState(
          navigationDataEither: navigationDataEither,
          userLocation: userLocation,
          event: event);
    } on Exception catch (error) {
      yield NavigationLoadFailure(message: error.toString());
    }
  }

  Future<LatLng> _getUserLocationFromEvent(NavigationLoaded event) async {
    if (event.userLocation != null) {
      return LatLng(event.userLocation.latitude, event.userLocation.longitude);
    } else {
      LocationData locationData;
      // Location().getLocation() gets stuck on iOS in current Location package version
      if (Platform.isIOS) {
        await for (final LocationData userLocation
            in getIt<Location>().onLocationChanged) {
          locationData = userLocation;
          break;
        }
      } else {
        locationData = await getIt<Location>().getLocation();
      }
      return LatLng(locationData.latitude, locationData.longitude);
    }
  }

  Stream<NavigationState> _handleNavigationOrFailureState(
      {@required Either<Failure, NavigationData> navigationDataEither,
      @required LatLng userLocation,
      @required NavigationLoaded event}) async* {
    if (navigationDataEither.isRight()) {
      final NavigationData navigationData =
          navigationDataEither.getOrElse(() => null);
      yield* _handleNavigation(
          navigationData: navigationData,
          userLocation: userLocation,
          event: event);
    } else {
      log('NavigationFailure',
          name: 'NavigationBloc navigation _handleNavigationOrFailureState');
      yield const NavigationLoadFailure(
          message: 'Could not load navigation data');
    }
  }

  Stream<NavigationState> _handleNavigation(
      {@required NavigationData navigationData,
      @required LatLng userLocation,
      @required NavigationLoaded event}) async* {
    final double distanceToTour =
        await distanceHelper.distanceToTour(userLocation, event.tour);
    log('distanceToTour: $distanceToTour',
        name: 'NavigationBloc navigation _handleNavigation');
    // Not on tour -> navigate to tour
    if (distanceToTour >= ConstantsHelper.maxAllowedDistanceToTour &&
        settingsHelper.navigateToTourEnabled) {
      log('Not on tour -> navigating to tour',
          name: 'NavigationBloc navigation _handleNavigation');
      yield* _startOrContinueNavigationToTour(
          userLocation: userLocation,
          event: event,
          closestWayPoint: navigationData.nextWayPoint.latLng,
          tourNavigationData: navigationData);
      // On tour -> continue navigation on tour
    } else {
      log('On tour or navigation to tour disabled -> continue navigation on tour, navigateToTourEnabled: ${settingsHelper.navigateToTourEnabled}',
          name: 'NavigationBloc navigation _handleNavigation');
      event.mapboxController.clearPathToTour();
      yield NavigationLoadSuccess(
          currentWayPoint: navigationData.currentWayPoint,
          nextWayPoint: navigationData.nextWayPoint,
          currentWayPointDistance: navigationData.distanceToCurrentWayPoint,
          distanceToTourEnd: navigationData.distanceToTourEnd,
          userLocation: userLocation);
    }
  }

  Stream<NavigationState> _startOrContinueNavigationToTour(
      {@required LatLng userLocation,
      @required NavigationLoaded event,
      @required LatLng closestWayPoint,
      @required NavigationData tourNavigationData}) async* {
    final NavigationState navigationState = state;
    // Already navigating to tour
    if (navigationState is NavigationToTourLoadSuccess) {
      log('Already navigating to tour',
          name: 'NavigationBloc navigation _startOrContinueNavigationToTour');
      final Either<Failure, NavigationData> navigationToTourDataEither =
          await getNavigationData(NavigationDataParams(
              tour: navigationState.pathToTour, userLocation: userLocation));
      yield* _continueNavigationToTourOrFailureState(
          navigationToTourDataEither: navigationToTourDataEither,
          userLocation: userLocation,
          event: event,
          closestWayPoint: closestWayPoint,
          tourNavigationData: tourNavigationData);
      // No previous path to tour
    } else {
      log('No previous path to tour',
          name: 'NavigationBloc navigation _startOrContinueNavigationToTour');
      final Either<Failure, Tour> pathToTourEither = await getPathToTour(
          PathToTourParams(
              tourStart: closestWayPoint, userLocation: userLocation));
      yield* _newPathToTourOrNavigationLoadSuccess(
          pathToTourEither: pathToTourEither,
          userLocation: userLocation,
          event: event,
          tourNavigationData: tourNavigationData);
    }
  }

  Stream<NavigationState> _continueNavigationToTourOrFailureState(
      {@required Either<Failure, NavigationData> navigationToTourDataEither,
      @required LatLng userLocation,
      @required NavigationLoaded event,
      @required LatLng closestWayPoint,
      @required NavigationData tourNavigationData}) async* {
    if (navigationToTourDataEither.isRight()) {
      final NavigationData navigationToTourData =
          navigationToTourDataEither.getOrElse(() => null);
      yield* _continueOnPathToTourOrGetNewPath(
          navigationToTourData: navigationToTourData,
          userLocation: userLocation,
          event: event,
          closestWayPoint: closestWayPoint,
          tourNavigationData: tourNavigationData);
    } else {
      log('NavigationFailure',
          name:
              'NavigationBloc navigation _continueNavigationToTourOrFailureState');
      yield const NavigationLoadFailure(
          message: 'Could not load navigation data');
    }
  }

  Stream<NavigationState> _continueOnPathToTourOrGetNewPath(
      {@required NavigationData navigationToTourData,
      @required LatLng userLocation,
      @required NavigationLoaded event,
      @required LatLng closestWayPoint,
      @required NavigationData tourNavigationData}) async* {
    final NavigationToTourLoadSuccess navigationState =
        state as NavigationToTourLoadSuccess;
    final double distanceToPath = await distanceHelper.distanceToTour(
        userLocation, navigationState.pathToTour);
    log('distanceToPath: $distanceToPath',
        name: 'NavigationBloc navigation _continueOnPathToTourOrGetNewPath');
    // Left path to tour -> navigate along new path to tour
    if (distanceToPath >= ConstantsHelper.maxAllowedDistanceToTour) {
      log('Left path to tour -> navigate along new path to tour',
          name: 'NavigationBloc navigation _continueOnPathToTourOrGetNewPath');
      final Either<Failure, Tour> pathToTourEither = await getPathToTour(
          PathToTourParams(
              tourStart: closestWayPoint, userLocation: userLocation));
      yield* _newPathToTourOrNavigationLoadSuccess(
          pathToTourEither: pathToTourEither,
          userLocation: userLocation,
          event: event,
          tourNavigationData: tourNavigationData);
      // Still on path to tour -> continue navigation to tour
    } else {
      log('Still on path to tour -> continue navigation to tour',
          name: 'NavigationBloc navigation _continueOnPathToTourOrGetNewPath');
      final Either<Failure, NavigationData> navigationToTourDataEither =
          await getNavigationData(NavigationDataParams(
              tour: navigationState.pathToTour, userLocation: userLocation));
      yield* _navigateOnPathToTourOrFailureState(
          navigationToTourDataEither: navigationToTourDataEither,
          pathToTour: navigationState.pathToTour,
          userLocation: userLocation,
          event: event);
    }
  }

  Stream<NavigationState> _newPathToTourOrNavigationLoadSuccess(
      {@required Either<Failure, Tour> pathToTourEither,
      @required LatLng userLocation,
      @required NavigationLoaded event,
      @required NavigationData tourNavigationData}) async* {
    if (pathToTourEither.isRight()) {
      final Tour pathToTour = pathToTourEither.getOrElse(() => null);
      await event.mapboxController.addPathToTour(pathToTour);
      final Either<Failure, NavigationData> navigationToTourDataEither =
          await getNavigationData(NavigationDataParams(
              tour: pathToTour, userLocation: userLocation));
      yield* _navigateOnPathToTourOrFailureState(
          navigationToTourDataEither: navigationToTourDataEither,
          pathToTour: pathToTour,
          userLocation: userLocation,
          event: event);
    } else {
      log('NavigationFailure',
          name: 'NavigationBloc navigation _newPathToTourOrFailureState');
      yield const NavigationLoadFailure(
          message: 'Could not load path to tour navigation data');
      yield NavigationLoadSuccess(
          currentWayPoint: tourNavigationData.currentWayPoint,
          nextWayPoint: tourNavigationData.nextWayPoint,
          currentWayPointDistance: tourNavigationData.distanceToCurrentWayPoint,
          distanceToTourEnd: tourNavigationData.distanceToTourEnd,
          userLocation: userLocation);
    }
  }

  Stream<NavigationState> _navigateOnPathToTourOrFailureState(
      {@required Either<Failure, NavigationData> navigationToTourDataEither,
      @required Tour pathToTour,
      @required LatLng userLocation,
      @required NavigationLoaded event}) async* {
    if (navigationToTourDataEither.isRight()) {
      final NavigationData navigationToTourData =
          navigationToTourDataEither.getOrElse(() => null);
      log('NavigationToTourLoadSuccess',
          name:
              'NavigationBloc navigation _navigateOnPathToTourOrFailureState');
      yield NavigationToTourLoadSuccess(
          currentWayPoint: navigationToTourData.currentWayPoint,
          nextWayPoint: navigationToTourData.nextWayPoint,
          currentWayPointDistance:
              navigationToTourData.distanceToCurrentWayPoint,
          distanceToTourEnd: navigationToTourData.distanceToTourEnd,
          userLocation: userLocation,
          pathToTour: pathToTour);
    } else {
      log('NavigationFailure',
          name:
              'NavigationBloc navigation _navigateOnPathToTourOrFailureState');
      yield const NavigationLoadFailure(message: 'Could not load path to tour');
    }
  }

  Stream<NavigationState> _mapNavigationStoppedToState(
      NavigationStopped event) async* {
    yield NavigationInitial();
  }
}
