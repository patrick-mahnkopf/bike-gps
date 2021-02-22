part of 'height_map_bloc.dart';

abstract class HeightMapEvent extends Equatable {
  const HeightMapEvent();

  @override
  List<Object> get props => [];
}

class HeightMapLoaded extends HeightMapEvent {
  final Tour tour;

  const HeightMapLoaded({@required this.tour});

  @override
  List<Object> get props => [tour];

  @override
  String toString() => 'HeightMapLoaded { tour: $tour }';
}
