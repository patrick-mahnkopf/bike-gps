import 'dart:async';

import 'package:bike_gps/core/error/failure.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/usecases/navigation/get_navigation_data.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final GetNavigationData _getNavigationData;
  NavigationBloc({@required GetNavigationData getNavigationData})
      : assert(getNavigationData != null),
        _getNavigationData = getNavigationData,
        super(NavigationInitial());

  @override
  Stream<NavigationState> mapEventToState(
    NavigationEvent event,
  ) async* {
    if (event is NavigationLoaded) {
      yield* _mapNavigationLoadedToState(event);
    }
  }

  Stream<NavigationState> _mapNavigationLoadedToState(
      NavigationLoaded event) async* {
    yield NavigationLoading();
    try {
      final LatLng userLocation =
          LatLng(event.userLocation.latitude, event.userLocation.longitude);
      final Either<Failure, NavigationData> navigationDataEither =
          await _getNavigationData(
              Params(tour: event.tour, userLocation: userLocation));
      yield* _eitherLoadSuccessOrLoadFailureState(navigationDataEither);
    } on Exception catch (error) {
      yield NavigationLoadFailure(message: error.toString());
    }
  }

  Stream<NavigationState> _eitherLoadSuccessOrLoadFailureState(
    Either<Failure, NavigationData> failureOrNavigationData,
  ) async* {
    yield failureOrNavigationData.fold(
      (failure) => const NavigationLoadFailure(
          message: 'Could not load navigation data'),
      (navigationData) => NavigationLoadSuccess(
          currentWayPoint: navigationData.currentWayPoint,
          currentWayPointDistance: navigationData.currentWayPointDistance,
          nextWayPoint: navigationData.nextWayPoint,
          distanceToTourEnd: navigationData.distanceToTourEnd),
    );
  }
}
