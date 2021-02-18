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
  @override
  List<Object> get props => [];
}

class TourLoadSuccess extends TourState {
  final Tour tour;

  const TourLoadSuccess({@required this.tour});

  @override
  String toString() => 'TourLoadSuccess { tour: $tour }';

  @override
  List<Object> get props => [tour];
}

class TourLoadFailure extends TourState {
  final String message;

  const TourLoadFailure({@required this.message});

  @override
  List<Object> get props => [message];
}
