import 'dart:developer';

import 'package:bike_gps/core/error/exception.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../models/tour/models.dart';
import '../tour_parser/data_sources.dart';

abstract class TourLocalDataSource {
  Future<TourModel> getTour({@required String name});
}

@Injectable(as: TourLocalDataSource)
class TourLocalDataSourceImpl implements TourLocalDataSource {
  final TourParser tourParser;

  TourLocalDataSourceImpl({@required this.tourParser});

  @override
  Future<TourModel> getTour({@required String name}) async {
    try {
      final TourModel tourModel = await tourParser.getTour(name: name);
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
