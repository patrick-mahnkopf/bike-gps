import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/main_common.dart';
import 'package:f_logs/f_logs.dart';

Future<FunctionResult> main() async {
  FLog.trace(text: 'appStart environment: public', methodName: 'main');
  await appStart(environment: 'public');
  return FunctionResultSuccess();
}
