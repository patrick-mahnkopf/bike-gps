import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:bike_gps_closed_source/bike_gps_closed_source.dart';
import 'package:injectable/injectable.dart';

import 'tour_parser.dart';

@module
abstract class RtxParserModule {
  @Injectable(as: TourParser, env: ["rtx"])
  RtxParser getRtxParser(
    ConstantsHelper constantsHelper,
    DistanceHelper distanceHelper,
    GpxParser gpxParser,
  ) =>
      RtxParser(
        constantsHelper: constantsHelper,
        distanceHelper: distanceHelper,
        gpxParser: gpxParser,
      );
}

@module
abstract class GpxParserModule {
  @Injectable(env: ["rtx"])
  GpxParser getGpxParser(
    ConstantsHelper constantsHelper,
    DistanceHelper distanceHelper,
  ) =>
      GpxParser(
        constantsHelper: constantsHelper,
        distanceHelper: distanceHelper,
      );
}
