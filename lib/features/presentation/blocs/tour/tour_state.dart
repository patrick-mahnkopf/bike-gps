part of 'tour_bloc.dart';

abstract class TourState extends Equatable {
  const TourState();

  @override
  List<Object> get props => [];
}

/// Initial state of the TourBloc when no tour is active.
class TourEmpty extends TourState {
  @override
  List<Object> get props => [];
}

/// State of the TourBloc while loading.
class TourLoading extends TourState {
  final TourState previousState;

  const TourLoading({@required this.previousState});
  @override
  List<Object> get props => [previousState];
}

/// State of the TourBloc if loading was successful.
class TourLoadSuccess extends TourState {
  final Tour tour;
  final List<Tour> alternativeTours;

  const TourLoadSuccess(
      {@required this.tour, this.alternativeTours = const []});

  @override
  String toString() =>
      'TourLoadSuccess { tour: $tour, alternativeTours: $alternativeTours }';

  @override
  List<Object> get props => [tour, alternativeTours];
}

/// State of the TourBloc if loading failed.
class TourLoadFailure extends TourState {
  final String message;

  const TourLoadFailure({@required this.message});

  @override
  List<Object> get props => [message];
}
