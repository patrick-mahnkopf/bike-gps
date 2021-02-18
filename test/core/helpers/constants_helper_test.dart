import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  ConstantsHelper constantsHelper;

  setUp(() async {
    constantsHelper = await ConstantsHelper.create();
  });

  test(
      'tour directory path should start with application documents directory path',
      () async {
    // arrange
    final applicationDocumentsDirectoryPath =
        (await getApplicationDocumentsDirectory()).path;
    // act
    final result = constantsHelper.tourDirectoryPath;
    // assert
    expect(result, startsWith(applicationDocumentsDirectoryPath));
  });

  test('tour directory path should end with tours', () {
    // arrange
    // act
    final result = constantsHelper.tourDirectoryPath;
    // assert
    expect(result, endsWith('\\tours'));
  });
}
