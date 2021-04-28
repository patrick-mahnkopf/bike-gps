import 'dart:async';

import 'package:bike_gps/core/helpers/tour_conversion_helper.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bloc/bloc.dart';
import 'package:charts_flutter_cf/charts_flutter_cf.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';

part 'height_map_event.dart';
part 'height_map_state.dart';

/// BLoC responsible for the height map.
@injectable
class HeightMapBloc extends Bloc<HeightMapEvent, HeightMapState> {
  final TourConversionHelper tourConversionHelper;

  HeightMapBloc({@required this.tourConversionHelper})
      : super(HeightMapInitial());

  @override
  Stream<HeightMapState> mapEventToState(
    HeightMapEvent event,
  ) async* {
    if (event is HeightMapLoaded) {
      yield* _mapHeightMapLoadedToState(event);
    }
  }

  /// Prepares and returns the height map.
  ///
  /// Gets the chart data from the currently active tour. Yields
  /// [HeightMapLoadSuccess] if successful and [HeightMapLoadFailure] otherwise.
  Stream<HeightMapState> _mapHeightMapLoadedToState(
      HeightMapLoaded event) async* {
    yield HeightMapLoading();
    try {
      final List<Series<TrackPoint, int>> chartData =
          await _getChartData(event.tour);
      final List<TickSpec<num>> primaryMeasureAxisTickSpecs =
          _getPrimaryMeasureAxisTickSpecs(event.tour);
      final List<TickSpec<num>> domainAxisTickSpecs =
          _getDomainAxisTickSpecs(event.tour);
      yield HeightMapLoadSuccess(
          chartData: chartData,
          primaryMeasureAxisTickSpecs: primaryMeasureAxisTickSpecs,
          domainAxisTickSpecs: domainAxisTickSpecs,
          tour: event.tour);
    } on Exception catch (error) {
      yield HeightMapLoadFailure(message: error.toString());
    }
  }

  /// Gets the [tour] data to be shown in the chart.
  Future<List<Series<TrackPoint, int>>> _getChartData(Tour tour) async {
    return [
      Series<TrackPoint, int>(
        id: 'Active Tour',
        colorFn: (TrackPoint trackPoint, _) => tourConversionHelper
            .mapSurfaceToChartColor(surface: trackPoint.surface),
        domainFn: (TrackPoint trackPoint, _) =>
            trackPoint.distanceFromStart.toInt(),
        measureFn: (TrackPoint trackPoint, _) => trackPoint.elevation.toInt(),
        data: tour.trackPoints,
      )
    ];
  }

  /// Calculates the y-axis tick spacing and labels for the [tour].
  List<TickSpec<num>> _getPrimaryMeasureAxisTickSpecs(Tour tour) {
    final List<TickSpec<num>> tickSpecs = [];
    final double tickStep = tour.highestPoint / 5;
    for (double tickValue = 0;
        tickValue < tour.highestPoint + tickStep;
        tickValue += tickStep) {
      final double roundValue = (tickStep / 10).roundToDouble() * 10;
      final double labelValue =
          (tickValue / roundValue).roundToDouble() * roundValue;
      tickSpecs.add(TickSpec(labelValue, label: '${labelValue.toInt()} m'));
    }
    return tickSpecs;
  }

  /// Calculates the x-axis tick spacing and labels for the [tour].
  List<TickSpec<num>> _getDomainAxisTickSpecs(Tour tour) {
    final List<TickSpec<num>> tickSpecs = [];
    final double tourLength =
        double.parse((tour.tourLength / 1000).toStringAsFixed(1)) * 1000;
    final double tickStep = tourLength / 5;
    for (double tickValue = 0;
        tickValue < tourLength + tickStep;
        tickValue += tickStep) {
      final String labelValue = (tickValue / 1000).toStringAsFixed(1);
      tickSpecs.add(TickSpec(tickValue, label: '$labelValue km'));
    }
    return tickSpecs;
  }
}
