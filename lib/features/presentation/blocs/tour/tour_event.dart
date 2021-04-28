part of 'tour_bloc.dart';

abstract class TourEvent extends Equatable {
  const TourEvent();

  @override
  List<Object> get props => [];
}

/// Event of the TourBloc when loading was initiated.
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

/// Event of the TourBloc when the active tour was dismissed.
class TourRemoved extends TourEvent {}
