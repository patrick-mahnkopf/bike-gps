part of 'tour_bloc.dart';

abstract class TourState extends Equatable {
  const TourState();

  @override
  List<Object> get props => [];
}

class TourEmpty extends TourState {
  @override
  List<Object> get props => [];
}

class TourLoading extends TourState {
  final TourState previousState;

  const TourLoading({@required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class TourLoadSuccess extends TourState {
  final Tour tour;
  final List<Tour> alternativeTours;

  const TourLoadSuccess({@required this.tour, this.alternativeTours});

  @override
  String toString() =>
      'TourLoadSuccess { tour: $tour, alternativeTours: $alternativeTours }';

  @override
  List<Object> get props => [tour, alternativeTours];
}

class TourLoadFailure extends TourState {
  final String message;

  const TourLoadFailure({@required this.message});

  @override
  List<Object> get props => [message];
}
