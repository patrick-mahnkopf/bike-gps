import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/main_common.dart';

Future<FunctionResult> main() async {
  await appStart(environment: 'public');
  return FunctionResultSuccess();
}
