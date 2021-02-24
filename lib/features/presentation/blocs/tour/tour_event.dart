part of 'tour_bloc.dart';

abstract class TourEvent extends Equatable {
  const TourEvent();

  @override
  List<Object> get props => [];
}

class TourLoaded extends TourEvent {
  final String tourName;
  final MapboxController mapboxController;

  const TourLoaded({@required this.tourName, @required this.mapboxController});

  @override
  List<Object> get props => [tourName, mapboxController];

  @override
  String toString() =>
      'TourLoaded { tourName: $tourName, mapboxController: $mapboxController }';
}

class TourRemoved extends TourEvent {}
