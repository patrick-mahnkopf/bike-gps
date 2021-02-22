part of 'tour_bloc.dart';

abstract class TourEvent extends Equatable {
  const TourEvent();

  @override
  List<Object> get props => [];
}

class TourLoaded extends TourEvent {
  final String tourName;
  final BuildContext context;

  const TourLoaded({@required this.tourName, @required this.context});

  @override
  List<Object> get props => [tourName];

  @override
  String toString() => 'TourLoaded { tourName: $tourName }';
}

class TourRemoved extends TourEvent {}
