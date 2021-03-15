import 'dart:async';

import 'package:bike_gps/core/controllers/controllers.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_alternative_tours.dart';
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

  TourBloc({@required this.getTour, @required this.getAlternativeTours})
      : assert(getTour != null),
        assert(getAlternativeTours != null),
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
    yield failureOrTour.fold(
      (failure) => TourLoadFailure(message: _mapFailureToMessage(failure)),
      (tour) {
        if (failureOrAlternativeTours.isRight()) {
          final List<Tour> alternativeTours =
              failureOrAlternativeTours.getOrElse(() => null);
          mapboxController.onSelectTour(
              tour: tour, alternativeTours: alternativeTours);
          return TourLoadSuccess(
              tour: tour, alternativeTours: alternativeTours);
        } else {
          mapboxController.onSelectTour(tour: tour);
          return TourLoadSuccess(tour: tour);
        }
      },
    );
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
