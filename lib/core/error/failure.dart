import 'package:equatable/equatable.dart';

/// The different failures that can occur in the app.

abstract class Failure extends Equatable {
  @override
  List<Object> get props => [];
}

class ServerFailure extends Failure {}

class ParserFailure extends Failure {}

class ArgumentFailure extends Failure {}

class NavigationDataFailure extends Failure {}

class FileFailure extends Failure {}

class TourListFailure extends Failure {}
