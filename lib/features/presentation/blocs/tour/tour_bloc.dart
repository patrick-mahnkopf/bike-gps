import 'dart:async';

import 'package:bike_gps/core/error/failure.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/repositories/repositories.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

part 'tour_event.dart';
part 'tour_state.dart';

const String parserFailureMessage = 'Parser Failure';
const String serverFailureMessage = 'Server Failure';

@injectable
class TourBloc extends Bloc<TourEvent, TourState> {
  final TourRepository tourRepository;

  TourBloc({@required this.tourRepository}) : super(TourEmpty());

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
    yield TourLoading();
    try {
      final Either<Failure, Tour> failureOrTour =
          await tourRepository.getTour(name: event.tourName);
      yield* _eitherLoadSuccessOrLoadFailureState(failureOrTour);
    } on Exception catch (error) {
      yield TourLoadFailure(message: error.toString());
      rethrow;
    }
  }

  Stream<TourState> _eitherLoadSuccessOrLoadFailureState(
      Either<Failure, Tour> failureOrTour) async* {
    yield failureOrTour.fold(
      (failure) => TourLoadFailure(message: _mapFailureToMessage(failure)),
      (tour) => TourLoadSuccess(tour: tour),
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
