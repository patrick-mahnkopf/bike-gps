import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  ConstantsHelper constantsHelper;

  setUp(() async {
    constantsHelper = await ConstantsHelper.create();
  });

  test('tour directory path should be application support directory path',
      () async {
    // arrange
    final applicationSupportDirectory =
        (await getApplicationSupportDirectory()).path;
    // act
    final result = constantsHelper.tourDirectoryPath;
    // assert
    expect(result, applicationSupportDirectory);
  });
}
