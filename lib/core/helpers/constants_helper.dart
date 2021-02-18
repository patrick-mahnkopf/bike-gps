import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

@injectable
class ConstantsHelper {
  final String applicationDocumentsDirectoryPath;
  String tourDirectoryPath;

  ConstantsHelper({@required this.applicationDocumentsDirectoryPath}) {
    tourDirectoryPath = p.join(
      applicationDocumentsDirectoryPath,
      'tours',
    );
  }

  @factoryMethod
  static Future<ConstantsHelper> create() async {
    return ConstantsHelper(
        applicationDocumentsDirectoryPath:
            (await getApplicationDocumentsDirectory()).path);
  }
}
