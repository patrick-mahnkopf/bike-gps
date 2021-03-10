import 'dart:async';

import 'package:bike_gps/core/helpers/distance_helper.dart';
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
  static const double maxAllowedDistanceToTour =
      double.maxFinite; // TODO change back to 20

  NavigationBloc(
      {@required this.getNavigationData,
      @required this.getPathToTour,
      @required this.distanceHelper})
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
    yield NavigationLoading();
    try {
      final LatLng userLocation = await _getUserLocationFromEvent(event);
      final Either<Failure, NavigationData> navigationDataEither =
          await getNavigationData(NavigationDataParams(
              tour: event.tour, userLocation: userLocation));
      yield* _eitherHandleGetPathToTourOrNavigationLoadState(
          navigationDataEither, userLocation, event.tour);
    } on Exception catch (error) {
      yield NavigationLoadFailure(message: error.toString());
    }
  }

  Future<LatLng> _getUserLocationFromEvent(NavigationLoaded event) async {
    if (event.userLocation != null) {
      return LatLng(event.userLocation.latitude, event.userLocation.longitude);
    } else {
      final LocationData locationData = await getIt<Location>().getLocation();
      return LatLng(locationData.latitude, locationData.longitude);
    }
  }

  Stream<NavigationState> _eitherHandleGetPathToTourOrNavigationLoadState(
      Either<Failure, NavigationData> failureOrNavigationData,
      LatLng userLocation,
      Tour tour) async* {
    if (failureOrNavigationData.isRight()) {
      final NavigationData navigationData =
          failureOrNavigationData.getOrElse(() => null);
      yield* _eitherGetPathToTourOrNavigationLoadSuccessState(
          tour, navigationData, userLocation);
    } else {
      yield const NavigationLoadFailure(
          message: 'Could not load navigation data');
    }
  }

  Stream<NavigationState> _eitherGetPathToTourOrNavigationLoadSuccessState(
      Tour tour, NavigationData navigationData, LatLng userLocation) async* {
    final double distanceToTour =
        distanceHelper.distanceToTour(userLocation, tour, navigationData);
    if (distanceToTour >= maxAllowedDistanceToTour) {
      final Either<Failure, Tour> pathToTourEither = await getPathToTour(
          PathToTourParams(
              tourStart: tour.trackPoints.first.latLng,
              userLocation: userLocation));
      yield* _eitherHandleNavigationToTourOrLoadFailureState(
          pathToTourEither, userLocation);
    } else {
      yield NavigationLoadSuccess(
          currentWayPoint: navigationData.currentWayPoint,
          currentWayPointDistance: navigationData.currentWayPointDistance,
          nextWayPoint: navigationData.nextWayPoint,
          distanceToTourEnd: navigationData.distanceToTourEnd,
          currentPosition: userLocation);
    }
  }

  Stream<NavigationState> _eitherHandleNavigationToTourOrLoadFailureState(
      Either<Failure, Tour> pathToTourEither, LatLng userLocation) async* {
    if (pathToTourEither.isRight()) {
      final Tour pathToTour = pathToTourEither.getOrElse(() => null);
      final Either<Failure, NavigationData> navigationToTourDataEither =
          await getNavigationData(NavigationDataParams(
              tour: pathToTour, userLocation: userLocation));
      yield* _eitherNavigationToTourLoadSuccessOrLoadFailureState(
          navigationToTourDataEither, userLocation, pathToTour);
    } else {
      yield const NavigationLoadFailure(message: 'Could not get path to tour');
    }
  }

  Stream<NavigationState> _eitherNavigationToTourLoadSuccessOrLoadFailureState(
      Either<Failure, NavigationData> failureOrNavigationToTourData,
      LatLng userLocation,
      Tour pathToTour) async* {
    yield failureOrNavigationToTourData.fold(
      (failure) => const NavigationLoadFailure(
          message: 'Could not load path to tour navigation data'),
      (navigationToTourData) => NavigationToTourLoadSuccess(
          currentWayPoint: navigationToTourData.currentWayPoint,
          currentWayPointDistance: navigationToTourData.currentWayPointDistance,
          nextWayPoint: navigationToTourData.nextWayPoint,
          distanceToTourEnd: navigationToTourData.distanceToTourEnd,
          currentPosition: userLocation,
          pathToTour: pathToTour),
    );
  }

  Stream<NavigationState> _mapNavigationStoppedToState(
      NavigationStopped event) async* {
    yield NavigationInitial();
  }
}
