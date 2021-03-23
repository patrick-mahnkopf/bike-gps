import 'package:bike_gps/main_common.dart';

import 'core/function_results/function_result.dart';

Future<FunctionResult> main() async {
  await appStart(environment: 'rtx');
  return FunctionResultSuccess();
}
