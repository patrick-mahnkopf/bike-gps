import 'dart:developer';
import 'dart:io';

import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exception.dart';
import '../../models/tour/models.dart';
import '../tour_parser/data_sources.dart';

abstract class TourLocalDataSource {
  Future<TourModel> getTour({@required String name});
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
}
