import 'dart:async';
import 'dart:math' show max;

import 'package:bike_gps/core/controllers/controllers.dart';
import 'package:bike_gps/core/helpers/settings_helper.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_alternative_tours.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_enhanced_tour.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_tour.dart';
import 'package:bloc/bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../domain/entities/tour/entities.dart';

part 'tour_event.dart';
part 'tour_state.dart';

const String parserFailureMessage = 'Parser Failure';
const String serverFailureMessage = 'Server Failure';

/// BLoC responsible for the tours.
@lazySingleton
class TourBloc extends Bloc<TourEvent, TourState> {
  final GetTour getTour;
  final GetAlternativeTours getAlternativeTours;
  final GetEnhancedTour getEnhancedTour;
  final SettingsHelper settingsHelper;

  TourBloc(
      {@required this.getTour,
      @required this.getAlternativeTours,
      @required this.getEnhancedTour,
      @required this.settingsHelper})
      : assert(getTour != null),
        assert(getAlternativeTours != null),
        assert(getEnhancedTour != null),
        super(TourEmpty());

  @override
  Stream<TourState> mapEventToState(
    TourEvent event,
  ) async* {
    if (event is TourLoaded) {
      yield* _mapTourLoadedToState(event);
    } else if (event is TourRemoved) {
      yield* _mapTourRemovedToState();
    }
  }

  /// Loads the tour and looks for alternative tours.
  ///
  /// Yields [TourLoadFailure] state on error.
  Stream<TourState> _mapTourLoadedToState(TourLoaded event) async* {
    yield TourLoading(previousState: state);
    try {
      final Either<Failure, Tour> failureOrTour =
          await getTour(TourParams(name: event.tourName));
      final Either<Failure, List<Tour>> failureOrAlternativeTours =
          await getAlternativeTours(
              AlternativeTourParams(mainTourName: event.tourName));
      yield* _eitherLoadSuccessOrLoadFailureState(
          failureOrTour, event.mapboxController, failureOrAlternativeTours);
    } on Exception catch (error) {
      yield TourLoadFailure(message: error.toString());
      rethrow;
    }
  }

  /// Checks if the [Tour] and optionally also alternative tours or a Failure
  /// was returned by the use case and handles accordingly.
  ///
  /// Yields [TourLoadFailure] state on error.
  Stream<TourState> _eitherLoadSuccessOrLoadFailureState(
      Either<Failure, Tour> failureOrTour,
      MapboxController mapboxController,
      Either<Failure, List<Tour>> failureOrAlternativeTours) async* {
    if (failureOrTour.isRight()) {
      final Tour tour = failureOrTour.getOrElse(() => null);

      /// Pass alternative tours if they exist.
      if (failureOrAlternativeTours.isRight()) {
        final List<Tour> alternativeTours =
            failureOrAlternativeTours.getOrElse(() => null);
        yield* _tourLoadSuccessOrEnhanceFirst(
            tour, alternativeTours, mapboxController);

        /// No alternative tours were found.
      } else {
        yield* _tourLoadSuccessOrEnhanceFirst(tour, [], mapboxController);
      }
    } else {
      yield failureOrTour.fold(
        (failure) => TourLoadFailure(message: _mapFailureToMessage(failure)),
        (tour) => null,
      );
    }
  }

  /// Checks if the tour should be enhanced before using it.
  ///
  /// Tours without direction information will be enhanced if the setting is
  /// turned on and the device is connected to wifi. Directly yields
  /// [TourLoadSuccess] state if no enhancement should be done.
  Stream<TourState> _tourLoadSuccessOrEnhanceFirst(Tour tour,
      List<Tour> alternativeTours, MapboxController mapboxController) async* {
    Tour tourWithDirections = tour;
    final ConnectivityResult connectivityResult =
        await Connectivity().checkConnectivity();
    final bool wifiConnected = connectivityResult == ConnectivityResult.wifi;

    /// Checks if the tour should be enhanced. Tours without direction
    /// information should be enhanced if the setting is turned on and the
    /// device is connected to wifi.
    if (!_tourContainsDirections(tour) &&
        wifiConnected &&
        settingsHelper.enhanceToursEnabled) {
      FLog.info(text: "Tour: ${tour.name} doesn't contain directions");
      FLog.info(
          text:
              'Tour without directions and connected to WiFi -> enhancing tour');
      final Either<Failure, Tour> failureOrEnhancedTour =
          await getEnhancedTour(EnhancedTourParams(tour: tour));
      if (failureOrEnhancedTour.isRight()) {
        tourWithDirections = failureOrEnhancedTour.getOrElse(() => null);
      }
    }

    /// Only yield the tour, since no alternative tours were found.
    if (alternativeTours == null || alternativeTours.isEmpty) {
      mapboxController.onSelectTour(tour: tourWithDirections);
      yield TourLoadSuccess(tour: tourWithDirections);

      /// Yield the tour and its alternative tours.
    } else {
      mapboxController.onSelectTour(
          tour: tourWithDirections, alternativeTours: alternativeTours);
      yield TourLoadSuccess(
          tour: tourWithDirections, alternativeTours: alternativeTours);
    }
  }

  /// Checks if the [tour]'s waypoints contain direction information.
  ///
  /// Only checks up to the first 10 waypoints for performance reasons.
  bool _tourContainsDirections(Tour tour) {
    int wayPointsWithDirections = 0;
    const int amountOfWayPointsToCheck = 10;
    final int maxIterationIndex =
        max(tour.wayPoints.length, amountOfWayPointsToCheck);
    for (int i = 0; i < maxIterationIndex; i++) {
      if (tour.wayPoints[i].direction != '') {
        wayPointsWithDirections++;
      }
    }
    return wayPointsWithDirections > 0;
  }

  /// Maps the [failure] to a message displayed in the failure state.
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ParserFailure:
        return parserFailureMessage;
        break;
      case ServerFailure:
        return serverFailureMessage;
        break;
      default:
        return 'Unexpected error';
    }
  }

  /// Removes the active tour and all alternative tours.
  ///
  /// Yields [TourEmpty] state.
  Stream<TourState> _mapTourRemovedToState() async* {
    yield TourEmpty();
  }
}
