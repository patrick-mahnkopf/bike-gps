import 'package:bike_gps/main_common.dart';

import 'core/function_results/function_result.dart';

/// Starts the app with the 'rtx' environment.
Future<FunctionResult> main() async {
  await appStart(environment: 'rtx');
  return FunctionResultSuccess();
}
