import 'dart:async';

import 'package:bike_gps/core/controllers/controllers.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_alternative_tours.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_enhanced_tour.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_tour.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../domain/entities/tour/entities.dart';

part 'tour_event.dart';
part 'tour_state.dart';

const String parserFailureMessage = 'Parser Failure';
const String serverFailureMessage = 'Server Failure';

@lazySingleton
class TourBloc extends Bloc<TourEvent, TourState> {
  final GetTour getTour;
  final GetAlternativeTours getAlternativeTours;
  final GetEnhancedTour getEnhancedTour;

  TourBloc(
      {@required this.getTour,
      @required this.getAlternativeTours,
      @required this.getEnhancedTour})
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

  Stream<TourState> _eitherLoadSuccessOrLoadFailureState(
      Either<Failure, Tour> failureOrTour,
      MapboxController mapboxController,
      Either<Failure, List<Tour>> failureOrAlternativeTours) async* {
    if (failureOrTour.isRight()) {
      final Tour tour = failureOrTour.getOrElse(() => null);
      if (failureOrAlternativeTours.isRight()) {
        final List<Tour> alternativeTours =
            failureOrAlternativeTours.getOrElse(() => null);
        yield* _tourLoadSuccessOrEnhanceFirst(
            tour, alternativeTours, mapboxController);
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

  Stream<TourState> _tourLoadSuccessOrEnhanceFirst(Tour tour,
      List<Tour> alternativeTours, MapboxController mapboxController) async* {
    Tour tourWithDirections = tour;
    if (!_tourContainsDirections(tour)) {
      final Either<Failure, Tour> failureOrEnhancedTour =
          await getEnhancedTour(EnhancedTourParams(tour: tour));
      if (failureOrEnhancedTour.isRight()) {
        tourWithDirections = failureOrEnhancedTour.getOrElse(() => null);
      }
    }

    if (alternativeTours == null || alternativeTours.isEmpty) {
      mapboxController.onSelectTour(tour: tourWithDirections);
      yield TourLoadSuccess(tour: tourWithDirections);
    } else {
      mapboxController.onSelectTour(
          tour: tourWithDirections, alternativeTours: alternativeTours);
      yield TourLoadSuccess(
          tour: tourWithDirections, alternativeTours: alternativeTours);
    }
  }

  bool _tourContainsDirections(Tour tour) {
    int wayPointsWithDirections = 0;
    for (var i = 0; i < tour.wayPoints.length; i++) {
      if (tour.wayPoints[i].direction != '') {
        wayPointsWithDirections++;
      }
      if (i >= 10) {
        break;
      }
    }
    return wayPointsWithDirections > 0;
  }

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

  Stream<TourState> _mapTourRemovedToState() async* {
    yield TourEmpty();
  }
}
