import 'dart:developer';

import 'package:flutter/widgets.dart';

class FunctionResult {}

class FunctionResultSuccess extends FunctionResult {}

class FunctionResultFailure extends FunctionResult {
  final Exception error;
  final StackTrace stackTrace;
  final String name;

  FunctionResultFailure(
      {@required this.error, @required this.stackTrace, this.name}) {
    log(error.toString(),
        error: error,
        stackTrace: stackTrace,
        name: name ?? 'FunctionResultFailure',
        time: DateTime.now());
  }
}
