part of 'height_map_bloc.dart';

abstract class HeightMapState extends Equatable {
  const HeightMapState();

  @override
  List<Object> get props => [];
}

/// Initial state of the HeightMapBloc.
class HeightMapInitial extends HeightMapState {
  final String name = 'HeightMapInitial';

  @override
  List<Object> get props => [name];
}

/// State of the HeightMapBloc while loading.
class HeightMapLoading extends HeightMapState {
  final String name = 'HeightMapLoading';

  @override
  List<Object> get props => [name];
}

/// State of the HeightMapBloc if loading was successful.
class HeightMapLoadSuccess extends HeightMapState {
  String get name => 'HeightMapLoadSuccess';
  final List<TickSpec<num>> primaryMeasureAxisTickSpecs;
  final List<TickSpec<num>> domainAxisTickSpecs;
  final List<Series<TrackPoint, int>> chartData;
  final Tour tour;

  const HeightMapLoadSuccess(
      {@required this.primaryMeasureAxisTickSpecs,
      @required this.domainAxisTickSpecs,
      @required this.chartData,
      @required this.tour});

  @override
  List<Object> get props => [
        primaryMeasureAxisTickSpecs,
        primaryMeasureAxisTickSpecs.length,
        domainAxisTickSpecs,
        domainAxisTickSpecs.length,
        chartData,
        chartData.length,
        name,
        tour
      ];

  @override
  String toString() =>
      'HeightMapLoadSuccess { primaryMeasureAxisTickSpecs: ${primaryMeasureAxisTickSpecs.length}, domainAxisTickSpecs: ${domainAxisTickSpecs.length}, chartData: ${chartData.length} }';
}

/// State of the HeightMapBloc if loading failed.
class HeightMapLoadFailure extends HeightMapState {
  final String message;

  const HeightMapLoadFailure({@required this.message});

  @override
  List<Object> get props => [message];
}
