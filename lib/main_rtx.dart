import 'package:bike_gps/main_common.dart';
import 'package:f_logs/f_logs.dart';

import 'core/function_results/function_result.dart';

Future<FunctionResult> main() async {
  FLog.trace(text: 'appStart environment: rtx', methodName: 'main');
  await appStart(environment: 'rtx');
  return FunctionResultSuccess();
}
