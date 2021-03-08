import 'dart:developer';
import 'dart:io';

import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/data/data_sources/tour_parser/tour_parser.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exception.dart';
import '../../models/tour/models.dart';

abstract class TourLocalDataSource {
  Future<TourModel> getTour({@required String name});
  Future<List<TourModel>> getAlternativeTours({@required String mainTourName});
}

@Injectable(as: TourLocalDataSource)
class TourLocalDataSourceImpl implements TourLocalDataSource {
  final TourParser tourParser;
  final ConstantsHelper constantsHelper;
  final TourListHelper tourListHelper;

  TourLocalDataSourceImpl(
      {@required this.tourParser,
      @required this.constantsHelper,
      @required this.tourListHelper});

  @override
  Future<TourModel> getTour({@required String name}) async {
    try {
      final File tourFile = tourListHelper.getFile(name);
      final TourModel tourModel = await tourParser.getTour(file: tourFile);
      if (tourModel == null) {
        throw ParserException();
      } else {
        return tourModel;
      }
    } on Exception catch (error, stacktrace) {
      log('Parsing failed',
          error: error,
          stackTrace: stacktrace,
          time: DateTime.now(),
          name: 'TourLocalDataSource');
      throw ParserException();
    }
  }

  @override
  Future<List<TourModel>> getAlternativeTours(
      {@required String mainTourName}) async {
    try {
      if (tourListHelper.contains(mainTourName)) {
        final List<TourModel> tourModels = [];
        final TourBounds mainTourBounds =
            tourListHelper.getBounds(mainTourName);

        for (final TourBounds alternativeTourBounds
            in tourListHelper.getBoundsList()) {
          if (mainTourBounds != alternativeTourBounds) {
            if (mainTourBounds.getOverlap(alternativeTourBounds) >= 0.25) {
              final TourModel tourModel =
                  await getTour(name: alternativeTourBounds.name);
              tourModels.add(tourModel);
            }
          }
        }
        return tourModels;
      } else {
        throw TourListException();
      }
    } on Exception catch (error, stacktrace) {
      log('Getting alternative tours failed',
          error: error,
          stackTrace: stacktrace,
          time: DateTime.now(),
          name: 'TourLocalDataSource');
      throw TourListException();
    }
  }
}
