part of 'tour_bloc.dart';

abstract class TourEvent extends Equatable {
  const TourEvent();

  @override
  List<Object> get props => [];
}

class TourLoaded extends TourEvent {
  final String tourName;

  const TourLoaded({@required this.tourName});

  @override
  List<Object> get props => [tourName];

  @override
  String toString() => 'TourLoaded { tourName: $tourName }';
}

class TourRemoved extends TourEvent {}
