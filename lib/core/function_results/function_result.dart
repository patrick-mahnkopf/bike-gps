import 'dart:developer';

import 'package:f_logs/f_logs.dart';
import 'package:flutter/widgets.dart';

/// Function results to return for async functions because they should not
/// return void.

class FunctionResult {}

class FunctionResultSuccess extends FunctionResult {}

class FunctionResultFailure extends FunctionResult {
  final Exception error;
  final StackTrace stackTrace;
  final String name;
  final String methodName;

  FunctionResultFailure(
      {@required this.error,
      @required this.stackTrace,
      this.name,
      this.methodName}) {
    log(error.toString(),
        error: error,
        stackTrace: stackTrace,
        name: name ?? 'FunctionResultFailure',
        time: DateTime.now());
    FLog.error(
        text: error.toString(),
        exception: error,
        stacktrace: stackTrace,
        methodName: methodName);
  }
}
