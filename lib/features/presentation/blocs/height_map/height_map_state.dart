part of 'height_map_bloc.dart';

abstract class HeightMapState extends Equatable {
  const HeightMapState();

  @override
  List<Object> get props => [];
}

class HeightMapInitial extends HeightMapState {
  final String name = 'HeightMapInitial';

  @override
  List<Object> get props => [name];
}

class HeightMapLoading extends HeightMapState {
  final String name = 'HeightMapLoading';

  @override
  List<Object> get props => [name];
}

class HeightMapLoadSuccess extends HeightMapState {
  final List<TickSpec<num>> primaryMeasureAxisTickSpecs;
  final List<TickSpec<num>> domainAxisTickSpecs;
  final List<Series<WayPoint, int>> chartData;

  const HeightMapLoadSuccess(
      {@required this.primaryMeasureAxisTickSpecs,
      @required this.domainAxisTickSpecs,
      @required this.chartData});

  @override
  List<Object> get props =>
      [primaryMeasureAxisTickSpecs, domainAxisTickSpecs, chartData];

  @override
  String toString() =>
      'HeightMapLoaded { primaryMeasureAxisTickSpecs: $primaryMeasureAxisTickSpecs, domainAxisTickSpecs: $domainAxisTickSpecs, chartData: $chartData,  }';
}

class HeightMapLoadFailure extends HeightMapState {
  final String message;

  const HeightMapLoadFailure({@required this.message});

  @override
  List<Object> get props => [message];
}
