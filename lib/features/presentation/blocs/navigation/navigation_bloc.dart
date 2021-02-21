import 'dart:async';

import 'package:bike_gps/features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../../core/error/failure.dart';
import '../../../../injection_container.dart';
import '../../../domain/entities/tour/entities.dart';
import '../../../domain/usecases/navigation/get_navigation_data.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

@lazySingleton
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
    } else if (event is NavigationStopped) {
      yield* _mapNavigationStoppedToState(event);
    }
  }

  Stream<NavigationState> _mapNavigationLoadedToState(
      NavigationLoaded event) async* {
    yield NavigationLoading();
    try {
      LatLng userLocation;
      if (event.userLocation != null) {
        userLocation =
            LatLng(event.userLocation.latitude, event.userLocation.longitude);
      } else {
        final LocationData locationData = await getIt<Location>().getLocation();
        userLocation = LatLng(locationData.latitude, locationData.longitude);
      }
      final MapboxState mapboxState = getIt<MapboxBloc>().state;
      if (mapboxState is MapboxLoadSuccess) {
        getIt<MapboxBloc>().add(MapboxLoaded(
            mapboxController: mapboxState.controller.copyWith(
                myLocationTrackingMode:
                    MyLocationTrackingMode.TrackingCompass)));
      }
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

  Stream<NavigationState> _mapNavigationStoppedToState(
      NavigationStopped event) async* {
    yield NavigationInitial();
  }
}
